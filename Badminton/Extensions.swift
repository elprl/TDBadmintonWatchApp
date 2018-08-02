//
//  Extensions.swift
//  Badminton
//
//  Created by Paul Leo on 29/01/2016.
//  Copyright © 2016 TapDigital Ltd. All rights reserved.
//

import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
}
