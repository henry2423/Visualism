//
//  ArtCollectionViewController.swift
//  Visualism
//
//  Created by Henry Huang on 12/26/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit

private let ArtCollectionReuseIdentifier = "ArtCollectionCell"

class ArtCollectionViewController: UINavigationController {
    
    let ArtCollectionViewCellSpacingFullScreen: CGFloat = 8.0
    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        let artStyle = ArtStyles.allCases[indexPath.item]
//        let vc = VisualismViewController(withStyle: artStyle)
//        self.present(vc, animated: true, completion: nil)
    }

}
