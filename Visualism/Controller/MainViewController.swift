//
//  MainViewController.swift
//  Visualism
//
//  Created by Henry Huang on 12/31/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit
import Lottie

class MainViewController: UIViewController {
    
    lazy var swipeUpAnimation: LOTAnimationView! = LOTAnimationView(name: "hand_swipe_up_gesture")
    lazy var mirrorAnimation: LOTAnimationView! = LOTAnimationView(name: "kagami_mirror_lens_flare")
    var actionButton: UIButton!
    
    // MARK: - UI stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        // MirrorViewAnimation
        mirrorAnimation.frame = UIScreen.main.bounds
        mirrorAnimation.loopAnimation = true
        self.view.addSubview(mirrorAnimation)
        
        // StartButton
        swipeUpAnimation.contentMode = .scaleAspectFit
        swipeUpAnimation.frame = CGRect(x: UIScreen.main.bounds.midX - 100, y: UIScreen.main.bounds.height - 220, width: 200, height: 200)
        swipeUpAnimation.loopAnimation = true
        self.view.addSubview(swipeUpAnimation)
        
        actionButton = UIButton()
        actionButton.setImage(UIImage(named: "Icon-Aarrow-Down")?.withRenderingMode(.alwaysTemplate), for: .normal)
        actionButton.tintColor = UIColor.white
        actionButton.addTarget(self, action: #selector(actionButtonTapHandler(_:)), for: .touchUpInside)
        actionButton.frame = CGRect(x: 30, y: UIApplication.shared.statusBarFrame.height + 25, width: 45, height: 45)
        actionButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        actionButton.layer.cornerRadius = 45/2
        actionButton.layer.masksToBounds = true
        actionButton.isHidden = false
        self.view.addSubview(actionButton)
        
        // SwipeGestureRecognizer
        let swipeLeft = UISwipeGestureRecognizer(target:self, action:#selector(swipeGestureHandler(_:)))
        swipeLeft.direction = .up
        self.view.addGestureRecognizer(swipeLeft)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.mirrorAnimation.play()
        self.swipeUpAnimation.play()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    @objc func actionButtonTapHandler(_ sender: UIBarButtonItem) {
        
        AttachmentHandler.shared.showAttachmentActionSheet(vc: self, button: actionButton)
        AttachmentHandler.shared.videoPickedBlock = { [weak self] (url) in
            self?.present(ArtCollectionViewController(withURL: url), animated: true, completion: nil)
        }
    }
    
    // MARK: - SwipeGestureHandler
    @objc func swipeGestureHandler(_ sender: UISwipeGestureRecognizer) {
        self.mirrorAnimation.stop()
        self.swipeUpAnimation.stop()
        let artStyle = ArtStyles.Avigon
        let vc = VisualismViewController(withStyle: artStyle)
        self.present(vc, animated: true, completion: nil)
    }

}
