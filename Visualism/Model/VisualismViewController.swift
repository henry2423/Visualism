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
    var ADKGLView : ADKOpenGLImageView!

//    // Vision parts
//    private var analysisRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add preview View as a subview
        setUpCamera()
        ADKGLView = ADKOpenGLImageView()
        ADKGLView.contentMode = .scaleAspectFill
        self.view.addSubview(ADKGLView)
    }
    
    // MARK: - Initialization
    
//    @discardableResult
//    func setUpVision() -> NSError? {
//        let error : NSError! = nil
//
//        do {
//            let visionModel = try VNCoreMLModel(for: starry_night_640x480_025().model)
//            let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] (request, error) in
//                guard let results = request.results else { return }
//
//                for case let styleTransferedImage as VNPixelBufferObservation in results {
//                    DispatchQueue.main.async {
//                        self?.styleImage.backgroundColor = UIColor.red.cgColor
//                        self?.styleImage.contents = CIImage(cvPixelBuffer: styleTransferedImage.pixelBuffer, options: [:])
//                        //self?.imageView.layer.addSublayer(imageLayer)
//                    }
//                }
//            }
//
//            // NOTE: If you choose another crop/scale option, then you must also
//            // change how the BoundingBox objects get scaled when they are drawn.
//            // Currently they assume the full input image is used.
//            objectRecognition.imageCropAndScaleOption = .scaleFill
//
//            self.analysisRequests.append(objectRecognition)
//        } catch let error as NSError {
//            print("Error: could not create Vision model: \"\(error)\"")
//        }
//
//        return error
//    }
    
    func setUpCamera() {
        videoCapture = VideoCaptureView()
        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
//                // Add the video preview into the UI.
//                if let previewLayer = self.videoCapture.previewLayer {
//                    self.videoPreview.layer.addSublayer(previewLayer)
//                    self.resizePreviewLayer()
//                }
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    // MARK: - UI stuff
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        ADKGLView.frame = view.bounds
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Doing inference
    func predictUsingVision(with buffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        
        // Vision will automatically resize the input image.
//        let handler = VNImageRequestHandler(cvPixelBuffer: image) //, orientation: orientation)
//        do {
//            try handler.perform(self.analysisRequests)
//        } catch {
//            print("Error: Vision request failed with error \"\(error)\"")
//        }
        

//        let styleArray = try? MLMultiArray(shape: [1] as [NSNumber], dataType: .double)
//        styleArray?[0] = 1.0
//
//          let ciImage = CIImage(cvPixelBuffer: buffer)
////        let srcWidth = CGFloat(ciImage.extent.width)
////        let srcHeight = CGFloat(ciImage.extent.height)
////
////        let dstWidth: CGFloat = 256
////        let dstHeight: CGFloat = 256
////
////        let scaleX = dstWidth / srcWidth
////        let scaleY = dstHeight / srcHeight
////        let scale = min(scaleX, scaleY)
////
////        let transform = CGAffineTransform.init(scaleX: scale, y: scale)
////        let output = ciImage.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: dstWidth, height: dstHeight))
//        let tempContext = CIContext(options: nil)
//        let tempImage = tempContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: 256, height: 256))
        // set input size of the model
//        let modelInputSize = CGSize(width: 720, height: 1280)
//
//        // create a cvpixel buffer
//        var pixelBuffer : CVPixelBuffer?
//        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
//        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(modelInputSize.width), Int(modelInputSize.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
//        guard (status == kCVReturnSuccess) else {
//            return
//        }
////
////        // put bytes into pixelBuffer
//        let context = CIContext()
//        context.render(ciImage, to: pixelBuffer!)

    
//        guard let image = getPixelBuffer(from: UIImage(pixelBuffer: buffer)!) else {
//            return
//        }
        
        do {
            let predictionOutput = try model.prediction(image: buffer) // , index: styleArray!
//            let ciImage = CIImage(cvPixelBuffer: predictionOutput.stylizedImage)
//            let tempContext = CIContext(options: nil)
//            let tempImage = tempContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(predictionOutput.stylizedImage), height: CVPixelBufferGetHeight(predictionOutput.stylizedImage)))
            //let predImage = CIImage(cvPixelBuffer: (predictionOutput.stylizedImage))
            DispatchQueue.main.async {
                self.ADKGLView.image = CIImage(cvPixelBuffer: (predictionOutput.stylizedImage))
            }
        } catch let error as NSError {
            print("CoreML Model Error: \(error)")
        }
    }
    /**
     Resizes a CVPixelBuffer to a new width and height.
     */
    public func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                                  width: Int, height: Int,
                                  output: CVPixelBuffer, context: CIContext) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        context.render(scaledImage, to: output)
    }

    
    func getPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let width = 720
        let height = 1280
        // 1
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // 2
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        // 3
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        // 4
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        // 5
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // 6
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    
}


extension VisualismViewController: VideoCaptureDelegate {

    func videoCapture(_ capture: VideoCaptureView, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?) {

        guard let pixelBuffer = pixelBuffer else {
            return
        }

        self.predictUsingVision(with: pixelBuffer)
    }
}

//extension UIImage {
//    public convenience init?(pixelBuffer: CVPixelBuffer) {
//        var cgImage: CGImage?
//        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
//
//        if let cgImage = cgImage {
//            self.init(cgImage: cgImage)
//        } else {
//            return nil
//        }
//    }
//}
