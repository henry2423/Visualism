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
    
    var swipeUpAnimation: LOTAnimationView! = LOTAnimationView(name: "hand_swipe_up_gesture")
    var mirrorAnimation: LOTAnimationView! = LOTAnimationView(name: "kagami_mirror_lens_flare")
    
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
        
        // SwipeGestureRecognizer
        let swipeLeft = UISwipeGestureRecognizer(target:self, action:#selector(swipeGestureHandler(_:)))
        swipeLeft.direction = .up
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.mirrorAnimation.play()
        self.swipeUpAnimation.play()
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
