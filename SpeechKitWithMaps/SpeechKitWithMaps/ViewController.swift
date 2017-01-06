//
//  ViewController.swift
//  SpeechKitWithMaps
//
//  Created by Sumit Mendiratta on 11/30/16.
//  Copyright © 2016 Sumit Mendiratta. All rights reserved.
//

import UIKit
import Speech
import CoreLocation

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var micButtonImage: UIButton!
    
    private let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recogTask: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        
        recognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            var isButtonEnabled = false
            
            switch status {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject?) {
        if engine.isRunning {
            engine.stop()
            request?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
            self.micButtonImage.setImage(UIImage(named: "mic"), for: .normal)
            if textView.text.lowercased().contains("map") || textView.text.lowercased().contains("maps") || textView.text.lowercased().contains("navigation") || textView.text.lowercased().contains("navigate") {
                openMaps()
            }
            
        } else {
            startRecording()
            self.micButtonImage.setImage(UIImage(named: "micRecording"), for: .normal)
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recogTask != nil {  //1
            recogTask?.cancel()
            recogTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        request = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = engine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let request = request else {
            fatalError("Unable to create an SFSpeechAudioBufferrequest object")
        } //5
        
        request.shouldReportPartialResults = true  //6
        
        recogTask = recognizer.recognitionTask(with: request, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.engine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.request = nil
                self.recogTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.request?.append(buffer)
        }
        
        engine.prepare()  //12
        
        do {
            try engine.start()
        } catch {
            print("engine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    func openMaps() {
        if !textView.text.isEmpty {
            
            if textView.text.lowercased().contains("map") || textView.text.lowercased().contains("maps") || textView.text.lowercased().contains("navigation") || textView.text.lowercased().contains("navigate") {
                let geocoder = CLGeocoder()
                let str = textView.text ?? "1050 Benton St 95050" // A string of the address info you already have
                geocoder.geocodeAddressString(str) { (placemarksOptional, error) -> Void in
                    if let placemarks = placemarksOptional {
                        print("placemark| \(placemarks.first)")
                        if let location = placemarks.first?.location {
                            let query = "?ll=\(location.coordinate.latitude),\(location.coordinate.longitude)"
                            let path = "http://maps.apple.com/" + query
                            if let url = NSURL(string: path) {
                                UIApplication.shared.openURL(url as URL)
                            } else {
                                // Could not construct url. Handle error.
                            }
                        } else {
                            
                        }
                    } else if error != nil {
                        let alert = UIAlertController(title: "Location Error", message: "Location Not Reconized", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.cancel, handler: {
                            action in
                            self.microphoneTapped(nil)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

