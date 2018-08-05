//
//  TDHealthKitSessionManager.swift
//  Badminton
//
//  Created by Paul Leo on 05/08/2018.
//  Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import HealthKit

class TDHealthKitSessionManager: NSObject {
    let healthStore = HKHealthStore()

    static let sharedManager = TDHealthKitSessionManager()
    private override init() {
        super.init()
    }
    
    public func handleAuthorizationForExtension() {
        self.healthStore.handleAuthorizationForExtension { success, errorOrNil in
            if success {
                NotificationCenter.default.post(name: NSNotification.Name("handledAuthorization"), object: nil)
            }
            
            if let error = errorOrNil {
                print("Error in handling authorization for extension - \(error.localizedDescription)")
            }
        }
    }
    
    public func isAuthorized() -> Bool {
        let status = self.healthStore.authorizationStatus(for: .workoutType())
        if status == .sharingAuthorized {
            return true
        }
        
        return false
    }
}
