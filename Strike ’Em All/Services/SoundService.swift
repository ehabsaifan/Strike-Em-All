//
//  SoundService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/26/25.
//

import AVFoundation

protocol SoundServiceProtocol {
    var volume: Float { get }
    
    func setCategory(_ category: SoundCategory)
    func playSound(for event: SoundEvent)
    func stopSound(for event: SoundEvent)
    func stopCurrentPlayingAudio()
    func setVolume(_ volume: Float)
}

class SoundService: SoundServiceProtocol, ClassNameRepresentable {
    private var audioPlayers: [SoundEvent: [AVAudioPlayer]] = [:]
    private var category: SoundCategory = .street
    private var currentAudioPlaying: AVAudioPlayer?
    
    private(set) var volume: Float = 1.0 {
        didSet {
            updateVolume()
        }
    }
    
    init(category: SoundCategory) {
        self.category = category
        SoundEvent.allCases.forEach { loadSound(for: $0) }
    }
    
    private func loadSound(for event: SoundEvent) {
        let soundNames = event.getSoundFileNames()
        soundNames.forEach { soundName in
            // "street_rope_pull_heck"
            let fileName = "\(category.getSoundFolderName())_\(soundName)"
            if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
                do {
                    // print("Found sound for \(fileName)")
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    if var list = audioPlayers[event] {
                        list.append(player)
                        audioPlayers[event] = list
                    } else {
                        audioPlayers[event] = [player]
                    }
                } catch {
                    print("Error loading sound for \(event): \(error)")
                }
            } else {
                print("Cant find a resource at the path \(fileName)")
            }
        }
    }
    
    private func updateVolume() {
        for (_, players) in audioPlayers {
            for player in players {
                player.volume = volume
            }
        }
        // Also update the current audio if playing.
        currentAudioPlaying?.volume = volume
    }
    
    func setCategory(_ category: SoundCategory) {
        guard self.category != category else {
            return
        }
        self.category = category
        audioPlayers = [:]
        SoundEvent.allCases.forEach { loadSound(for: $0) }
    }
    
    func playSound(for event: SoundEvent) {
        let x = audioPlayers[event]?.randomElement()
        currentAudioPlaying = x
        x?.play()
    }
    
    func stopSound(for event: SoundEvent) {
        print("Stopping sound for \(event.rawValue)")
        let x = audioPlayers[event]?.randomElement()
        x?.stop()
    }
    
    func stopCurrentPlayingAudio() {
        print("stop current playing audio")
        currentAudioPlaying?.stop()
    }
    
    func setVolume(_ volume: Float) {
        // Clamp to 0...1 range.
        let clampedVolume = min(max(volume, 0.0), 1.0)
        self.volume = clampedVolume
    }
}
