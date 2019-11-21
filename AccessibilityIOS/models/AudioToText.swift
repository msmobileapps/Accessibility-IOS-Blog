//
//  RecordedAudioToText.swift
//  AccessibilityIOS
//
//  Created by Daniel Radshun on 21/11/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import AVFoundation
import Speech

class AudioToText{
    
    public static let shared = AudioToText()
    
    var audioPlayer: AVAudioPlayer?
    
    let avAudioEngine = AVAudioEngine()
    var node:AVAudioInputNode?
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer() //the local parametar is automatically the device location
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    var isPermissionRequesed = false
    var isRecordEngineDefined = false
    var isPlaying = false
    
    private init(){}
    
    func requestPermission() {
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
    
    func setAudioCategoryToPlayAndRecord() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
    }
    
    //MARK: Live audio to text
    
    func defineAudioEngineProperties() {
        setAudioCategoryToPlayAndRecord()
        //AVAudioEngine creates a singleton and set the correct nodes needed to process the audio bit
        node = avAudioEngine.inputNode
        let outputFormat = node!.outputFormat(forBus: 0)
        node!.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { [unowned self] (buffer, _) in
            self.request.append(buffer)
        }
        isRecordEngineDefined = true
    }
    
    func startRecording(complition: @escaping (_ : SFSpeechRecognitionResult?) -> Void) {
        if !isPermissionRequesed{
            requestPermission()
            isPermissionRequesed = true
        }
        avAudioEngine.prepare()
        do {
            try avAudioEngine.start()
            
            if speechRecognizer?.isAvailable ?? false{
                
                recognitionTask = speechRecognizer?.recognitionTask(with: request) { (result, _) in
                    complition(result)
                }
            }
            else{
                complition(SFSpeechRecognitionResult())
            }
        } catch {
            print(error)
        }
    }
    
    func stopRecording() {
        avAudioEngine.stop()
        request.endAudio()
        recognitionTask?.cancel()
        node?.removeTap(onBus: 0)
        node?.reset()
        isRecordEngineDefined = false
    }
    
    
    //MARK: Recorded audio to text
    
    func audioFileFrom(url: URL, complition: @escaping (_ : SFSpeechRecognitionResult?) -> Void){
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
            complition(SFSpeechRecognitionResult())
        }
      
        if !speechRecognizer!.isAvailable {
            print("Speech recognition is not available")
            complition(SFSpeechRecognitionResult())
        }
      
        let request = SFSpeechURLRecognitionRequest(url: url)
      
        recognitionTask = speechRecognizer!.recognitionTask(with: request) { (result, error) in
            complition(result)
        }
    }
}
