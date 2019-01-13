//
//  ArtCollectionModel.swift
//  Visualism
//
//  Created by Henry Huang on 12/27/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import Foundation
import CoreML

public enum ArtStyles: String, CaseIterable {
    case Avigon = "Avignon.jpg"
    case Woman = "Woman.jpg"
    case Horse = "Horse.jpg"
    case OldMan = "Old_man.jpg"
    case Lion = "Lion.jpg"
    //case Morning = "Morning.jpg"
    case Gray_tree = "Gray_tree.jpg"

    var getMLModel: MLModel {
        switch self {
        case .Avigon:
            return AvignonStyle().model
        case .Gray_tree:
            return GrayTreeStyle().model
        case .Horse:
            return HorseStyle().model
        case .Lion:
            return LionStyle().model
        case .OldMan:
            return OldManStyle().model
        case .Woman:
            return WomanStyle().model
        }
    }
}
