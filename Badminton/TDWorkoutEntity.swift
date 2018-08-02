//
//  TDWorkout.swift
//  Badminton
//
//  Created by Paul Leo on 05/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import Foundation
import HealthKit

protocol TDScorePointProtocol {
    var scoredAt: Date { get set }
    var gameIndex: UInt8 { get set }
    var forScore: UInt8 { get set }
    var againstScore: UInt8 { get set }
}

protocol TDScoreDataProtocol {
    var points: [TDScorePointProtocol] { get set }
}

extension TDScoreDataProtocol {
    var finalScore: TDScorePointProtocol? {
        get {
            return points.last
        }
    }
}

protocol TDWorkoutProtocol {
    var workoutRecord: HKWorkout { get set }
    var samples: [HKSample]? { get set }
    var scoreData: TDScoreDataProtocol? { get set }
    var isProcessing: Bool { get set }
}



struct TDWorkoutEntity : TDWorkoutProtocol {
    var workoutRecord: HKWorkout
    var samples: [HKSample]?
    var scoreData: TDScoreDataProtocol?
    var isProcessing = true
}
