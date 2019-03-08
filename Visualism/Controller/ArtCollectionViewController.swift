//
//  StyleConvertViewController.swift
//  Visualism
//
//  Created by Henry Huang on 3/7/19.
//  Copyright © 2019 Henry Huang. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos
import Vision


private let ArtCollectionReuseIdentifier = "ArtCollectionCell"

class ArtCollectionViewController: UIViewController {
    
    var model: MLModel!
    
    var videoURL: URL!
    let ArtCollectionViewCellSpacingFullScreen: CGFloat = 8.0
    var collectionView: UICollectionView!
    
    init(withURL url: URL) {
        self.videoURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        // UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width/2-20, height: UIScreen.main.bounds.height/3-30)
        layout.minimumLineSpacing = 20
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "ArtCollectionCell", bundle: nil), forCellWithReuseIdentifier: ArtCollectionReuseIdentifier)
        self.collectionView.backgroundColor = UIColor.black
        self.view.addSubview(collectionView)
    }
    
    // MARK: - UI stuff
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.frame = view.bounds
    }
    
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video.mp4"
        return filePath
    }
    
    func filePathUrl() -> URL! {
        return URL(fileURLWithPath: self.filePath())
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate
extension ArtCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ArtStyles.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtCollectionReuseIdentifier, for: indexPath) as! ArtCollectionCell
        
        cell.imageView.image = UIImage(named: ArtStyles.allCases[indexPath.item].rawValue)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.model = ArtStyles.allCases[indexPath.item].getMLModel
        let asset = AVAsset(url: videoURL)
        guard let videoReader = VideoReader(videoAsset: asset), let sampleFrame = videoReader.nextFrame() else {
            fatalError()
        }
        
        do {
            if FileManager.default.fileExists(atPath: self.filePath()) {
                try FileManager.default.removeItem(atPath: self.filePath())
                print("file removed")
            }
        } catch {
            print(error)
        }

        let buffer = CMSampleBufferGetImageBuffer(sampleFrame)
        let video = VideoWriter()
        video.start(withSize: CVImageBufferGetCleanRect(buffer!), at: self.filePathUrl())

        guard videoReader.restartReading() else {
            return
        }
        var frames = 0
        while true {
            guard let frame = videoReader.nextFrame() else {
                break
            }
            frames += 1
            print(frames)
            // Transfer Style
            let buffer = CMSampleBufferGetImageBuffer(frame)
            let sampleTime =  CMSampleBufferGetOutputPresentationTimeStamp(frame)
            let stylePixelBuffer = self.predictUsingVision(with: buffer! as CVPixelBuffer)
            video.append(stylePixelBuffer!, currentSampleTime: sampleTime)
        }

        video.stop(at: self.filePathUrl())
        let alert = UIAlertController(title: "Video Saved", message: "Your Style Video has been saved", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

}

extension CMFormatDescription {
    static func make(from pixelBuffer: CVPixelBuffer) -> CMFormatDescription? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        return formatDescription
    }
}

extension CMSampleBuffer {
    static func make(from pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, timingInfo: inout CMSampleTimingInfo) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
}

// MARK: Model Inference
extension ArtCollectionViewController {
    
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
    
    
}
