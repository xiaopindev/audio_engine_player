//
//  AudioEnginePlayer.swift
//  SwiftAudioEqualizer
//
//  Created by xiaopin on 2024/7/17.
//

import AVFoundation

enum LoopMode {
    case single
    case all
    case shuffle
}

class AudioEnginePlayer {
    var onPlaybackProgressUpdate: ((Int) -> Void)? // 播放进度更新回调
    /// 播放总时长，单位毫秒
    var totalDuration: Int = 0
    /// 音量控制
    var volume : Float = 1.0
    
    //MARK: Private Property
    private var audioEngine: AVAudioEngine
    private var equalizer: AVAudioUnitEQ
    private var reverb: AVAudioUnitReverb
    
    private var playerNode: AVAudioPlayerNode
    private var audioFile: AVAudioFile?
    
    private var isPlaying: Bool = false
    private var isPaused: Bool = false
    private var isSeeking: Bool = false
    private var seekTarget: Int = 0
    
    /// 播放进度，单位毫秒
    private var playbackProgress: Int = 0
    private var progressUpdateTimer: DispatchSourceTimer?
    
    private var playlist: [String] = []
    private var currentTrackIndex: Int = 0
    
    private var loopMode: LoopMode = .all
    
    init() {
        playerNode = AVAudioPlayerNode()
        audioEngine = AVAudioEngine()
        equalizer = AVAudioUnitEQ(numberOfBands: 10)
        reverb = AVAudioUnitReverb()
        initEqualizer()
        setupAudioEngine()
    }
    
    //MARK: Private Methods
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(equalizer)
        audioEngine.attach(reverb)
        
        audioEngine.connect(playerNode, to: equalizer, format: nil)// 连接播放源到均衡器
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil) // 连接混响到主混音器
        
        do {
            try audioEngine.start()
        } catch {
            print("音频引擎启动失败: \(error)")
        }
    }
    
    private func restartEngine() {
        audioEngine.stop()
        do {
            try audioEngine.start()
        } catch {
            print("音频引擎重新启动失败: \(error)")
        }
    }
    
    private func initEqualizer() {
        let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        let initialGains: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] // 初始标准模式的增益值
        
        for i in 0..<equalizer.bands.count {
            let band = equalizer.bands[i]
            band.filterType = .parametric
            band.frequency = frequencies[i]
            band.bandwidth = 1.0
            band.gain = initialGains[i]
            band.bypass = false
        }
    }
    
    private func loadAndPlayAudioFile(from url: URL) {
        do {
            self.audioFile = try AVAudioFile(forReading: url)
            if let audioFile = self.audioFile {
                let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                self.totalDuration = Int(duration * 1000) // 转换为毫秒
            }
            self.playerNode.scheduleFile(self.audioFile!, at: nil, completionHandler: nil)
            self.restartEngine()
            //self.playerNode.prepare(withFrameCount: <#T##AVAudioFrameCount#>)
            self.playerNode.play()
            self.isPlaying = true
            startProgressUpdateTimer() // 开始更新播放进度
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    private func startProgressUpdateTimer() {
        stopProgressUpdateTimer() // 确保之前的定时器被取消
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let currentTime = self.playerNode.current + Double(seekTarget/1000)
            let progress = Int(currentTime * 1000) // 转换为毫秒
            //print("self.playerNode.current :\(self.playerNode.current) + \(seekTarget/1000) = currentTime: \(currentTime)")
            DispatchQueue.main.async {
                if self.isSeeking {
                    self.playbackProgress = self.seekTarget
                    self.isSeeking = false
                } else {
                    self.playbackProgress = progress
                }
                self.onPlaybackProgressUpdate?(self.playbackProgress) // 回调播放进度
                if self.playbackProgress >= self.totalDuration {
                    self.stopProgressUpdateTimer() // 停止定时器
                    self.handlePlaybackCompletion() // 播放下一首
                }
            }
        }
        timer.resume()
        progressUpdateTimer = timer
    }
    
    private func stopProgressUpdateTimer() {
        playbackProgress = 0
        progressUpdateTimer?.cancel()
        progressUpdateTimer = nil
    }
    
    private func downloadFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                print("Download error: \(String(describing: error))")
                completion(nil)
                return
            }
            do {
                let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let audioCacheURL = documentsURL.appendingPathComponent("AudioEnginePlayer")
                
                if !FileManager.default.fileExists(atPath: audioCacheURL.path) {
                    try FileManager.default.createDirectory(at: audioCacheURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                let destinationURL = audioCacheURL.appendingPathComponent(url.lastPathComponent)
                // 检查目标路径是否存在
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    do {
                        try FileManager.default.removeItem(at: destinationURL)
                    } catch {
                        print("无法删除现有文件: \(error)")
                        completion(destinationURL) // 返回现有文件的路径
                        return
                    }
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                print("File move error: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func resetBands() {
        let initialGains: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] // 重置为初始标准模式的增益值
        for i in 0..<equalizer.bands.count {
            equalizer.bands[i].gain = initialGains[i]
        }
        restartEngine() // 刷新音频引擎以应用新的增益值
    }
    
    private func resetReverb(){
        audioEngine.disconnectNodeInput(audioEngine.mainMixerNode)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil) // 连接均衡器到主混音器，不使用混响
        restartEngine()
    }
    
    private func handlePlaybackCompletion() {
        seekTarget = 0
        stopProgressUpdateTimer() // 播放完成后停止定时器
        switch loopMode {
        case .single:
            playCurrentTrack()
        case .all:
            playNextTrack()
        case .shuffle:
            playRandomTrack()
        }
    }
    private func playCurrentTrack() {
        guard !playlist.isEmpty, currentTrackIndex < playlist.count else {
            print("播放列表为空或索引无效")
            return
        }
        let filePath = playlist[currentTrackIndex];
        play(with: filePath)
    }
    
    private func playNextTrack() {
        guard !playlist.isEmpty else {
            print("播放列表为空")
            return
        }
        currentTrackIndex = (currentTrackIndex + 1) % playlist.count
        playCurrentTrack()
    }
    
    private func playPreviousTrack() {
        guard !playlist.isEmpty else {
            print("播放列表为空")
            return
        }
        currentTrackIndex = (currentTrackIndex - 1 + playlist.count) % playlist.count
        playCurrentTrack()
    }
    
    private func playRandomTrack() {
        guard !playlist.isEmpty else {
            print("播放列表为空")
            return
        }
        currentTrackIndex = Int.random(in: 0..<playlist.count)
        playCurrentTrack()
    }
    
    //MARK: Public Methods
    public func play(with filePath: String) {
        print("Play filePath \(filePath)")
        stop()
        if let url = URL(string: filePath), url.scheme == "http" || url.scheme == "https" {
            downloadFile(from: url) { localURL in
                guard let localURL = localURL else {
                    print("Failed to download file")
                    return
                }
                print("成功下载：\(filePath)\n存储位置：\(localURL)")
                self.loadAndPlayAudioFile(from: localURL)
            }
        } else {
            let localURL = URL(fileURLWithPath: filePath)
            loadAndPlayAudioFile(from: localURL)
        }
    }

    public func seekTo(milliseconds: Int) {
        guard let audioFile = self.audioFile else {
            print("音频文件未加载")
            return
        }
        
        do {
            // 如果当前是暂停状态，跳转后自动播放
            if isPaused || !isPlaying {
                playerNode.play()
            }
            guard let nodeTime = self.playerNode.lastRenderTime,
                  let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) else {
                print("无法获取播放节点时间")
                return
            }
            let sampleRate = playerTime.sampleRate
            
            // 计算新的采样时间（将毫秒转换为秒再乘以采样率）
            let newSampleTime = AVAudioFramePosition(sampleRate * (Double(milliseconds) / 1000.0))
            // 计算剩余播放时长（单位：秒）
            let length = (totalDuration - milliseconds) / 1000
            // 计算剩余播放帧数
            let framesToPlay = AVAudioFrameCount(Float(playerTime.sampleRate) * Float(length))
            
            print("newSampleTime \(newSampleTime) framesToPlay: \(framesToPlay)")
            
            // 停止当前播放
            playerNode.stop()
            
            // 如果剩余帧数大于1000，则重新调度播放
            if framesToPlay > 1000 {
                playerNode.scheduleSegment(audioFile, startingFrame: newSampleTime, frameCount: framesToPlay, at: nil, completionHandler: nil)
            }
            
            // 设置跳转标志位和目标时间
            isSeeking = true
            seekTarget = milliseconds
            
            // 如果当前是暂停状态，跳转后自动播放
            if isPaused {
                isPaused = false
                isPlaying = true
            }
            
            // 开始播放
            playerNode.play()
            isPlaying = true
            
            // 开始更新播放进度的定时器
            startProgressUpdateTimer()
        } catch {
            print("Seek操作失败: \(error)")
        }
    }
    
    public func playOrPause() {
        if isPlaying {
            playerNode.pause()
            isPaused = true
            isPlaying = false
            stopProgressUpdateTimer() // 暂停更新播放进度
        } else if isPaused {
            playerNode.play()
            isPaused = false
            isPlaying = true
            startProgressUpdateTimer() // 继续更新播放进度
        }
    }
    
    public func stop() {
        // 停止播放节点和音频引擎
        playerNode.stop()
        audioEngine.stop()
        
        // 重置播放节点和音频引擎
        playerNode.reset()
        audioEngine.reset()
        
        // 更新播放状态
        isPlaying = false
        isPaused = false
        
        // 停止更新播放进度的定时器
        stopProgressUpdateTimer()
        
        // 重置播放进度
        playbackProgress = 0
        onPlaybackProgressUpdate?(playbackProgress) // 回调重置后的播放进度
    }
    
    public func setPlaylist(_ urls: [String], autoPlay:Bool = true) {
        playlist = urls
        currentTrackIndex = 0
        if (autoPlay){
            play(with: urls[currentTrackIndex])
        }
    }
    
    public func playNext() {
        playNextTrack()
    }
    
    public func playPrevious() {
        playPreviousTrack()
    }

    public func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(volume, 1.0)) // 限制音量范围在 0.0 到 1.0 之间
        self.volume = clampedVolume
        playerNode.volume = clampedVolume
        print("音量设置为：\(clampedVolume)")
    }
    
    public func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
        print("切换到：\(loopMode)")
    }
    
    public func setBandGain(bandIndex: Int, gain: Float) {
        if isPlaying {
            playerNode.pause()
        }
        guard bandIndex >= 0 && bandIndex < equalizer.bands.count else {
            print("无效的频段索引： \(bandIndex)/\(equalizer.bands.count) \(gain)")
            return
        }
        let clampedGain = max(-12.0, min(gain, 12.0)) // 限制增益范围在 -12 dB 到 +12 dB 之间
        equalizer.bands[bandIndex].gain = clampedGain
        restartEngine() // 刷新音频引擎以应用新的增益值
        if isPlaying {
            playerNode.play()
        }
    }
    
    public func setReverb(id: Int, wetDryMix: Float = 50) {
        if isPlaying {
            playerNode.pause()
        }
        if let preset = AVAudioUnitReverbPreset(rawValue: id) {
            reverb.loadFactoryPreset(preset)
        } else {
            print("无效的混响预设ID: \(id)")
            return
        }
        
        let clampedMix = max(0.0, min(wetDryMix, 100.0)) // 限制混响范围在 0% 到 100% 之间
        reverb.wetDryMix = clampedMix
        
        audioEngine.disconnectNodeInput(audioEngine.mainMixerNode)
        audioEngine.connect(equalizer, to: reverb, format: nil) // 连接均衡器到混响
        audioEngine.connect(reverb, to: audioEngine.mainMixerNode, format: nil) // 连接混响到主混音器
        
        restartEngine() // 刷新音频引擎以应用新的混响效果
        if isPlaying {
            playerNode.play()
        }
    }
    
    public func resetAll() {
        resetBands()
        resetReverb()
        if isPlaying {
            playerNode.pause()
            playerNode.play()
        }
    }
    
    public func clearCaches() {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let audioCacheURL = documentsURL.appendingPathComponent("AudioEnginePlayer")
            do {
                if fileManager.fileExists(atPath: audioCacheURL.path) {
                    let fileURLs = try fileManager.contentsOfDirectory(at: audioCacheURL, includingPropertiesForKeys: nil, options: [])
                    for fileURL in fileURLs {
                        try fileManager.removeItem(at: fileURL)
                    }
                    print("缓存清理成功")
                } else {
                    print("缓存目录不存在")
                }
            } catch {
                print("缓存清理失败: \(error)")
            }
        }
    }
}

extension AVAudioFile{
    /// Unit:  Seconds
    var duration: TimeInterval{
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong
        return lengthSongSeconds
    }
}

extension AVAudioPlayerNode{
    /// Unit:  Seconds
    var current: TimeInterval{
        if let nodeTime = lastRenderTime,let playerTime = playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
}
