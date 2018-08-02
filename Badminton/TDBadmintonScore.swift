//
//  TDBadmintonScore.swift
//  Badminton
//
//  Created by Paul Leo on 10/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import Foundation

struct TDBadmintonScore : CustomDebugStringConvertible {
    var scoreArray : [[Int]]?
    
    var debugDescription: String {
        get {
            guard let score = scoreArray else {
                return "[]"
            }
            var scoreString = "["
            for set in score {
                scoreString += "["
                scoreString += set.map({"\($0)"}).joined(separator: ",")
                scoreString += "]"
            }
            scoreString += "]"

            return scoreString
        }
    }
}
