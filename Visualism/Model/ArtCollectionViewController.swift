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
    
    let ArtCollection = ["Avignon", "Composition_b", "Gray_tree"]
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate
extension ArtCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ArtCollection.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtCollectionReuseIdentifier, for: indexPath) as! ArtCollectionCell
    
        cell.imageView.image = UIImage(named: "\(ArtCollection[indexPath.item]).jpg")
    
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = VisualismViewController(withStyle: ArtCollection[indexPath.item])
        
//        self.pushViewController(vc, animated: true)
//        self.navigationController?.pushViewController(vc, animated: true)
//        navigationVC.pushViewController(vc, animated: true)
//        self.pushViewController(vc, animated: true)
        self.present(vc, animated: true, completion: nil)
    }

}
