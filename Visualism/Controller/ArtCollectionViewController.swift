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
    var collectionView: UICollectionView!
    
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
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width/2-20, height: UIScreen.main.bounds.height/3-30)
        layout.minimumLineSpacing = 20
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "ArtCollectionCell", bundle: nil), forCellWithReuseIdentifier: ArtCollectionReuseIdentifier)
        self.collectionView.backgroundColor = UIColor.black
        self.view.addSubview(collectionView)
    }
    
    // MARK: - UI stuff
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.frame = view.bounds
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
        self.present(StyleVideoConverterViewController(withStyle: style, withURL: videoURL), animated: true, completion: nil)
    }

}
