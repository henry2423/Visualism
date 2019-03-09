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
    var maxFrame: Float = 1.0
    var videoURL: URL!
    var videoFrameSize: CGRect!
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
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        
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
        progressLabel.textColor = UIColor.white
        progressLabel.textAlignment = .center
        progressLabel.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50, y: UIScreen.main.bounds.height / 2, width: 100, height: 50)
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
    
    func updateProgress(withCurrentFrame frame: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.progressView.setProgress(frame/self!.maxFrame, animated: true)
            self?.progressLabel.text = "\(Int(frame/self!.maxFrame * 100))%"
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
        guard let videoReader = AssetReader(asset: asset, withType: .video) else {
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
        
        var frames: Float = 1.0
        self.maxFrame = videoReader.totalFrames

        while true {
            guard let videoFrame = videoReader.nextFrame() else {
                break
            }
            
            let buffer = CMSampleBufferGetImageBuffer(videoFrame)
            if frames == 1.0 {
                // Setup videoWrite for the first time
                self.videoFrameSize = CVImageBufferGetCleanRect(buffer!)
                videoWriter.start(withSize: videoFrameSize, at: self.filePathUrl())
            }
            // Transfer Style
            let stylePixelBuffer = self.predictUsingVision(with: buffer! as CVPixelBuffer)
            // Appned Style Image to videoWriter
            let sampleTime =  CMSampleBufferGetOutputPresentationTimeStamp(videoFrame)
            videoWriter.append(pixelBuffer: stylePixelBuffer!, currentSampleTime: sampleTime)

            frames += 1.0
            self.updateProgress(withCurrentFrame: frames)
        }
        
        videoWriter.stop() {
            self.mergeFilesWithUrl(videoUrl: self.filePathUrl(), audioUrl: self.videoURL, completed: { (mixURL) in
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mixURL)
                }) { saved, error in
                    if saved {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Video Saved", message: "Your Style Video has been saved", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: { _ in
                                self.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            })
        }
        
    }
    
    // MARK: Audio Mixing
    // Ref: https://stackoverflow.com/questions/31984474/swift-merge-audio-and-video-files-into-one-video
    func mergeFilesWithUrl(videoUrl: URL, audioUrl: URL, completed: @escaping (URL) -> Void){
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        //start merge
        let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset : AVAsset = AVAsset(url: audioUrl)
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        // FIXME: If No Audio in the audioUrl
        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        
        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
            
            //if audio file is longer then video file, use videoAsset duration instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
        }catch{
            
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero,duration: aVideoAssetTrack.timeRange.duration )
        
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        
        mutableVideoComposition.renderSize = CGSize(width: videoFrameSize.width, height: videoFrameSize.height)
        
        //find your video on this URl
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/styleVideowithAudio.mp4"
        let savePathUrl = URL(fileURLWithPath: filePath)
        
        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
                print("old styleVideowithAudio file removed")
            }
        } catch {
            print(error)
        }
        
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = false
        
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSession.Status.completed:
                //Uncomment this if u want to store your video in asset
                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
                print("success")
                completed(savePathUrl)
            case  AVAssetExportSession.Status.failed:
                print("failed \(String(describing: assetExport.error))")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
            default:
                print("complete")
            }
        }
        
        
    }
    
}
