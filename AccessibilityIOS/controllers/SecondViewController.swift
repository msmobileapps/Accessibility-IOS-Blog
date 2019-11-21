//
//  SecondViewController.swift
//  AccessibilityIOS
//
//  Created by Daniel Radshun on 21/11/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class SecondViewController: UIViewController {
    @IBOutlet weak var wordsToSayTextField: UITextField!
    @IBOutlet weak var recordMeButton: UIButton!
    @IBOutlet weak var recordMeIcon: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pauseIcon: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var stopIcon: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueIcon: UIButton!
    @IBOutlet weak var playIcon: UIButton!
    @IBOutlet weak var lyricsLabel: UILabel!
    @IBOutlet weak var playSongButton: UIButton!
    @IBOutlet weak var playSongIcon: UIButton!
    
    let textToSpeech = TextToSpeech.shared
    let audioToText = AudioToText.shared
    
    @IBAction func readTextWasPressed(_ sender: UIButton) {
        if audioToText.avAudioEngine.isRunning{
            stopRecording()
        }
        textToSpeech.setAudioCategoryToPlayback()
        if !setSpeechWord(){
            return
        }
        swichPauseStopContinueStateTo(true)
        if textToSpeech.avSpeechUtterance != nil{
            if !textToSpeech.avSpeechSynthesizer.isSpeaking{ //check if other speech is not already in progress
                textToSpeech.avSpeechSynthesizer.speak(textToSpeech.avSpeechUtterance!) //start speech
            }
            else{
                textToSpeech.avSpeechSynthesizer.stopSpeaking(at: .immediate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned self] in
                    self.textToSpeech.avSpeechSynthesizer.speak(self.textToSpeech.avSpeechUtterance!) //start speech
                }
            }
        }
    }
    @IBAction func pauseWasPressed(_ sender: UIButton) {
        if textToSpeech.avSpeechSynthesizer.isSpeaking{
            textToSpeech.avSpeechSynthesizer.pauseSpeaking(at: .immediate) //pauses speech imidiatly
            //avSpeechSynthesizer.pauseSpeaking(at: .word) -> pauses after the word ends
        }
    }
    @IBAction func stopWasPressed(_ sender: UIButton) {
        if textToSpeech.avSpeechSynthesizer.isSpeaking{
            textToSpeech.avSpeechSynthesizer.stopSpeaking(at: .immediate) //stops speech imidiatly
            //avSpeechSynthesizer.stopSpeaking(at: .word) -> stops after the word ends
        }
    }
    @IBAction func continueWasPressed(_ sender: UIButton) {
        textToSpeech.avSpeechSynthesizer.continueSpeaking() //resume speech
    }
    @IBAction func recordMeWasPressed(_ sender: UIButton) {
        recordMeButton.setTitle("Loading..", for: .normal)
        if textToSpeech.avSpeechSynthesizer.isSpeaking{
            textToSpeech.avSpeechSynthesizer.stopSpeaking(at: .immediate)
        }
        if !audioToText.isRecordEngineDefined{
            audioToText.defineAudioEngineProperties()
            recordMeButton.isEnabled = false
            recordMeIcon.isEnabled = false
        }
        if !audioToText.avAudioEngine.isRunning{
            startRecording()
            recordMeButton.isEnabled = true
            recordMeIcon.isEnabled = true
        }
        else{
            stopRecording()
        }
    }
    @IBAction func playSongWasPressed(_ sender: UIButton) {
        if audioToText.isPlaying{
            setPlayingSongTo(false)
        }
        else{
            let fileURL = Bundle.main.path(forResource: "LoveTheWayYouLie", ofType: "mp3")!
            audioFileFrom(url: URL(fileURLWithPath: fileURL))
            setPlayingSongTo(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initAccesibility()
        textToSpeech.avSpeechSynthesizer.delegate = self
        hideKeyboardWhenTappedAround()
        swichPauseStopContinueStateTo(false)
    }
    
}

//MARK: Text to speech
extension SecondViewController: AVSpeechSynthesizerDelegate{
    
    private func setSpeechWord() -> Bool{
        let wordsFromUser = wordsToSayTextField.text
        if wordsFromUser == nil || wordsFromUser == ""{
            return false
        }
        
        textToSpeech.setSpeechWord(wordsFromUser!)
        
        return true
    }
    
    private func swichPauseStopContinueStateTo(_ isEnabled: Bool){
        pauseButton.isEnabled = isEnabled
        pauseIcon.isEnabled = isEnabled
        stopButton.isEnabled = isEnabled
        stopIcon.isEnabled = isEnabled
        continueButton.isEnabled = isEnabled
        continueIcon.isEnabled = isEnabled
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.playIcon.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            self.pauseIcon.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.playIcon.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            self.pauseIcon.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.playIcon.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            self.pauseIcon.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.playIcon.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            self.pauseIcon.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.playIcon.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            self.pauseIcon.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) { }
}


//MARK: Live voice to text
extension SecondViewController{
        
        private func startRecording() {
            
            recordMeButton.setTitle("Stop Recording", for: .normal)
            recordMeIcon.setBackgroundImage(UIImage(systemName: "mic.fill"), for: .normal)
            swichPauseStopContinueStateTo(false)
            
            audioToText.startRecording { [unowned self] (result) in
                guard let result = result else {return}
                let transcription = result.bestTranscription
                self.wordsToSayTextField.text = transcription.formattedString
            }
            
        }
        
        private func stopRecording() {
            
            audioToText.stopRecording()
            
            recordMeButton.setTitle("Record Me", for: .normal)
            recordMeIcon.setBackgroundImage(UIImage(systemName: "mic"), for: .normal)
        }
}


//MARK: Recorded voice to text
extension SecondViewController{
    
    private func audioFileFrom(url: URL) {
        
        audioToText.audioFileFrom(url: url) { [unowned self] (result) in
        
            guard let result = result else { return }
            
            let words = result.bestTranscription.segments
            
            if words.count == 0{
                return
            }
            
            var sentence = NSMutableString()
            if words.count > 10{
                for i in 1...9{
                    sentence.append(words[words.count-i].substring)
                    sentence.append(" ")
                }
            }
            else{
                sentence = NSMutableString(string: result.bestTranscription.formattedString)
            }
            
            self.lyricsLabel.text = sentence as String
            
            if result.isFinal {
                self.setPlayingSongTo(false)
            }
        }
    }
    
    private func setPlayingSongTo(_ shouldPlay:Bool){
        audioToText.isPlaying = shouldPlay
        if !shouldPlay {
            audioToText.audioPlayer?.stop()
            audioToText.recognitionTask?.cancel()
            playSongIcon.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            playSongButton.setTitle("Play Song", for: .normal)
            lyricsLabel.text = ""
        }
        else{
            playSongIcon.setBackgroundImage(UIImage(systemName: "stop"), for: .normal)
            playSongButton.setTitle("Stop Song", for: .normal)
        }
    }
}


//MARK: VoiceOver
extension SecondViewController{
    private func initAccesibility(){
        wordsToSayTextField.setAccesibilityProperties(traits: .searchField, label: "Words text field", hint: "Words from here can be said by the play button")
        recordMeButton.setAccesibilityProperties(traits: .button, label: "Record me", hint: "Press here to start recording your voice")
        recordMeIcon.setAccesibilityProperties(traits: .button, label: "Record me icon", hint: "Press here to start recording your voice")
        pauseButton.setAccesibilityProperties(traits: .button, label: "Pause speech", hint: "Press here to pause speech")
        pauseIcon.setAccesibilityProperties(traits: .button, label: "Pause speech icon", hint: "Press here to pause speech")
        stopButton.setAccesibilityProperties(traits: .button, label: "Stop speech", hint: "Press here to stop speech")
        stopIcon.setAccesibilityProperties(traits: .button, label: "Stop speech icon", hint: "Press here to stop speech")
        continueButton.setAccesibilityProperties(traits: .button, label: "Continue speech", hint: "Press here to continue speech")
        continueIcon.setAccesibilityProperties(traits: .button, label: "Continue speech icon", hint: "Press here to continue speech")
        playIcon.setAccesibilityProperties(traits: .button, label: "Play speech icon", hint: "Press here to play speech")
        lyricsLabel.setAccesibilityProperties(traits: .staticText, label: "Song lyrics", hint: "Displays lyrics from played song")
        playSongButton.setAccesibilityProperties(traits: .button, label: "Play song", hint: "Press here to play and stop song")
        playSongIcon.setAccesibilityProperties(traits: .button, label: "Play song icon", hint: "Press here to play and stop song")
    }
}

//Aready exist in ViewController

//extension UIView{
//    func setAccesibilityProperties(traits:UIAccessibilityTraits, label:String, hint:String){
//        self.isAccessibilityElement = true
//        self.accessibilityTraits = traits
//        self.accessibilityLabel = label
//        self.accessibilityHint = hint
//    }
//}
//
////MARK: Guided Access
//extension AppDelegate: UIGuidedAccessRestrictionDelegate{
//
//    var guidedAccessRestrictionIdentifiers: [String]? {
//        return ["com.msapps.AccessibilityIOS.restriction.play.song"]
//    }
//
//    func guidedAccessRestriction(withIdentifier restrictionIdentifier: String, didChange newRestrictionState: UIAccessibility.GuidedAccessRestrictionState) {
//        switch newRestrictionState {
//        case .allow:
//            print("ALLOW")
//        case .deny:
//            print("DENY")
//        default:
//            print("DEFAULT")
//        }
//        NotificationCenter.default.post(name: UIAccessibility.guidedAccessStatusDidChangeNotification, object: restrictionIdentifier)
//    }
//
//    func textForGuidedAccessRestriction(withIdentifier restrictionIdentifier: String) -> String? {
//        return "Play song restriction"
//    }
//
//}

extension SecondViewController{
    
    private func checkIfGuidedAccessIsOn(){
        NotificationCenter.default.addObserver(forName: UIAccessibility.guidedAccessStatusDidChangeNotification, object: nil, queue: .main) { [unowned self] (_) in
            
            print("Guided access state is: ",UIAccessibility.isGuidedAccessEnabled)
            if UIAccessibility.isGuidedAccessEnabled{
                self.playSongButton.isEnabled = false
                self.playSongIcon.isEnabled = false
            }
            else{
                self.playSongButton.isEnabled = true
                self.playSongIcon.isEnabled = true
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkIfGuidedAccessIsOn()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
}


//dissmis keyboard
extension SecondViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 8
    }
}
