//
//  TDWorkoutManager.swift
//  Badminton
//
//  Created by Paul Leo on 01/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import Foundation
import HealthKit
import WatchKit

class TDWorkoutSessionContext {
    let healthStore : HKHealthStore
    var activityType : HKWorkoutActivityType
    var locationType : HKWorkoutSessionLocationType
    
    init(healthStore: HKHealthStore, activityType : HKWorkoutActivityType = .other, locationType : HKWorkoutSessionLocationType = .unknown) {
        self.healthStore = healthStore
        self.activityType = activityType
        self.locationType = locationType
    }
}

protocol TDWorkoutSessionManagerDelegate: class {
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didStartWorkoutWithDate startDate: Date)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didStopWorkoutWithDate endDate: Date)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didSaveWorkout workout: HKWorkout)
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateEnergyQuantity energyQuantity: HKQuantity)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateDistanceQuantity distanceQuantity: HKQuantity)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateStepQuantity stepQuantity: HKQuantity)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateHeartRateSample heartRateSample: HKQuantitySample)

}


class TDWorkoutSessionManager: NSObject, HKWorkoutSessionDelegate {
    let healthStore : HKHealthStore
    var workoutSession: HKWorkoutSession
    
    var workoutStartDate: Date?
    var workoutEndDate: Date?
    
    var queries: [HKQuery] = []
    var energySamples: [HKQuantitySample] = []
    var distanceSamples: [HKQuantitySample] = []
    var stepSamples: [HKQuantitySample] = []
    var heartRateSamples: [HKQuantitySample] = []
    var workoutMetadata: [String: Any] = [HKMetadataKeyWorkoutBrandName: "BadmintonWakt"]
    
    let energyUnit = HKUnit.kilocalorie()
    let distanceUnit = HKUnit.meter()
    let stepUnit = HKUnit.count()
    let countPerMinuteUnit = HKUnit(from: "count/min")

    let energyType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
    let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
    let stepType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    
    var currentEnergyQuantity: HKQuantity {
        get {
            var total : Double = 0.0
            for quant in energySamples {
                total += quant.quantity.doubleValue(for: energyUnit)
            }
            return HKQuantity(unit: energyUnit, doubleValue: total)
        }
    }
    
    var currentDistanceQuantity: HKQuantity {
        get {
            var total : Double = 0.0
            for quant in distanceSamples {
                total += quant.quantity.doubleValue(for: distanceUnit)
            }
            return HKQuantity(unit: distanceUnit, doubleValue: total)
        }
    }
    
    var currentStepQuantity: HKQuantity {
        get {
            var total : Double = 0.0
            for quant in stepSamples {
                total += quant.quantity.doubleValue(for: stepUnit)
            }
            return HKQuantity(unit: stepUnit, doubleValue: total)
        }
    }
    
    var currentHeartRateSample: HKQuantitySample?
    let sessionContext : TDWorkoutSessionContext
    
    weak var delegate: TDWorkoutSessionManagerDelegate?
    
    init(context: TDWorkoutSessionContext) {
        self.sessionContext = context
        self.healthStore = context.healthStore
        self.workoutSession = HKWorkoutSession(activityType: sessionContext.activityType, locationType: sessionContext.locationType)

        super.init()
    }
    
    func startWorkout() {
        self.workoutSession = HKWorkoutSession(activityType: sessionContext.activityType, locationType: sessionContext.locationType)
        self.workoutSession.delegate = self

        self.healthStore.start(self.workoutSession)
    }
    
    func stopWorkoutAndSave() {
        self.healthStore.end(self.workoutSession)
    }
    
    func resetSamples() {
        self.energySamples.removeAll()
        self.distanceSamples.removeAll()
        self.stepSamples.removeAll()
        self.heartRateSamples.removeAll()
    }

    //MARK: HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async() { () -> Void in
            switch toState {
            case .running:
                self.workoutDidStart(date: date)
            case .ended:
                self.workoutDidEnd(date: date)
            default:
                print("Unexpected state \(toState)")
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        NSLog("Workout Session error : " + error.localizedDescription)
    }
    
    //MARK: internal 
    
    func workoutDidStart(date: Date) {
        self.workoutStartDate = date
        
        queries.append(self.createStreamingDistanceQuery(workoutStartDate: date))
        queries.append(self.createStreamingEnergyQuery(workoutStartDate: date))
        queries.append(self.createStreamingStepQuery(workoutStartDate: date))
        queries.append(self.createStreamingHeartRateQuery(workoutStartDate: date))
        
        for query in queries {
            self.healthStore.execute(query)
        }
        
        self.delegate?.workoutSessionManager(workoutSessionManager: self, didStartWorkoutWithDate: date)
    }
    
    func workoutDidEnd(date: Date) {
        self.workoutEndDate = date
        
        for query in queries {
            self.healthStore.stop(query)
        }
        
        self.queries.removeAll()
        
        self.delegate?.workoutSessionManager(workoutSessionManager: self, didStopWorkoutWithDate: date)
        
        self.saveWorkout()
    }
    
    func saveWorkout() {
        guard let startDate = self.workoutStartDate, let endDate = self.workoutEndDate else { return }
        
//        let metadata = [HKMetadataKeyWorkoutBrandName: "BadmintonWakt"]

        let workout = HKWorkout(activityType: self.workoutSession.activityType, start: startDate, end: endDate, duration: endDate.timeIntervalSince(startDate), totalEnergyBurned: self.currentEnergyQuantity, totalDistance: self.currentDistanceQuantity, metadata: self.workoutMetadata)
        
        var allSamples: [HKQuantitySample] = []
        allSamples += self.energySamples
        allSamples += self.distanceSamples
        allSamples += self.heartRateSamples
        allSamples += self.stepSamples
        
        self.healthStore.save(workout) { (success, error) -> Void in
            if success && allSamples.count > 0 {
                self.healthStore.add(allSamples, to: workout, completion: { (success, error) -> Void in
                    if success {
                        self.delegate?.workoutSessionManager(workoutSessionManager: self, didSaveWorkout: workout)

                        self.resetSamples()
                    } else if error != nil {
                        NSLog("addSamples error : " + error!.localizedDescription)
                    }
                })
            }
        }
    }
    
    //MARK: Data queries
    
    func createStreamingDistanceQuery(workoutStartDate: Date) -> HKQuery {
        let predicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: HKQueryOptions(rawValue: 0))
        
        let distanceQuery = HKAnchoredObjectQuery(type: self.distanceType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addDistanceSamples(samples: samples)
        }
        
        distanceQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.addDistanceSamples(samples: samples)
        }
        
        return distanceQuery
    }
    
    
    func addDistanceSamples(samples: [HKSample]?) {
        guard let distanceSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async() { () -> Void in
            self.distanceSamples += distanceSamples
            
            self.delegate?.workoutSessionManager(workoutSessionManager: self, didUpdateDistanceQuantity: self.currentDistanceQuantity)
        }
    }
    
    func createStreamingStepQuery(workoutStartDate: Date) -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples(startDate: workoutStartDate)
        
        let distanceQuery = HKAnchoredObjectQuery(type: self.stepType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addStepSamples(samples: samples)
        }
        
        distanceQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.addStepSamples(samples: samples)
        }
        
        return distanceQuery
    }
    
    
    func addStepSamples(samples: [HKSample]?) {
        guard let stepSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async() { () -> Void in
            self.stepSamples += stepSamples
            
            self.delegate?.workoutSessionManager(workoutSessionManager: self, didUpdateStepQuantity: self.currentStepQuantity)
        }
    }
    
    func createStreamingEnergyQuery(workoutStartDate: Date) -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples(startDate: workoutStartDate)
        
        let energyQuery = HKAnchoredObjectQuery(type: self.energyType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addEnergySamples(samples: samples)
        }
        
        energyQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.addEnergySamples(samples: samples)
        }
        
        return energyQuery
    }
    
    func addEnergySamples(samples: [HKSample]?) {
        guard let energySamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async() { () -> Void in
            self.energySamples += energySamples
            
            self.delegate?.workoutSessionManager(workoutSessionManager: self, didUpdateEnergyQuantity: self.currentEnergyQuantity)
        }
    }
    
    func createStreamingHeartRateQuery(workoutStartDate: Date) -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples(startDate: workoutStartDate)
        
        // sum the new quantities with the current heartrate quantity
        let sampleHandler = { (samples: [HKQuantitySample]) -> Void in
            var mostRecentSample = self.currentHeartRateSample
            var mostRecentStartDate = mostRecentSample?.startDate ?? Date.distantPast
            
            for sample in samples {
                if mostRecentStartDate.compare(sample.startDate) == .orderedAscending {
                    mostRecentSample = sample
                    mostRecentStartDate = sample.startDate
                }
            }
            
            self.currentHeartRateSample = mostRecentSample
            
            self.heartRateSamples += samples
            
            if let sample = mostRecentSample {
                self.delegate?.workoutSessionManager(workoutSessionManager: self, didUpdateHeartRateSample: sample)
            }
        }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: self.heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            if let quantitySamples = samples as? [HKQuantitySample] {
                sampleHandler(quantitySamples)
            }
        }
        
        heartRateQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            if let quantitySamples = samples as? [HKQuantitySample] {
                sampleHandler(quantitySamples)
            }
        }
        
        return heartRateQuery
    }
    
    func predicateFromWorkoutSamples(startDate: Date) -> NSPredicate {
        return HKQuery.predicateForSamples(withStart: startDate, end: nil, options: HKQueryOptions(rawValue: 0))
    }
    
}

/* JSON 

[
{
"time" : 1447611378,
"score" : [
[
21,
0
],
[
3,
21
],
[
29,
30
]
]
},
{
"time" : 1447611378,
"score" : [
[
21,
0
],
[
3,
21
],
[
29,
30
]
]
}
]
*/

