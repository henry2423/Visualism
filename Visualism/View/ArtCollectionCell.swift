//
//  ArtCollectionCell.swift
//  Visualism
//
//  Created by Henry Huang on 12/26/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit

class ArtCollectionCell: UICollectionViewCell {
    
    var artStyle: ArtStyles! {
        didSet {
            self.imageView.image = UIImage(named: artStyle.rawValue)
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.layer.cornerRadius = 4.0
        self.imageView.layer.masksToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        
    }
    
}
