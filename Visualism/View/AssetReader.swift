/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Contains the video reader implementation using AVCapture.
 */

import Foundation
import AVFoundation
import Darwin

class AssetReader {
    static private let millisecondsInSecond: Float32 = 1000.0
    
    var frameRateInSeconds: Float32 {
        return self.assetTrack.nominalFrameRate
    }
    
//    var frameRateInSeconds: Float32 {
//        return self.frameRateInMilliseconds / VideoReader.millisecondsInSecond
//    }
//
    var durationInSeconds: Float32 {
        return Float32(CMTimeGetSeconds(self.asset.duration))
    }
    
    var totalFrames: Float32 {
        return self.durationInSeconds * self.frameRateInSeconds
    }
    
    var affineTransform: CGAffineTransform {
        return self.assetTrack.preferredTransform.inverted()
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
    
    private var asset: AVAsset!
    private var assetTrack: AVAssetTrack!
    private var assetReader: AVAssetReader!
    private var assetReaderOutput: AVAssetReaderTrackOutput!
    
    init?(asset: AVAsset, withType MediaType: AVMediaType) {
        self.asset = asset
        let array = self.asset.tracks(withMediaType: MediaType)
        self.assetTrack = array[0]
        
        guard self.restartReading() else {
            return nil
        }
    }
    
    func restartReading() -> Bool {
        do {
            self.assetReader = try AVAssetReader(asset: asset)
        } catch {
            print("Failed to create AVAssetReader object: \(error)")
            return false
        }
        
        switch self.assetTrack.mediaType {
        case .video:
            self.assetReaderOutput = AVAssetReaderTrackOutput(track: self.assetTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
            guard self.assetReaderOutput != nil else {
                return false
            }
        case .audio:
            // Currently Not available
            fatalError()
//            self.assetReaderOutput = AVAssetReaderTrackOutput(track: self.assetTrack, outputSettings: [AVFormatIDKey as String: kAudioFormatLinearPCM])
//            guard self.assetReaderOutput != nil else {
//                return false
//            }
        default:
            fatalError()
        }
        
        self.assetReaderOutput.alwaysCopiesSampleData = true
        
        guard self.assetReader.canAdd(assetReaderOutput) else {
            return false
        }
        
        self.assetReader.add(assetReaderOutput)
        
        return self.assetReader.startReading()
    }
    
    func nextFrame() -> CMSampleBuffer? {
        guard let sampleBuffer = self.assetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        
        return sampleBuffer
    }
}
