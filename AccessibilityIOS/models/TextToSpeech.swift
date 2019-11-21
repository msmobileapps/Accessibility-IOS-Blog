//
//  TextToSpeech.swift
//  AccessibilityIOS
//
//  Created by Daniel Radshun on 21/11/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import AVFoundation

public class TextToSpeech{
    
    public static let shared = TextToSpeech()
    
    let avSpeechSynthesizer = AVSpeechSynthesizer()
    var avSpeechUtterance:AVSpeechUtterance?
    
    private init(){}
    
    func setAudioCategoryToPlayback() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch{
            print(error)
        }
    }
    
    func setSpeechWord(_ wordsFromUser:String, rate:Float = 0.5, pitchMultiplier:Float = 1, volume:Float = 0.5, preUtteranceDelay:TimeInterval = 0, postUtteranceDelay:TimeInterval = 0){
        
        avSpeechUtterance = AVSpeechUtterance(string: wordsFromUser)
        
        var language = "en"
        if let inputLanguage = NSLinguisticTagger.dominantLanguage(for: wordsFromUser) {
            language = inputLanguage
        }
        avSpeechUtterance!.voice = AVSpeechSynthesisVoice(language: language)
        //utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Karen-compact") -> another option
        
        avSpeechUtterance!.rate = rate // 0-1 range
        avSpeechUtterance!.pitchMultiplier = pitchMultiplier // 0.5-2 range
        avSpeechUtterance!.volume = volume //0-1 range
        avSpeechUtterance!.preUtteranceDelay = preUtteranceDelay
        avSpeechUtterance!.postUtteranceDelay = postUtteranceDelay
        
    }
}
