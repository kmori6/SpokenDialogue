//
//  TTSService.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/27.
//

import Foundation
import Combine
import AVFAudio

final class TTSService {
    private let synthesizer = AVSpeechSynthesizer()
    
    func synthesize(text: String, rate: Float) throws {

        // https://developer.apple.com/documentation/avfoundation/speech-synthesis
        let utt = AVSpeechUtterance(string: text)
        utt.rate = rate
        
        let voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utt.voice = voice
        synthesizer.speak(utt)
    }
}
