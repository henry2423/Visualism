import Foundation
import AVFoundation
import AssetsLibrary
import Photos

class VideoWriter : NSObject {
    var videoWriter: AVAssetWriter!
    //var videoWriterInput: AVAssetWriterInput!
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var audioWriterInput: AVAssetWriterInput!
    var sessionAtSourceTime: CMTime? = nil
    var fileURL: URL?
//    lazy var context: CIContext = {
//        let eaglContext = EAGLContext(api: .openGLES3)
//        let options = [CIContextOption.workingColorSpace : NSNull()]
//        return CIContext(eaglContext: eaglContext!, options: options)
//    }()
    
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
            
            // add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
            
            audioWriterInput.expectsMediaDataInRealTime = true
            
            if videoWriter.canAdd(audioWriterInput!) {
                videoWriter.add(audioWriterInput!)
                print("audio input added")
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
        
        if writable, sessionAtSourceTime == nil {
            // start writing
            sessionAtSourceTime = currentSampleTime
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
            //print("Writing")
        }
        
        while !self.assetWriterPixelBufferInput!.assetWriterInput.isReadyForMoreMediaData {
        }
        
        if writable {
            if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
//                var newPixelBuffer: CVPixelBuffer? = nil
//                self.sessionAtSourceTime = currentSampleTime
//                CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
//
//                self.context.render(outputImage, to: newPixelBuffer!, bounds:outputImage.extent, colorSpace: nil)
                
                let success = self.assetWriterPixelBufferInput?.append(pixelBuffer, withPresentationTime: currentSampleTime)
                
                if success == false {
                    print("Pixel Buffer append Failed")
                }
            }
        }

    }
    
    // MARK: Start recording
    func start(withSize rect: CGRect, at url: URL) {
        fileURL = url
        setUpWriter(withSize: rect)
        print(videoWriter)
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
    func stop(at url: URL) {
        print("marked as finished")
        videoWriter.finishWriting {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                if saved {
                    print("Finished")
                }
                
            }
        }
    }
}
