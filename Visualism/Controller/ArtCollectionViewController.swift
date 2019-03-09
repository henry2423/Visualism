//
//  StyleConvertViewController.swift
//  Visualism
//
//  Created by Henry Huang on 3/7/19.
//  Copyright © 2019 Henry Huang. All rights reserved.
//

import Foundation
import UIKit

private let ArtCollectionReuseIdentifier = "ArtCollectionCell"

class ArtCollectionViewController: UIViewController {
        
    var videoURL: URL!
    let ArtCollectionViewCellSpacingFullScreen: CGFloat = 8.0
    var collectionViewBounds: CGRect!
    var collectionView: UICollectionView!
    var closeBarButton: UIButton!
    
    
    init(withURL url: URL) {
        self.videoURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        // UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        layout.itemSize = CGSize(width: self.view.bounds.width/2-20, height: self.view.bounds.height/3-30)
        layout.minimumLineSpacing = 20
        self.collectionViewBounds = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY + 90, width: self.view.bounds.width, height: self.view.bounds.height - 90)
        self.collectionView = UICollectionView(frame: collectionViewBounds, collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "ArtCollectionCell", bundle: nil), forCellWithReuseIdentifier: ArtCollectionReuseIdentifier)
        self.collectionView.backgroundColor = UIColor.black
        self.view.addSubview(collectionView)
        
        // Add Close Button
        closeBarButton = UIButton()
        closeBarButton.setImage(UIImage(named: "Icon-Aarrow-Down")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeBarButton.tintColor = UIColor.white
        closeBarButton.addTarget(self, action: #selector(closeButtonTapHandler(_:)), for: .touchUpInside)
        closeBarButton.frame = CGRect(x: 30, y: UIApplication.shared.statusBarFrame.height, width: 45, height: 45)
        closeBarButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeBarButton.layer.cornerRadius = 45/2
        closeBarButton.layer.masksToBounds = true
        self.view.addSubview(closeBarButton)
    }
    
    // MARK: - UI stuff
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.frame = self.collectionViewBounds
    }
    
    @objc func closeButtonTapHandler(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate
extension ArtCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ArtStyles.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtCollectionReuseIdentifier, for: indexPath) as! ArtCollectionCell
        
        cell.imageView.image = UIImage(named: ArtStyles.allCases[indexPath.item].rawValue)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let style = ArtStyles.allCases[indexPath.item]
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
        let vc = StyleVideoConverterViewController(withStyle: style, withURL: videoURL)
        vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(vc, animated: false, completion: nil)
    }

}
