//
//  ArtCollectionModel.swift
//  Visualism
//
//  Created by Henry Huang on 12/27/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import Foundation
import CoreML

enum ArtCollection: String, CaseIterable {
    case Avigon = "Avignon.jpg"
    case Composition_b = "Composition_b.jpg"
    case Gray_tree = "Gray_tree.jpg"
    case Horse = "Horse.jpg"
    case Lion = "Lion.jpg"
    
    var getMLModel: MLModel {
        switch self {
        case .Avigon:
            return AvignonStyle().model
        case .Composition_b:
            return StarryNightStyle().model
        case .Gray_tree:
            return GrayTreeStyle().model
        case .Horse:
            return HorseStyle().model
        case .Lion:
            return LionStyle().model
        }
    }
}
