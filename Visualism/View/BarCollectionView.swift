//
//  ViewController.swift
//  ScrollCollectionView
//
//  Created by Henry Huang on 12/28/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit

private let ArtCollectionReuseIdentifier = "ArtCollectionCell"
private let BarItemSize: CGFloat = 120
private let BarItemLineSpacing: CGFloat = 10
private let collectionViewHeightOffset: CGFloat = 20

public protocol BarCollectionViewDelegate: class {
    func didSelectStyle(_ style: ArtStyles)
}

class BarCollectionView: UICollectionView {

    //var feedbackGenerator: UISelectionFeedbackGenerator?
    public weak var selectionDelegate: BarCollectionViewDelegate?
    
    // MARK: - Initialization
    convenience init(frame: CGRect) {
        let layout = SelectingFlowLayout()
        layout.minimumLineSpacing = BarItemLineSpacing
        layout.scrollDirection = .horizontal
        self.init(frame: frame, collectionViewLayout: layout)
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        // UICollectionView
        self.collectionViewLayout = layout
        self.delegate = self
        self.dataSource = self
        self.register(UINib(nibName: "ArtCollectionCell", bundle: nil), forCellWithReuseIdentifier: ArtCollectionReuseIdentifier)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        self.showsHorizontalScrollIndicator = false
        self.contentInset = UIEdgeInsets(top: 0, left: self.bounds.width * 0.5 - BarItemSize * 0.5, bottom: 0, right: self.bounds.width * 0.5 - BarItemSize * 0.5)
        //self.feedbackGenerator = UISelectionFeedbackGenerator()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIScrollView
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let barContentOffset = self.bounds.width * 0.5 - BarItemSize * 0.5
//        let rollingCount = Int((scrollView.contentOffset.x + barContentOffset) / (BarItemSize + BarItemLineSpacing))
//        if rollingCount > 0 {
//            self.feedbackGenerator?.selectionChanged()
//        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Find collectionview cell nearest to the center of collectionView
        // Arbitrarily start with the last cell (as a default)
        var closestCell: UICollectionViewCell = self.visibleCells[0];
        self.visibleCells.forEach { (cell) in
            let closestCellDelta = abs(closestCell.center.x - self.bounds.size.width/2.0 - self.contentOffset.x)
            let cellDelta = abs(cell.center.x - self.bounds.size.width/2.0 - self.contentOffset.x)
            if (cellDelta < closestCellDelta){
                closestCell = cell
            }
        }
        let indexPath = self.indexPath(for: closestCell)
        self.selectionDelegate?.didSelectStyle(ArtStyles.allCases[indexPath!.item])
    }

}


// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension BarCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ArtStyles.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtCollectionReuseIdentifier, for: indexPath) as! ArtCollectionCell
        
        cell.artStyle = ArtStyles.allCases[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let offset = (BarItemSize + BarItemLineSpacing) * CGFloat(indexPath.item)
        self.setContentOffset(CGPoint(x: -(self.bounds.width * 0.5 - BarItemSize * 0.5) + offset, y: 0), animated: true)
        self.selectionDelegate?.didSelectStyle(ArtStyles.allCases[indexPath.item])
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout
extension BarCollectionView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: BarItemSize, height: BarItemSize)
    }
    
}


class SelectingFlowLayout: UICollectionViewFlowLayout {
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let visiableRect = CGRect(x: self.collectionView!.contentOffset.x, y: self.collectionView!.contentOffset.y, width: self.collectionView!.frame.width, height: self.collectionView!.frame.height)
        
        guard let attributes = super.layoutAttributesForElements(in: visiableRect) else {
            return nil
        }
        
        guard let attributesCopy = attributes.map({ $0.copy() }) as? [UICollectionViewLayoutAttributes] else {
            return nil
        }
        guard var closestCell = attributesCopy.first else {
            return nil
        }
        //let centerOffset = collectionView!.bounds.width/2.0 + collectionView!.contentOffset.x
        attributesCopy.forEach { (attribute) in
            let closestCellDelta = abs(closestCell.center.x - collectionView!.bounds.width/2.0 - collectionView!.contentOffset.x)
            let cellDelta = abs(attribute.center.x - collectionView!.bounds.width/2.0 - collectionView!.contentOffset.x)
            if (cellDelta < closestCellDelta){
                closestCell = attribute
            }
//            if abs(attribute.center.x - centerOffset) <= (itemSize.width * 0.5 + 10.0) {
//                attribute.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//            }
        }
        closestCell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        
        return attributesCopy
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let lastRect = CGRect(x: proposedContentOffset.x, y: proposedContentOffset.y, width: self.collectionView!.frame.width, height: self.collectionView!.frame.height)

        let centerX = proposedContentOffset.x + self.collectionView!.frame.width * 0.5;
        //这个范围内所有的属性
        let array = self.layoutAttributesForElements(in: lastRect)
        //需要移动的距离
        var adjustOffsetX = CGFloat(MAXFLOAT);
        for attri in array! {
            if abs(attri.center.x - centerX) < abs(adjustOffsetX) {
                adjustOffsetX = attri.center.x - centerX;
            }
        }
        return CGPoint(x: proposedContentOffset.x + adjustOffsetX, y: proposedContentOffset.y)
    }
    
}
