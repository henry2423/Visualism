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
import VideoToolbox

class VisualismViewController: UIViewController {
    
    // Note: For Art Demo Purpose - Timer
    var restartTimer: Timer?
    var countDownTimer: Timer?
    
    // Bar CollectionView
    var barCollectionView: BarCollectionView!
    
    // Video capture parts
    var videoCapture : VideoCaptureView!
    var model: MLModel!
    
    // Metal View for MLModel output
    var metalView : MetalImageView!
    
    // Capture Image
    private var imageCaptureButton: UIButton!
    private var stylePixelBuffer: CVPixelBuffer?
    
    // Close Button
    var closeBarButton: UIButton!
    var restartButton: UIButton!
    var shareButton: UIButton!
    
    // CountDown View
    var countDown: Int = 3
    var countDownLabelView: UILabel!

    convenience init() {
        // Load Default ML Model
        let artStyle = ArtStyles.Avigon
        self.init(withStyle: artStyle)
    }
    
    init(withStyle style: ArtStyles) {
        self.model = style.getMLModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
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
        closeBarButton.setImage(UIImage(named: "Icon-Aarrow-Down")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeBarButton.tintColor = UIColor.white
        closeBarButton.addTarget(self, action: #selector(closeButtonTapHandler(_:)), for: .touchUpInside)
        closeBarButton.frame = CGRect(x: 30, y: UIApplication.shared.statusBarFrame.height + 25, width: 45, height: 45)
        closeBarButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeBarButton.layer.cornerRadius = 45/2
        closeBarButton.layer.masksToBounds = true
        closeBarButton.isHidden = true
        self.view.addSubview(closeBarButton)
        
        // Add ImageCapture Button
        imageCaptureButton = UIButton()
        imageCaptureButton.setImage(UIImage(named: "iconShutter"), for: .normal)
        imageCaptureButton.addTarget(self, action: #selector(imageCaptureButtonTapHandler(_:)), for: .touchUpInside)
        imageCaptureButton.frame = CGRect(x: UIScreen.main.bounds.midX - 37, y: UIScreen.main.bounds.height - 360, width: 85, height: 300)
        imageCaptureButton.setTitle("倒數拍照", for: .normal)
        imageCaptureButton.setTitleColor(UIColor.white, for: .normal)
        imageCaptureButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        let titleSize = imageCaptureButton.titleLabel!.bounds.size
        let imageSize = imageCaptureButton.imageView!.bounds.size
        imageCaptureButton.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: titleSize.height, right: -(titleSize.width))
        imageCaptureButton.titleEdgeInsets = UIEdgeInsets(top: imageSize.height + 18.0, left: -(imageSize.width + 10.0), bottom: 0.0, right: 0.0)
        imageCaptureButton.isHidden = true
        self.view.addSubview(imageCaptureButton)
        
        // Add Restart Button
        restartButton = UIButton()
        restartButton.setImage(UIImage(named: "Icon-Close"), for: .normal)
        restartButton.imageView?.contentMode = .scaleAspectFill
        restartButton.addTarget(self, action: #selector(restartButtonTapHandler(_:)), for: .touchUpInside)
        restartButton.frame = CGRect(x: UIScreen.main.bounds.midX + 10, y: UIScreen.main.bounds.height - 250, width: 70, height: 70)
        restartButton.isHidden = true
        restartButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        restartButton.layer.cornerRadius = 70/2
        restartButton.layer.masksToBounds = true
        restartButton.isHidden = true
        self.view.addSubview(restartButton)
        
        // Add Share Button
        shareButton = UIButton()
        shareButton.setImage(UIImage(named: "Icon-Share"), for: .normal)
        shareButton.imageView?.contentMode = .scaleAspectFill
        shareButton.addTarget(self, action: #selector(shareButtonTapHandler(_:)), for: .touchUpInside)
        shareButton.frame = CGRect(x: UIScreen.main.bounds.midX - 80, y: UIScreen.main.bounds.height - 250, width: 70, height: 70)
        shareButton.isHidden = true
        shareButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        shareButton.layer.cornerRadius = 70/2
        shareButton.layer.masksToBounds = true
        shareButton.isHidden = true
        self.view.addSubview(shareButton)
        
        // Add Count Down View
        countDownLabelView = UILabel()
        countDownLabelView.text = "\(countDown)"
        countDownLabelView.font = UIFont.boldSystemFont(ofSize: 80)
        countDownLabelView.textColor = UIColor.white
        countDownLabelView.textAlignment = .center
        countDownLabelView.frame = CGRect(x: UIScreen.main.bounds.width - 100, y: UIApplication.shared.statusBarFrame.height + 25, width: 80, height: 80)
        countDownLabelView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        countDownLabelView.layer.cornerRadius = 80/2
        countDownLabelView.layer.masksToBounds = true
        countDownLabelView.isHidden = true
        countDownLabelView.isHidden = true
        self.view.addSubview(countDownLabelView)
        
        // Add BarCollectionViewController
        barCollectionView = BarCollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - 150, width: UIScreen.main.bounds.width, height: 150))
        barCollectionView.selectionDelegate = self
        self.view.addSubview(barCollectionView)
        
        // Activate Teardown Timer
        self.restartTimer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(viewTearDown(_:)), userInfo: nil, repeats: false)
    }
    
    // MARK: - Initialization
    func setUpCamera() {
        videoCapture = VideoCaptureView()
        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Once everything is set up, we can start capturing live video.
                self.closeBarButton.isHidden = false
                self.imageCaptureButton.isHidden = false
                self.videoCapture.start()
            }
        }
    }
    
    // MARK: - ButtonTapHandler
    @objc func imageCaptureButtonTapHandler(_ sender: UIBarButtonItem) {
        self.restartTimer?.invalidate()
        self.countDownLabelView.isHidden = false
        self.countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(captureImage(_:)), userInfo: nil, repeats: true)
        self.imageCaptureButton.isUserInteractionEnabled = false
        self.imageCaptureButton.alpha = 0.7
        self.countDownLabelView.isHidden = false
    }
    
    @objc func captureImage(_ time: Timer) {
        if countDown == 0 {
            self.videoCapture!.stop()
            self.imageCaptureButton.isHidden = true
            self.shareButton.isHidden = false
            self.restartButton.isHidden = false
            self.countDown = 3
            self.countDownLabelView.text = "\(countDown)"
            self.countDownLabelView.isHidden = true
            self.shareButtonTapHandler(UIBarButtonItem())
            time.invalidate()
        } else {
            countDown = countDown - 1
            self.countDownLabelView.text = "\(countDown)"
        }
    }
    
    @objc func closeButtonTapHandler(_ sender: UIBarButtonItem) {
        self.dissmissView()
    }
    
    @objc func restartButtonTapHandler(_ sender: UIBarButtonItem) {
        // Restart Time Scheduler
        self.restartTimer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(viewTearDown(_:)), userInfo: nil, repeats: false)
        self.imageCaptureButton.isHidden = false
        self.imageCaptureButton.isUserInteractionEnabled = true
        self.imageCaptureButton.alpha = 1.0
        self.shareButton.isHidden = true
        self.restartButton.isHidden = true
        self.videoCapture!.start()
    }
    
    @objc func shareButtonTapHandler(_ sender: UIBarButtonItem) {
        // capture image
        var cgImage: CGImage?
        // using previousPixelBuffer not currentPixelBuffer is because currentPixelBuffer is set to nil when coreml do inference
        VTCreateCGImageFromCVPixelBuffer(stylePixelBuffer!, options: nil, imageOut: &cgImage)
        let image = UIImage(cgImage: cgImage!)
        
        // set up activity view controller
        let imageToShare = [ image ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.shareButton
        activityViewController.popoverPresentationController?.sourceRect = self.shareButton.bounds
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ .assignToContact, .mail, .message, .addToReadingList, .openInIBooks, .postToFacebook, .postToTwitter, .print ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    // MARK: - UI stuff
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        metalView.frame = view.bounds
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func viewTearDown(_ time: Timer) {
        self.dissmissView()
    }
    
    func dissmissView() {
        self.restartTimer?.invalidate()
        self.countDownTimer?.invalidate()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Doing inference
    func predictUsingVision(with buffer: CVPixelBuffer) {
        
        do {
            let predictionOutput = try model.prediction(from: StyleInput(image: buffer))
            DispatchQueue.main.async { [weak self] in
                self?.stylePixelBuffer = predictionOutput.featureValue(for: "stylizedImage")!.imageBufferValue!
                self?.metalView.image = CIImage(cvPixelBuffer: (self?.stylePixelBuffer)!)
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

// MARK: BarCollectionViewDelegate
extension VisualismViewController: BarCollectionViewDelegate {
    
    func didSelectStyle(_ style: ArtStyles) {
        self.model = style.getMLModel
    }
    
}

//MARK: - Model Prediction Input Type
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
