//
//  TDWorkout.swift
//  Badminton
//
//  Created by Paul Leo on 05/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import Foundation
import HealthKit

class TDWorkout : HKWorkout {
    var score : [[Int]]?
    var scoreData : [Date: [[Int]]]?
    var isProcessing = true
}
