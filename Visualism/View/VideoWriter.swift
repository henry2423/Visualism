import Foundation
import AVFoundation
import AssetsLibrary
import Photos

class VideoWriter : NSObject {
    var videoWriter: AVAssetWriter!
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var sessionAtSourceTime: CMTime? = nil
    var fileURL: URL?
    
    func setUpWriter(withSize rect: CGRect) {
        
        do {
            videoWriter = try AVAssetWriter(outputURL: fileURL!, fileType: AVFileType.mov)
            
            // add video input
            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : rect.width,
                AVVideoHeightKey : rect.height,
                AVVideoCompressionPropertiesKey : [
                    AVVideoAverageBitRateKey : 2300000,
                ],
                ])
            
            videoWriterInput.expectsMediaDataInRealTime = true
            let sourcePixelBufferAttributesDictionary = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
                String(kCVPixelBufferWidthKey) : rect.width,
                String(kCVPixelBufferHeightKey) : rect.height,
                String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
                ] as [String : Any]
            
            self.assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
            
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
                print("video input added")
            } else {
                print("no input added")
            }
            
            videoWriter.startWriting()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        
        
    }
    
    func canWrite() -> Bool {
        return videoWriter != nil && videoWriter?.status == .writing
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func append(_ pixelBuffer: CVPixelBuffer, currentSampleTime: CMTime) {
        
        let writable = canWrite()
        
        while !writable {
        }
        
        if sessionAtSourceTime == nil {
            // start writing
            sessionAtSourceTime = currentSampleTime
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }
        
        // Write Video Data
        while !self.assetWriterPixelBufferInput!.assetWriterInput.isReadyForMoreMediaData {
        }
        
        self.assetWriterPixelBufferInput?.append(pixelBuffer, withPresentationTime: currentSampleTime)
    }
    
    // MARK: Start recording
    func start(withSize rect: CGRect, at url: URL) {
        fileURL = url
        setUpWriter(withSize: rect)
        if videoWriter.status == .writing {
            print("status writing")
        } else if videoWriter.status == .failed {
            print("status failed")
        } else if videoWriter.status == .cancelled {
            print("status cancelled")
        } else if videoWriter.status == .unknown {
            print("status unknown")
        } else {
            print("status completed")
        }
    }
    
    // MARK: Stop recording
    func stop(at url: URL, audioURL: URL, completed: @escaping () -> Void) {
        print("marked as finished")
        videoWriter.finishWriting {
            self.mergeFilesWithUrl(videoUrl: url, audioUrl: audioURL, completed: { (mixURL) in
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mixURL)
                }) { saved, error in
                    if saved {
                        completed()
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
        
        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        
        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            
        }catch{
            
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero,duration: aVideoAssetTrack.timeRange.duration )
        
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        mutableVideoComposition.renderSize = CGSize(width: 1280, height: 720)
        
        //        playerItem = AVPlayerItem(asset: mixComposition)
        //        player = AVPlayer(playerItem: playerItem!)
        //
        //
        //        AVPlayerVC.player = player
        
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
        assetExport.shouldOptimizeForNetworkUse = true
        
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSession.Status.completed:
                
                //Uncomment this if u want to store your video in asset
                
                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
                
                print("success")
                completed(savePathUrl)
            case  AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error)")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error)")
            default:
                print("complete")
            }
        }
        
        
    }
}
