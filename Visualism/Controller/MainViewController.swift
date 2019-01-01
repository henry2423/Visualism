//
//  MainViewController.swift
//  Visualism
//
//  Created by Henry Huang on 12/31/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        // SwipeGestureRecognizer
        let swipeLeft = UISwipeGestureRecognizer(target:self, action:#selector(swipeGestureHandler(_:)))
        swipeLeft.direction = .up
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    // MARK: - SwipeGestureHandler
    @objc func swipeGestureHandler(_ sender: UISwipeGestureRecognizer) {
        let artStyle = ArtStyles.Avigon
        let vc = VisualismViewController(withStyle: artStyle)
        self.present(vc, animated: true, completion: nil)
    }

}
