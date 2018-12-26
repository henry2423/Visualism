//
//  ViewController.swift
//  Visualism
//
//  Created by Henry Huang on 12/7/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

enum ArtCollectionMLModel: String {
    case Avigon = "Avignon"
    case Composition_b = "Composition_b"
    case Gray_tree = "Gray_tree"
    
    var getMLModel: MLModel {
        switch self {
        case .Avigon:
            return AvignonStyle().model
        case .Composition_b:
            return gray_tree_old().model
        case .Gray_tree:
            return GrayTreeStyle().model
        }
    }
}

class VisualismViewController: UIViewController {
    
    // Video capture parts
    var videoCapture : VideoCaptureView!
    var model: MLModel!
    
    // Metal View for MLModel output
    var metalView : MetalImageView!
    
    // Close Button
    var closeBarButton: UIButton!
    
    init() {
        model = AvignonStyle().model
        super.init(nibName: nil, bundle: nil)
    }
    
    init(withStyle styleName: String) {
        let style = ArtCollectionMLModel.init(rawValue: styleName)
        model = style?.getMLModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        model = AvignonStyle().model
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCamera()
        
        // Add Metal Preview View as a subview
        metalView = MetalImageView()
        metalView.imageContentMode = .ScaleAspectFill
        self.view.addSubview(metalView)
        
        // Add Close Button
        closeBarButton = UIButton()
        closeBarButton.setImage(UIImage(named: "Icon-Close"), for: .normal)
        closeBarButton.addTarget(self, action: #selector(closeButtonTapHandler(_:)), for: .touchUpInside)
        closeBarButton.frame = CGRect(x: 25, y: UIApplication.shared.statusBarFrame.height + 10, width: 30, height: 30)
        closeBarButton.isHidden = true
        self.view.addSubview(closeBarButton)
    }
    
    @objc func closeButtonTapHandler(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Initialization
    func setUpCamera() {
        videoCapture = VideoCaptureView()
        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Once everything is set up, we can start capturing live video.
                self.closeBarButton.isHidden = false
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
            let predictionOutput = try model.prediction(from: StyleInput(image: buffer))
            DispatchQueue.main.async {
                self.metalView.image = CIImage(cvPixelBuffer: predictionOutput.featureValue(for: "stylizedImage")!.imageBufferValue!)
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

/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class StyleInput : MLFeatureProvider {
    
    /// image as color (kCVPixelFormatType_32BGRA) image buffer, 480 pixels wide by 640 pixels high
    var image: CVPixelBuffer
    
    var featureNames: Set<String> {
        get {
            return ["image"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "image") {
            return MLFeatureValue(pixelBuffer: image)
        }
        return nil
    }
    
    init(image: CVPixelBuffer) {
        self.image = image
    }
}

