//
//  ViewController.swift
//  AccessibilityIOS
//
//  Created by Daniel Radshun on 20/11/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
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
    
    let avSpeechSynthesizer = AVSpeechSynthesizer()
    var avSpeechUtterance:AVSpeechUtterance?
    
    var audioPlayer: AVAudioPlayer?
    
    let avAudioEngine = AVAudioEngine()
    var node:AVAudioInputNode?
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer() //the local parametar is automatically the device location
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    var isPermissionRequesed = false
    var isRecordEngineDefined = false
    var isPlaying = false
    
    @IBAction func readTextWasPressed(_ sender: UIButton) {
        if avAudioEngine.isRunning{
            stopRecording()
        }
        setAudioCategoryToPlayback()
        if !setSpeechWord(){
            return
        }
        swichPauseStopContinueStateTo(true)
        if avSpeechUtterance != nil{
            if !avSpeechSynthesizer.isSpeaking{ //check if other speech is not already in progress
                avSpeechSynthesizer.speak(avSpeechUtterance!) //start speech
            }
            else{
                avSpeechSynthesizer.stopSpeaking(at: .immediate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned self] in
                    self.avSpeechSynthesizer.speak(self.avSpeechUtterance!) //start speech
                }
            }
        }
    }
    @IBAction func pauseWasPressed(_ sender: UIButton) {
        if avSpeechSynthesizer.isSpeaking{
            avSpeechSynthesizer.pauseSpeaking(at: .immediate) //pauses speech imidiatly
            //avSpeechSynthesizer.pauseSpeaking(at: .word) -> pauses after the word ends
        }
    }
    @IBAction func stopWasPressed(_ sender: UIButton) {
        if avSpeechSynthesizer.isSpeaking{
            avSpeechSynthesizer.stopSpeaking(at: .immediate) //stops speech imidiatly
            //avSpeechSynthesizer.stopSpeaking(at: .word) -> stops after the word ends
        }
    }
    @IBAction func continueWasPressed(_ sender: UIButton) {
        avSpeechSynthesizer.continueSpeaking() //resume speech
    }
    @IBAction func recordMeWasPressed(_ sender: UIButton) {
        if avSpeechSynthesizer.isSpeaking{
            avSpeechSynthesizer.stopSpeaking(at: .immediate)
        }
        if !isRecordEngineDefined{
            defineAudioEngineProperties()
            isRecordEngineDefined = true
        }
        if !avAudioEngine.isRunning{
            startRecording()
        }
        else{
            stopRecording()
        }
    }
    @IBAction func playSongWasPressed(_ sender: UIButton) {
        if isPlaying{
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
        avSpeechSynthesizer.delegate = self
        hideKeyboardWhenTappedAround()
        swichPauseStopContinueStateTo(false)
    }
    
}

//MARK: Text to speech
extension ViewController: AVSpeechSynthesizerDelegate{
    
    private func setAudioCategoryToPlayback() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch{
            print(error)
        }
    }
    
    private func setSpeechWord() -> Bool{
        let wordsFromUser = wordsToSayTextField.text
        if wordsFromUser == nil || wordsFromUser == ""{
            return false
        }
        avSpeechUtterance = AVSpeechUtterance(string: wordsFromUser!)
        
        var language = "en"
        if let inputLanguage = NSLinguisticTagger.dominantLanguage(for: wordsFromUser!) {
            language = inputLanguage
        }
        avSpeechUtterance!.voice = AVSpeechSynthesisVoice(language: language)
        //utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Karen-compact") -> another option
        
        avSpeechUtterance!.rate = 0.5 // -> deafult, 0-1 range
        avSpeechUtterance!.pitchMultiplier = 1 // -> deafult, 0.5-2 range
        avSpeechUtterance!.volume = 0.5 //0-1 range
        avSpeechUtterance!.preUtteranceDelay = 0
        avSpeechUtterance!.postUtteranceDelay = 0
        
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
            self.setPlayAndPauseIcons(firstStringName: "play.fill", secondStringName: "pause")
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.setPlayAndPauseIcons(firstStringName: "play", secondStringName: "pause.fill")
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.setPlayAndPauseIcons(firstStringName: "play.fill", secondStringName: "pause")
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.setPlayAndPauseIcons(firstStringName: "play", secondStringName: "pause")
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [unowned self] in
            self.setPlayAndPauseIcons(firstStringName: "play", secondStringName: "pause")
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) { }
    
    func setPlayAndPauseIcons(firstStringName: String, secondStringName: String){
        if #available(iOS 13.0, *) {
            self.playIcon.setBackgroundImage(UIImage(systemName: firstStringName), for: .normal)
            self.pauseIcon.setBackgroundImage(UIImage(systemName: secondStringName), for: .normal)
        } else {
            //TODO: Change images
        }
    }
}


//MARK: Live voice to text
extension ViewController{
    
        private func setAudioCategoryToPlayAndRecord() {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
        }
        
        private func requestPermission() {
            SFSpeechRecognizer.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Not available on this device")
                case .notDetermined:
                    print("Not determined")
                @unknown default:
                    print("Unknown")
                }
            }
        }
        
        private func defineAudioEngineProperties() {
            setAudioCategoryToPlayAndRecord()
            //AVAudioEngine creates a singleton and set the correct nodes needed to process the audio bit
            node = avAudioEngine.inputNode
            let outputFormat = node!.outputFormat(forBus: 0)
            node!.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { [unowned self] (buffer, _) in
                self.request.append(buffer)
            }
        }
        
        private func startRecording() {
            if !isPermissionRequesed{
                requestPermission()
                isPermissionRequesed = true
            }
            avAudioEngine.prepare()
            do {
                try avAudioEngine.start()
                
                if speechRecognizer?.isAvailable ?? false{
                    
                    recognitionTask = speechRecognizer?.recognitionTask(with: request) { [unowned self] (result, _) in
                        guard let result = result else {return}
                        let transcription = result.bestTranscription
                        self.wordsToSayTextField.text = transcription.formattedString
                    }
                }
            } catch {
                print(error)
            }
            
            recordMeButton.setTitle("Stop Recording", for: .normal)
            if #available(iOS 13.0, *) {
                recordMeIcon.setBackgroundImage(UIImage(systemName: "mic.fill"), for: .normal)
            } else {
                //TODO: change image
            }
            swichPauseStopContinueStateTo(false)
        }
        
        private func stopRecording() {
            avAudioEngine.stop()
            request.endAudio()
            recognitionTask?.cancel()
            node?.removeTap(onBus: 0)
            node?.reset()
            isRecordEngineDefined = false
            recordMeButton.setTitle("Record Me", for: .normal)
            if #available(iOS 13.0, *) {
                recordMeIcon.setBackgroundImage(UIImage(systemName: "mic"), for: .normal)
            } else {
                //TODO: change image
            }
        }
}


//MARK: Recorded voice to text
extension ViewController{
    
    private func audioFileFrom(url: URL) {
            if !isPermissionRequesed{
                requestPermission()
                isPermissionRequesed = true
            }
            setAudioCategoryToPlayAndRecord()
            
            do{
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            } catch{
                print(error)
            }
            audioPlayer?.play()

            if speechRecognizer == nil{
                return
            }
          
            if !speechRecognizer!.isAvailable {
                print("Speech recognition is not available")
                return
            }
          
            let request = SFSpeechURLRecognitionRequest(url: url)
          
            recognitionTask = speechRecognizer!.recognitionTask(with: request) { [unowned self] (result, error) in
            
                guard let result = result else { return }
                
                let words = result.bestTranscription.segments
                
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
        isPlaying = shouldPlay
        if !shouldPlay {
            audioPlayer?.stop()
            recognitionTask?.cancel()
            if #available(iOS 13.0, *) {
                playSongIcon.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            } else {
                //TODO: change image
            }
            playSongButton.setTitle("Play Song", for: .normal)
            lyricsLabel.text = ""
        }
        else{
            if #available(iOS 13.0, *) {
                playSongIcon.setBackgroundImage(UIImage(systemName: "stop"), for: .normal)
            } else {
                //TODO: change image
            }
            playSongButton.setTitle("Stop Song", for: .normal)
        }
    }
}


//MARK: VoiceOver
extension ViewController{
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

extension UIView{
    func setAccesibilityProperties(traits:UIAccessibilityTraits, label:String, hint:String){
        self.isAccessibilityElement = true
        self.accessibilityTraits = traits
        self.accessibilityLabel = label
        self.accessibilityHint = hint
    }
}

//MARK: Guided Access
extension AppDelegate: UIGuidedAccessRestrictionDelegate{
    
    var guidedAccessRestrictionIdentifiers: [String]? {
        return ["com.msapps.AccessibilityIOS.restriction.play.song"]
    }
    
    func guidedAccessRestriction(withIdentifier restrictionIdentifier: String, didChange newRestrictionState: UIAccessibility.GuidedAccessRestrictionState) {
        switch newRestrictionState {
        case .allow:
            print("ALLOW")
        case .deny:
            print("DENY")
        default:
            print("DEFAULT")
        }
        NotificationCenter.default.post(name: UIAccessibility.guidedAccessStatusDidChangeNotification, object: restrictionIdentifier)
    }
    
    func textForGuidedAccessRestriction(withIdentifier restrictionIdentifier: String) -> String? {
        return "Play song restriction"
    }

}

extension ViewController{
    
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
extension ViewController {
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
