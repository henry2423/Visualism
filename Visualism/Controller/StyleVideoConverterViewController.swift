//
//  StyleVideoConverterViewController.swift
//  Visualism
//
//  Created by Henry Huang on 3/8/19.
//  Copyright © 2019 Henry Huang. All rights reserved.
//

import UIKit
import AVKit
import Photos
import Vision

class StyleVideoConverterViewController: UIViewController {
    
    var progressView: UIProgressView!
    var progressLabel: UILabel!
    var maxFrame: Int = 0
    var videoURL: URL!
    var model: MLModel!
    private let converterQueue = DispatchQueue(label: "com.henrystime.videoConvert")
    
    init(withStyle style: ArtStyles, withURL url: URL) {
        self.model = style.getMLModel
        self.videoURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.yellow
        
        // Add ProgressView
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.center = view.center
        //progessView.frame = CGRect(x: 10, y: UIApplication.shared.statusBarFrame.height / 2 - 50, width: UIApplication.shared.statusBarFrame.width - 10, height: 50)
        progressView.trackTintColor = UIColor.lightGray
        progressView.tintColor = UIColor.blue
        progressView.setProgress(0.0, animated: true)
        progressView.isHidden = false
        self.view.addSubview(progressView)
        
        // Add ProgressLabel
        progressLabel = UILabel()
        //progressLabel.font = UIFont.boldSystemFont(ofSize: 20)
        progressLabel.textColor = UIColor.black
        progressLabel.textAlignment = .center
        progressLabel.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50, y: UIScreen.main.bounds.height / 2 + 3, width: 100, height: 50)
        progressLabel.text = "0%"
        progressLabel.isHidden = false
        self.view.addSubview(progressLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start Converting
        converterQueue.async {
            self.converterVideo()
        }
    }
    
    func updateProgress(withCurrentFrame frame: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.progressView.setProgress(Float(frame)/Float(self!.maxFrame), animated: true)
            self?.progressLabel.text = "\(Int(Float(frame)/Float(self!.maxFrame) * 100))%"
        }
    }
    
    // MARK: Temp Video Converter URL
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/styleVideo.mp4"
        return filePath
    }
    
    func filePathUrl() -> URL! {
        return URL(fileURLWithPath: self.filePath())
    }
    
}

// MARK: Model Inference
extension StyleVideoConverterViewController {
    
    // MARK: - Doing inference
    func predictUsingVision(with buffer: CVPixelBuffer) -> CVPixelBuffer? {
        
        do {
            let predictionOutput = try model.prediction(from: StyleInput(image: buffer))
            return predictionOutput.featureValue(for: "stylizedImage")!.imageBufferValue!
        } catch let error as NSError {
            print("CoreML Model Error: \(error)")
        }
        
        return nil
    }
    
    func converterVideo() {
        let asset = AVAsset(url: videoURL)
        guard let videoReader = VideoReader(videoAsset: asset) else {
            fatalError()
        }
        
        do {
            if FileManager.default.fileExists(atPath: self.filePath()) {
                try FileManager.default.removeItem(atPath: self.filePath())
                print("old styleVideo file removed")
            }
        } catch {
            print(error)
        }
        
        let videoWriter = VideoWriter()
        
        var frames = 0
        self.maxFrame = Int(videoReader.totalFrames)
        while true {
            guard let frame = videoReader.nextFrame() else {
                break
            }
            
            let buffer = CMSampleBufferGetImageBuffer(frame)
            if frames == 0 {
                // Setup videoWrite for the first time
                videoWriter.start(withSize: CVImageBufferGetCleanRect(buffer!), at: self.filePathUrl())
            }
            // Transfer Style
            let stylePixelBuffer = self.predictUsingVision(with: buffer! as CVPixelBuffer)
            // Appned Style Image to videoWriter
            let sampleTime =  CMSampleBufferGetOutputPresentationTimeStamp(frame)
            videoWriter.append(stylePixelBuffer!, currentSampleTime: sampleTime)
            
            frames += 1
            self.updateProgress(withCurrentFrame: frames)
        }
        
        videoWriter.stop(at: self.filePathUrl(), audioURL: self.videoURL) {
            let alert = UIAlertController(title: "Video Saved", message: "Your Style Video has been saved", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
    }
    
}
