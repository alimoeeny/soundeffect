//
//  SoundFeedback.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import AppKit
import AVFoundation

class SoundFeedback {
    private var lastVolume: Float = 0.0
    
    func playVolumeChangeSound(volume: Float) {
        // Only play if volume actually changed
        guard abs(volume - lastVolume) > 0.01 else { return }
        lastVolume = volume
        
        // Use NSSound for system sounds
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.3
            sound.play()
        }
    }
    
    func playMuteSound() {
        // Use NSSound for system sounds
        if let sound = NSSound(named: "Funk") {
            sound.volume = 0.3
            sound.play()
        }
    }
}
