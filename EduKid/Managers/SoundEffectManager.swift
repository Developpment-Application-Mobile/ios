//
//  SoundEffectManager.swift
//  EduKid
//
//  Fun and playful sound effect management for kids games
//

import AVFoundation
import AudioToolbox
import UIKit

class SoundEffectManager {
    static let shared = SoundEffectManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Fun Kid-Friendly Sounds
    
    /// Play cheerful "Yay!" sound for correct answers
    func playYay() {
        // NO BEEPS! Just haptic + voice
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Random cheerful voice
        let phrases = ["Yay!", "Awesome!", "Great job!", "Fantastic!", "You rock!", "Amazing!", "Woohoo!", "Super!"]
        speakCheerfully(phrases.randomElement()!, delay: 0.0)
    }
    
    /// Play fun "Pop" sound for interactions
    func playPop() {
        // NO BEEPS! Just light haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Play playful "Ding" sound for achievements
    func playDing() {
        // NO BEEPS! Just haptic + voice
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Encouraging words
        let phrases = ["Correct!", "Yes!", "Perfect!", "Brilliant!", "That's it!"]
        speakCheerfully(phrases.randomElement()!, delay: 0.0)
    }
    
    /// Play friendly "Oops" sound for mistakes
    func playOops() {
        // NO BEEPS! Just gentle haptic + voice
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // Encouraging feedback
        let phrases = ["Oops!", "Try again!", "Not quite!", "Almost!", "Give it another try!"]
        speakEncouragingly(phrases.randomElement()!, delay: 0.0)
    }
    
    /// Play fun "Buzz" sound for wrong attempts
    func playBuzz() {
        // NO BEEPS! Just double haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    /// Play exciting celebration sound with kids cheering
    func playKidsClapping() {
        // Play custom clapping sound from audio file
        playCustomSound(named: "clapping")
        
        // Exciting haptic celebration pattern
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        // Kids cheering voice - very high pitch!
        let bigPhrases = [
            "Yaaay!",
            "Woohoo!",
            "You did it!",
            "Amazing!",
            "You're a star!",
            "Fantastic!",
            "Super job!",
            "Way to go!",
            "You're awesome!"
        ]
        
        speakAsKid(bigPhrases.randomElement()!, delay: 0.5)
    }
    
    /// Play custom audio file
    private func playCustomSound(named fileName: String) {
        // Try to find the audio file in the bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") ??
                        Bundle.main.url(forResource: fileName, withExtension: "wav") ??
                        Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            print("⚠️ Audio file '\(fileName)' not found in bundle")
            return
        }
        
        do {
            // Create and configure audio player
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
            
            // Store player to prevent deallocation
            audioPlayers[fileName] = player
            
            print("🎵 Playing audio: \(fileName)")
        } catch {
            print("❌ Error playing audio '\(fileName)': \(error)")
        }
    }
    
    /// Play victory fanfare (for level completion)
    func playVictory() {
        // Triumphant sound sequence
        AudioServicesPlaySystemSound(1304)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            AudioServicesPlaySystemSound(1109)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            AudioServicesPlaySystemSound(1304)
        }
        
        // Victory haptic pattern
        let impact1 = UIImpactFeedbackGenerator(style: .light)
        impact1.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let impact2 = UIImpactFeedbackGenerator(style: .medium)
            impact2.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            let impact3 = UIImpactFeedbackGenerator(style: .heavy)
            impact3.impactOccurred()
        }
    }
    
    /// Play tap/button sound
    func playTap() {
        AudioServicesPlaySystemSound(1104) // Camera shutter (satisfying click)
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Voice Synthesis Helpers
    
    private func speakCheerfully(_ text: String, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Stop any current speech first
            if self.speechSynthesizer.isSpeaking {
                self.speechSynthesizer.stopSpeaking(at: .immediate)
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.55 // Slightly faster for excitement
            utterance.pitchMultiplier = 1.8 // Very high pitch for kid voice!
            utterance.volume = 1.0 // Maximum volume
            
            if let voice = AVSpeechSynthesisVoice(language: "en-US") {
                utterance.voice = voice
            }
            
            print("🎉 Kid speaking: \(text)")
            self.speechSynthesizer.speak(utterance)
        }
    }
    
    private func speakEncouragingly(_ text: String, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Stop any current speech first
            if self.speechSynthesizer.isSpeaking {
                self.speechSynthesizer.stopSpeaking(at: .immediate)
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.50 // Normal pace for clarity
            utterance.pitchMultiplier = 1.7 // High pitch for kid voice!
            utterance.volume = 1.0 // Maximum volume
            
            if let voice = AVSpeechSynthesisVoice(language: "en-US") {
                utterance.voice = voice
            }
            
            print("🗣️ Kid speaking: \(text)")
            self.speechSynthesizer.speak(utterance)
        }
    }
    
    private func speakExcitedly(_ text: String, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if !self.speechSynthesizer.isSpeaking {
                let utterance = AVSpeechUtterance(string: text)
                utterance.rate = 0.52 // Moderate speed
                utterance.pitchMultiplier = 1.9 // Very high pitch for excited kid!
                utterance.volume = 1.0
                
                if let voice = AVSpeechSynthesisVoice(language: "en-US") {
                    utterance.voice = voice
                }
                
                print("🎊 Kid cheering: \(text)")
            print("🎊 Kid cheering: \(text)")
                self.speechSynthesizer.speak(utterance)
            }
        }
    }
    
    private func speakAsKid(_ text: String, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Stop any current speech
            if self.speechSynthesizer.isSpeaking {
                self.speechSynthesizer.stopSpeaking(at: .immediate)
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.58 // Faster for excitement
            utterance.pitchMultiplier = 2.0 // Maximum pitch for kid voice!
            utterance.volume = 1.0
            
            if let voice = AVSpeechSynthesisVoice(language: "en-US") {
                utterance.voice = voice
            }
            
            print("👶 Kid celebrating: \(text)")
            self.speechSynthesizer.speak(utterance)
        }
    }
    
    // MARK: - Stop All Sounds
    
    func stopAllSounds() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
    }
}
