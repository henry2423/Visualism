//
//  ArtCollectionCell.swift
//  Visualism
//
//  Created by Henry Huang on 12/26/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit

class ArtCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.0)
        self.imageView.layer.cornerRadius = 4.0
        self.imageView.layer.masksToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        
    }
    
}