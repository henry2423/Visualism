/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Contains the video reader implementation using AVCapture.
 */

import Foundation
import AVFoundation
import Darwin

internal class VideoReader {
    static private let millisecondsInSecond: Float32 = 1000.0
    
    var frameRateInSeconds: Float32 {
        return self.videoTrack.nominalFrameRate
    }
    
//    var frameRateInSeconds: Float32 {
//        return self.frameRateInMilliseconds / VideoReader.millisecondsInSecond
//    }
//
    var durationInSeconds: Float32 {
        return Float32(CMTimeGetSeconds(self.videoAsset.duration))
    }
    
    var totalFrames: Float32 {
        return self.durationInSeconds * self.frameRateInSeconds
    }
    
    var affineTransform: CGAffineTransform {
        return self.videoTrack.preferredTransform.inverted()
    }
    
    var orientation: CGImagePropertyOrientation {
        let angleInDegrees = atan2(self.affineTransform.b, self.affineTransform.a) * CGFloat(180) / CGFloat.pi
        
        var orientation: UInt32 = 1
        switch angleInDegrees {
        case 0:
            orientation = 1 // Recording button is on the right
        case 180:
            orientation = 3 // abs(180) degree rotation recording button is on the right
        case -180:
            orientation = 3 // abs(180) degree rotation recording button is on the right
        case 90:
            orientation = 8 // 90 degree CW rotation recording button is on the top
        case -90:
            orientation = 6 // 90 degree CCW rotation recording button is on the bottom
        default:
            orientation = 1
        }
        
        return CGImagePropertyOrientation(rawValue: orientation)!
    }
    
    private var videoAsset: AVAsset!
    private var videoTrack: AVAssetTrack!
    private var assetReader: AVAssetReader!
    private var videoAssetReaderOutput: AVAssetReaderTrackOutput!
    
    init?(videoAsset: AVAsset) {
        self.videoAsset = videoAsset
        let array = self.videoAsset.tracks(withMediaType: AVMediaType.video)
        self.videoTrack = array[0]
        
        guard self.restartReading() else {
            return nil
        }
    }
    
    func restartReading() -> Bool {
        do {
            self.assetReader = try AVAssetReader(asset: videoAsset)
        } catch {
            print("Failed to create AVAssetReader object: \(error)")
            return false
        }
        
        self.videoAssetReaderOutput = AVAssetReaderTrackOutput(track: self.videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        guard self.videoAssetReaderOutput != nil else {
            return false
        }
        
        self.videoAssetReaderOutput.alwaysCopiesSampleData = true
        
        guard self.assetReader.canAdd(videoAssetReaderOutput) else {
            return false
        }
        
        self.assetReader.add(videoAssetReaderOutput)
        
        return self.assetReader.startReading()
    }
    
    func nextFrame() -> CMSampleBuffer? {
        guard let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        
        return sampleBuffer
    }
}
