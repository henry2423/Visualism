//
//  ViewController.swift
//  SmartMirror
//
//  Created by Henry Huang on 12/7/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class VisualismViewController: UIViewController {
    
    // Video capture parts
    var videoCapture : VideoCaptureView!
    let model = starry_night_640x480_small_a03_q8()
    
    // Metal View for MLModel output
    var metalView : MetalImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCamera()
        // Add Metal Preview View as a subview
        metalView = MetalImageView()
        metalView.imageContentMode = .ScaleAspectFill
        self.view.addSubview(metalView)
    }
    
    // MARK: - Initialization
    func setUpCamera() {
        videoCapture = VideoCaptureView()
        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    // MARK: - UI stuff
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        metalView.frame = view.bounds
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Doing inference
    func predictUsingVision(with buffer: CVPixelBuffer) {
        
        do {
            let predictionOutput = try model.prediction(image: buffer)
            DispatchQueue.main.async {
                self.metalView.image = CIImage(cvPixelBuffer: (predictionOutput.stylizedImage))
            }
        } catch let error as NSError {
            print("CoreML Model Error: \(error)")
        }
        
    }
    
}

// MARK: - VideoCaptureDelegate
extension VisualismViewController: VideoCaptureDelegate {

    func videoCapture(_ capture: VideoCaptureView, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?) {

        guard let pixelBuffer = pixelBuffer else {
            return
        }
        
        self.predictUsingVision(with: pixelBuffer)
    }
}
