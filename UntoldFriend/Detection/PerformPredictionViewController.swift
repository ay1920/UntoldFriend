//
//  PerformPredictionViewController.swift
//  UntoldFriend
//
//  Created by Amit Yadav on 13/05/21.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class PerformPredictionViewController: CameraViewController {
    
    private var requests = [VNRequest]()
    private var currentTime = TimeInterval(0)
    private var prvTime = TimeInterval(0)
    private var speechSynthesizer = AVSpeechSynthesizer()

    private lazy var classificationRequest: VNCoreMLRequest = {
      do {
        let model = try VNCoreMLModel(for: SignLanguageClass_v6(configuration: .init()).model)
        let request = VNCoreMLRequest(
          model: model) { [weak self] request, error in
            guard let self = self else {
              return
            }
            self.processClassifications(for: request, error: error)
        }
        request.imageCropAndScaleOption = .centerCrop
        self.requests = [request]
        return request
      } catch {
        fatalError("Failed to load Vision ML model: \(error)")
      }
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.title = ""
    }
    
    
    //MARK: - Custom Methods
    override func setupAVCapture() {
        super.setupAVCapture()
        // setup Vision parts
        
        
        // start the capture
        startCaptureSession()
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
      DispatchQueue.main.async {
        if let classifications =
          request.results as? [VNClassificationObservation] {
          let topClassifications = classifications.prefix(2).map {
            
            (confidence: $0.confidence, identifier: $0.identifier)
          }
          print("Top classifications: \(topClassifications)")
            
            
            let valueMaxElement = topClassifications.max(by: { (a, b) -> Bool in
                return a.confidence < b.confidence
            })
            
            print("Max Confidence: \(valueMaxElement!)")
            
            if let conf = valueMaxElement{
                if conf.confidence > 0.9{
                    self.readOutSignLanguage(sign: conf.identifier)
                }
            }
            
            let topIdentifiers =
              topClassifications.map {$0.identifier.lowercased()
              }
          
            print("Top Identifiers: \(topIdentifiers)")
        }
      }
    }
    
    func readOutSignLanguage(sign:String){
        // Line 2. Create an instance of AVSpeechUtterance and pass in a String to be spoken.
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: sign)
        //Line 3. Specify the speech utterance rate. 1 = speaking extremely the higher the values the slower speech patterns. The default rate, AVSpeechUtteranceDefaultSpeechRate is 0.5
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        // Line 4. Specify the voice. It is explicitly set to English here, but it will use the device default if not specified.
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // Line 5. Pass in the urrerance to the synthesizer to actually speak.
        speechSynthesizer.speak(speechUtterance)
    }
    
    
    //MARK: - AVCapture Delegate
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        //print("Time Difference:\(currentTime-prvTime)")
        if (currentTime-prvTime) > 5 || (currentTime-prvTime) == 0{
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
            do {
                try imageRequestHandler.perform([self.classificationRequest])
            } catch {
                print(error)
            }
            
            prvTime = currentTime
            currentTime = Date().timeIntervalSince1970
            
        }else{
            currentTime = Date().timeIntervalSince1970
        }
        
        
    }
    
    
    
    

    

}
