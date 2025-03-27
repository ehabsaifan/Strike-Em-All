//
//  SoundService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/26/25.
//

import AVFoundation

protocol SoundServiceProtocol {
    func setCategory(_ category: SoundCategory)
    func playSound(for event: SoundEvent)
    func stopCurrentPlayingAudio()
}

class SoundService: SoundServiceProtocol {
    private var audioPlayers: [SoundEvent: [AVAudioPlayer]] = [:]
    private var category: SoundCategory = .street
    private var currentAudioPlaying: AVAudioPlayer?
    
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
                    print("Found sound for \(fileName)")
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
    
    func setCategory(_ category: SoundCategory) {
        guard self.category != category else {
            return
        }
        self.category = category
        audioPlayers = [:]
        SoundEvent.allCases.forEach { loadSound(for: $0) }
    }
    
    func playSound(for event: SoundEvent) {
        print("Play sound for \(event.rawValue)")
        let x = audioPlayers[event]?.randomElement()
        currentAudioPlaying = x
        x?.play()
    }
    
    func stopCurrentPlayingAudio() {
        print("stop current playing audio")
        currentAudioPlaying?.stop()
    }
}
