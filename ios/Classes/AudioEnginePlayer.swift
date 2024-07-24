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
    //MARK: Public Property
    var onPlayingStatusChanged: ((Bool) -> ())?
    var onPlayingIndexChanged: ((Int) -> ())?
    var onPlayCompleted: (() -> ())?
    var onPlaybackProgressUpdate: ((Int) -> ())?
    
    /// 播放总时长，单位毫秒
    var totalDuration: Int = 0
    /// 是否静音
    var isMute : Bool = false
    /// 是否启用淡入淡出效果
    var enableFadeEffect: Bool = true
    /// 音量控制，限制音量范围在 0.0 到 1.0 之间
    var volume : Float = 1.0
    /// 音量增强，限制增益范围在 0 dB 到 24 dB 之间
    var volumeBV : Float = 0.0
    /// 播放速度，限制播放速度范围在 0.25 到 4.0 之间
    var speed : Float = 1.0
    /// 当前播放索引
    var currentPlayIndex: Int = 0
    /// 播放状态
    var isPlaying: Bool = false
    
    //MARK: Private Property
    private var audioFile: AVAudioFile?

    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var varispeed: AVAudioUnitVarispeed
    private var volumeBooster: AVAudioUnitEQ // 新增音量放大器
    private var equalizer: AVAudioUnitEQ
    private var reverb: AVAudioUnitReverb
    
    private var isPaused: Bool = false
    private var isSeeking: Bool = false
    /// 单位：毫秒
    private var seekPosition: Int = 0
    
    /// 播放进度，单位毫秒
    private var playbackProgress: Int = 0
    private var progressUpdateTimer: DispatchSourceTimer?
    
    private var playlist: [String] = []
    
    private var loopMode: LoopMode = .all
    
    init() {
        playerNode = AVAudioPlayerNode()
        audioEngine = AVAudioEngine()
        varispeed = AVAudioUnitVarispeed()
        volumeBooster = AVAudioUnitEQ(numberOfBands: 1) // 初始化音量放大器
        equalizer = AVAudioUnitEQ(numberOfBands: 10)
        reverb = AVAudioUnitReverb()
        initEqualizer()
        setupAudioEngine()
    }
    
    //MARK: Private Methods
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(varispeed)
        audioEngine.attach(volumeBooster) // 附加音量放大器
        audioEngine.attach(equalizer)
        audioEngine.attach(reverb)
        
        audioEngine.connect(playerNode, to: varispeed, format: nil)
        audioEngine.connect(varispeed, to: volumeBooster, format: nil)
        audioEngine.connect(volumeBooster, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("音频引擎启动失败: \(error)")
        }
    }
    
    private func restartEngine() {
        audioEngine.stop()
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("音频引擎重新启动失败: \(error)")
        }
    }
    
    private func initEqualizer() {
        let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        let initialGains: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        
        for i in 0..<equalizer.bands.count {
            let band = equalizer.bands[i]
            band.filterType = .parametric
            band.frequency = frequencies[i]
            band.bandwidth = 1.0
            band.gain = initialGains[i]
            band.bypass = false
        }

        // 初始化音量放大器
        let boosterBand = volumeBooster.bands[0]
        boosterBand.filterType = .parametric
        boosterBand.frequency = 1000 // 中频
        boosterBand.bandwidth = 1.0
        boosterBand.gain = 0 // 初始增益为0
        boosterBand.bypass = false
    }
    
    private func loadAndPlayAudioFile(from url: URL) {
        do {
            self.audioFile = try AVAudioFile(forReading: url)
            if let audioFile = self.audioFile {
                let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                self.totalDuration = Int(duration * 1000)
            }
            self.playerNode.scheduleFile(self.audioFile!, at: nil, completionHandler: nil)
            self.restartEngine()
            //self.playerNode.prepare(withFrameCount: <#T##AVAudioFrameCount#>)
            self.playerNode.play()
            self.isPlaying = true
            
            startProgressUpdateTimer()
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
            let currentTime = self.playerNode.current + Double(seekPosition/1000)
            let progress = Int(currentTime * 1000)
            //print("self.playerNode.current :\(self.playerNode.current) + \(seekPosition/1000) = currentTime: \(currentTime)")
            //print("PlayerNode isPlayer = \(self.playerNode.isPlaying)")
            DispatchQueue.main.async {
                if self.isSeeking {
                    self.playbackProgress = self.seekPosition
                    self.isSeeking = false
                } else {
                    self.playbackProgress = progress
                }
                self.onPlaybackProgressUpdate?(self.playbackProgress)
                if self.playbackProgress >= self.totalDuration {
                    self.stopProgressUpdateTimer()
                    self.handlePlaybackCompletion()
                }
            }
        }
        timer.resume()
        progressUpdateTimer = timer
        onPlayingStatusChanged?(true)
    }
    
    private func stopProgressUpdateTimer() {
        playbackProgress = 0
        progressUpdateTimer?.cancel()
        progressUpdateTimer = nil
        onPlayingStatusChanged?(false)
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
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    do {
                        try FileManager.default.removeItem(at: destinationURL)
                    } catch {
                        print("无法删除现有文件: \(error)")
                        completion(destinationURL)
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
    
    private func handlePlaybackCompletion() {
        onPlayCompleted?()
        seekPosition = 0
        stopProgressUpdateTimer()
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
        guard !playlist.isEmpty, currentPlayIndex < playlist.count else {
            print("播放列表为空或索引无效")
            return
        }
        
        let filePath = playlist[currentPlayIndex];
        play(with: filePath)
    }
    
    private func playNextTrack() {
        guard !playlist.isEmpty else {
            print("播放列表为空")
            return
        }
        if loopMode == .shuffle {
            playRandomTrack()
            return
        }
        currentPlayIndex = (currentPlayIndex + 1) % playlist.count
        playCurrentTrack()
    }
    
    private func playPreviousTrack() {
        guard !playlist.isEmpty else {
            print("播放列表为空")
            return
        }
        if loopMode == .shuffle {
            playRandomTrack()
            return
        }
        currentPlayIndex = (currentPlayIndex - 1 + playlist.count) % playlist.count
        playCurrentTrack()
    }
    
    private func playRandomTrack() {
        guard !playlist.isEmpty else {
            print("播放列表为空")
            return
        }
        currentPlayIndex = Int.random(in: 0..<playlist.count)
        playCurrentTrack()
    }

    private func fadeVolume(to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        let steps = 50
        let stepDuration = duration / Double(steps)
        let currentVolume = self.playerNode.volume
        let volumeStep = (targetVolume - currentVolume) / Float(steps)
        
        //print("current: \(currentVolume) targetVolume:\(targetVolume)")

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                self.playerNode.volume = currentVolume + volumeStep * Float(step)
                if step == steps {
                    completion?()
                }
            }
        }
    }
    
    //MARK: Public Methods
    public func play(with filePath: String) {
        print("Play filePath \(filePath)")
        stop()
        if !playlist.contains(filePath) {
            playlist.append(filePath)
            currentPlayIndex = playlist.count - 1
        } else {
            currentPlayIndex = playlist.firstIndex(of: filePath) ?? 0
        }
        onPlayingIndexChanged?(currentPlayIndex)
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
            seekPosition = milliseconds
                    
            // 开始播放            
            playerNode.play()
            isPaused = false
            isPlaying = true
            
            // 开始更新播放进度的定时器
            startProgressUpdateTimer()
        } catch {
            print("Seek操作失败: \(error)")
        }
    }
    
    public func seekToIndex(_ index: Int) {
        guard index >= 0 && index < playlist.count else {
            print("无效的索引：\(index)")
            return
        }
        currentPlayIndex = index
        playCurrentTrack()
    }
    
    public func playOrPause() {
        if isPlaying {
            if enableFadeEffect {
                fadeVolume(to: 0.0, duration: 2.0) { // 淡出
                    self.playerNode.pause()
                    self.isPaused = true
                    self.isPlaying = false
                    self.stopProgressUpdateTimer()
                }
            } else {
                self.playerNode.pause()
                self.isPaused = true
                self.isPlaying = false
                self.stopProgressUpdateTimer()
            }
        } else if isPaused {
            if enableFadeEffect {
                self.playerNode.play()
                self.isPaused = false
                self.isPlaying = true
                self.startProgressUpdateTimer()
                fadeVolume(to: self.volume, duration: 2.0) // 淡入
            } else {
                self.playerNode.play()
                self.isPaused = false
                self.isPlaying = true
                self.startProgressUpdateTimer()
            }
        }
    }
    
    public func pause() {
        playerNode.pause()
        isPaused = true
        isPlaying = false
        stopProgressUpdateTimer()
    }
    
    public func stop() {
        // 停止更新播放进度的定时器
        stopProgressUpdateTimer()
        
        // 停止播放节点和音频引擎
        playerNode.stop()
        audioEngine.stop()
        
        // 重置播放节点和音频引擎
        playerNode.reset()
        audioEngine.reset()
        
        // 更新播放状态
        isPlaying = false
        isPaused = false
        onPlayingStatusChanged?(false)

        // 重置播放进度
        seekPosition = 0
        playbackProgress = 0
        onPlaybackProgressUpdate?(playbackProgress)
    }
    
    public func setPlaylist(_ urls: [String], autoPlay:Bool = true) {
        stop()
        playlist = urls
        currentPlayIndex = 0
        if (autoPlay){
            play(with: urls[currentPlayIndex])
        }
    }
    
    public func appendToPlaylist(_ url: String, autoPlay:Bool = false){
        playlist.append(url)
        if (autoPlay){
            currentPlayIndex = playlist.count - 1
            play(with: playlist[currentPlayIndex])
        }
    }
    
    public func removeFromPlaylist(_ index: Int) {
        guard index >= 0 && index < playlist.count else {
            print("无效的索引：\(index)")
            return
        }
        
        // 如果移除的是当前正在播放的歌曲，停止播放
        if index == currentPlayIndex && isPlaying {
            stop()
        }
        
        // 移除播放列表中的指定项
        playlist.remove(at: index)
        
        // 调整当前播放索引
        if index < currentPlayIndex {
            currentPlayIndex -= 1
        } else if index == currentPlayIndex && !playlist.isEmpty {
            currentPlayIndex = 0
        }
        
        // 如果播放列表还有数据，播放第一首
        if !playlist.isEmpty {
            playCurrentTrack()
        } else {
            // 如果播放列表为空，停止播放
            stop()
        }
    }
    
    public func moveOnPlaylist(_ oldIndex: Int, _ newIndex: Int) {
        guard oldIndex >= 0 && oldIndex < playlist.count,
              newIndex >= 0 && newIndex < playlist.count else {
            print("无效的索引：oldIndex: \(oldIndex), newIndex: \(newIndex)")
            return
        }
        
        // 获取要移动的元素
        let element = playlist.remove(at: oldIndex)
        
        // 将元素插入到新位置
        playlist.insert(element, at: newIndex)
        
        // 更新当前播放索引
        if currentPlayIndex == oldIndex {
            currentPlayIndex = newIndex
        } else if oldIndex < currentPlayIndex && newIndex >= currentPlayIndex {
            currentPlayIndex -= 1
        } else if oldIndex > currentPlayIndex && newIndex <= currentPlayIndex {
            currentPlayIndex += 1
        }
    }
    
    public func playNext() {
        playNextTrack()
    }
    
    public func playPrevious() {
        playPreviousTrack()
    }
    
    public func setSpeed(_ speed: Float) {
        let clampedRate = max(0.25, min(speed, 4.0)) // 限制播放速度范围在 0.25 到 4.0 之间
        self.speed = clampedRate
        varispeed.rate = clampedRate
        print("播放速度设置为：\(clampedRate)")
    }

    public func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(volume, 1.0)) // 限制音量范围在 0.0 到 1.0 之间
        self.volume = clampedVolume
        playerNode.volume = clampedVolume
        print("音量设置为：\(clampedVolume)")
    }
    
    public func setIsMute(_ isMute: Bool) {
        self.isMute = isMute
        playerNode.volume = isMute ? 0 : 1;
        print("静音状态为：\(isMute)")
    }
    
    public func setEnableFadeEffect(_ value: Bool) {
        self.enableFadeEffect = value
        print("是否启用淡入淡出：\(value)")
    }
    
    public func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
        print("切换到：\(loopMode)")
    }
    
    public func setBandGain(bandIndex: Int, gain: Float) {
        if isPlaying {
            playOrPause()
        }
        guard bandIndex >= 0 && bandIndex < equalizer.bands.count else {
            print("无效的频段索引： \(bandIndex)/\(equalizer.bands.count) \(gain)")
            return
        }
        let clampedGain = max(-12.0, min(gain, 12.0)) // 限制增益范围在 -12 dB 到 +12 dB 之间
        equalizer.bands[bandIndex].gain = clampedGain
        restartEngine()
        
        if !isPlaying {
            playOrPause()
        }
    }
    
    public func setReverb(id: Int, wetDryMix: Float = 50) {
        let recordTime = playbackProgress
        if isPlaying {
            playOrPause()
        }
        if let preset = AVAudioUnitReverbPreset(rawValue: id) {
            reverb.loadFactoryPreset(preset)
        } else {
            print("无效的混响预设ID: \(id)")
            return
        }
        
        let clampedMix = max(0.0, min(wetDryMix, 100.0)) // 限制混响范围在 0% 到 100% 之间
        reverb.wetDryMix = clampedMix
                
        audioEngine.disconnectNodeInput(varispeed)
        audioEngine.disconnectNodeOutput(varispeed)
        audioEngine.disconnectNodeInput(volumeBooster)
        audioEngine.disconnectNodeOutput(volumeBooster)
        audioEngine.disconnectNodeInput(equalizer)
        audioEngine.disconnectNodeOutput(equalizer)
        audioEngine.disconnectNodeInput(reverb)
        audioEngine.disconnectNodeOutput(reverb)

        audioEngine.connect(playerNode, to: varispeed, format: nil)
        audioEngine.connect(varispeed, to: volumeBooster, format: nil)
        audioEngine.connect(volumeBooster, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: reverb, format: nil)
        audioEngine.connect(reverb, to: audioEngine.mainMixerNode, format: nil)
        
        restartEngine()
        
        self.seekTo(milliseconds: recordTime)
    }

    public func setVolumeBoost(_ gain: Float) {
        let clampedGain = max(0.0, min(gain, 24.0)) // 限制增益范围在 0 dB 到 24 dB 之间
        volumeBooster.bands[0].gain = clampedGain
        print("音量放大器增益设置为：\(clampedGain) dB")
    }

    public func resetAll() {
        let recordTime = playbackProgress
        if isPlaying {
            playOrPause()
        }

        let initialGains: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] // 重置为初始标准模式的增益值
        for i in 0..<equalizer.bands.count {
            equalizer.bands[i].gain = initialGains[i]
        }
        
        audioEngine.disconnectNodeInput(varispeed)
        audioEngine.disconnectNodeOutput(varispeed)
        audioEngine.disconnectNodeInput(volumeBooster)
        audioEngine.disconnectNodeOutput(volumeBooster)
        audioEngine.disconnectNodeInput(equalizer)
        audioEngine.disconnectNodeOutput(equalizer)
        audioEngine.disconnectNodeInput(reverb)
        audioEngine.disconnectNodeOutput(reverb)
        
        audioEngine.connect(playerNode, to: varispeed, format: nil)
        audioEngine.connect(varispeed, to: volumeBooster, format: nil)
        audioEngine.connect(volumeBooster, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil)
        
        restartEngine()
        
        self.seekTo(milliseconds: recordTime)
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
