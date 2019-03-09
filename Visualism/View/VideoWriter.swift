import Foundation
import AVFoundation
import AssetsLibrary

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
    func append(pixelBuffer: CVPixelBuffer, currentSampleTime: CMTime) {
        
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
    func stop(completed: @escaping () -> Void) {
        assetWriterPixelBufferInput?.assetWriterInput.markAsFinished()
        print("marked as finished")
        videoWriter.finishWriting {
            completed()
        }
    }
}
