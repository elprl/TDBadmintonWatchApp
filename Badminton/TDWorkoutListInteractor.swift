//
//  TDWorkoutListInteractor.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import Viperit
import HealthKit

// MARK: - TDWorkoutListInteractor Class
final class TDWorkoutListInteractor: Interactor {
}

// MARK: - TDWorkoutListInteractor API
extension TDWorkoutListInteractor: TDWorkoutListInteractorApi {
    
    func createWorkoutsQuery() {
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: HKQueryOptions(rawValue: 0))
        //        let sortDescriptor = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let workoutsQuery = HKAnchoredObjectQuery(type: HKObjectType.workoutType(), predicate: predicate,  anchor: nil, limit: Int(HKObjectQueryNoLimit)) { query, samples, deletedObjects, anchor, error in
            
            if error == nil {
                if let workoutSamples = samples {
                    self.presenter.setWorkouts(with: workoutSamples.reversed())
                    DispatchQueue.main.async() {
                        self.presenter.didFinishLoadingData()
                    }
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        workoutsQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            if error == nil {
                self.presenter.insertNewSamples(samples: samples)
                DispatchQueue.main.async() {
                    self.presenter.didFinishLoadingData()
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        TDHealthKitSessionManager.sharedManager.healthStore.execute(workoutsQuery)
    }
}

// MARK: - Interactor Viper Components Api
private extension TDWorkoutListInteractor {
    var presenter: TDWorkoutListPresenterApi {
        return _presenter as! TDWorkoutListPresenterApi
    }
}
