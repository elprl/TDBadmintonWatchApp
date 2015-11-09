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
    
    init(healthStore: HKHealthStore, activityType : HKWorkoutActivityType = .Other, locationType : HKWorkoutSessionLocationType = .Unknown) {
        self.healthStore = healthStore
        self.activityType = activityType
        self.locationType = locationType
    }
}

protocol TDWorkoutSessionManagerDelegate: class {
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didStartWorkoutWithDate startDate: NSDate)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didStopWorkoutWithDate endDate: NSDate)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didSaveWorkout workout: HKWorkout)
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateEnergyQuantity energyQuantity: HKQuantity)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateDistanceQuantity distanceQuantity: HKQuantity)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateStepQuantity stepQuantity: HKQuantity)
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateHeartRateSample heartRateSample: HKQuantitySample)

}


class TDWorkoutSessionManager: NSObject, HKWorkoutSessionDelegate {
    let healthStore : HKHealthStore
    var workoutSession: HKWorkoutSession
    
    var workoutStartDate: NSDate?
    var workoutEndDate: NSDate?
    
    var queries: [HKQuery] = []
    var energySamples: [HKQuantitySample] = []
    var distanceSamples: [HKQuantitySample] = []
    var stepSamples: [HKQuantitySample] = []
    var heartRateSamples: [HKQuantitySample] = []
    
    let energyUnit = HKUnit.calorieUnit()
    let distanceUnit = HKUnit.meterUnit()
    let stepUnit = HKUnit.countUnit()
    let countPerMinuteUnit = HKUnit(fromString: "count/min")

    let energyType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
    let distanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!
    let stepType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
    let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    
    var currentEnergyQuantity: HKQuantity {
        get {
            var total : Double = 0.0
            for quant in energySamples {
                total += quant.quantity.doubleValueForUnit(energyUnit)
            }
            return HKQuantity(unit: energyUnit, doubleValue: total)
        }
    }
    
    var currentDistanceQuantity: HKQuantity {
        get {
            var total : Double = 0.0
            for quant in distanceSamples {
                total += quant.quantity.doubleValueForUnit(distanceUnit)
            }
            return HKQuantity(unit: distanceUnit, doubleValue: total)
        }
    }
    
    var currentStepQuantity: HKQuantity {
        get {
            var total : Double = 0.0
            for quant in stepSamples {
                total += quant.quantity.doubleValueForUnit(stepUnit)
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

        self.healthStore.startWorkoutSession(self.workoutSession)
    }
    
    func stopWorkoutAndSave() {
        self.healthStore.endWorkoutSession(self.workoutSession)
    }
    
    func resetSamples() {
        self.energySamples.removeAll()
        self.distanceSamples.removeAll()
        self.stepSamples.removeAll()
        self.heartRateSamples.removeAll()
    }

    //MARK: HKWorkoutSessionDelegate
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            switch toState {
            case .Running:
                self.workoutDidStart(date)
            case .Ended:
                self.workoutDidEnd(date)
            default:
                print("Unexpected state \(toState)")
            }
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        NSLog("Workout Session error : " + error.localizedDescription)
    }
    
    //MARK: internal 
    
    func workoutDidStart(date: NSDate) {
        self.workoutStartDate = date
        
        queries.append(self.createStreamingDistanceQuery(date))
        queries.append(self.createStreamingEnergyQuery(date))
        queries.append(self.createStreamingStepQuery(date))
        queries.append(self.createStreamingHeartRateQuery(date))
        
        for query in queries {
            self.healthStore.executeQuery(query)
        }
        
        self.delegate?.workoutSessionManager(self, didStartWorkoutWithDate: date)
    }
    
    func workoutDidEnd(date: NSDate) {
        self.workoutEndDate = date
        
        for query in queries {
            self.healthStore.stopQuery(query)
        }
        
        self.queries.removeAll()
        
        self.delegate?.workoutSessionManager(self, didStopWorkoutWithDate: date)
        
        self.saveWorkout()
    }
    
    func saveWorkout() {
        guard let startDate = self.workoutStartDate, endDate = self.workoutEndDate else { return }
        
        let metadata = [ HKMetadataKeyExternalUUID: "BadmintonId \(startDate)",  HKMetadataKeyWorkoutBrandName: "Badminton"]

        let workout = HKWorkout(activityType: self.workoutSession.activityType, startDate: startDate, endDate: endDate, duration: endDate.timeIntervalSinceDate(startDate), totalEnergyBurned: self.currentEnergyQuantity, totalDistance: self.currentDistanceQuantity, metadata: metadata)
        
        var allSamples: [HKQuantitySample] = []
        allSamples += self.energySamples
        allSamples += self.distanceSamples
        allSamples += self.heartRateSamples
        allSamples += self.stepSamples
        
        self.healthStore.saveObject(workout) { (success, error) -> Void in
            if success && allSamples.count > 0 {
                self.healthStore.addSamples(allSamples, toWorkout: workout, completion: { (success, error) -> Void in
                    if success {
                        self.delegate?.workoutSessionManager(self, didSaveWorkout: workout)

                        self.resetSamples()
                    } else if error != nil {
                        NSLog("addSamples error : " + error!.localizedDescription)
                    }
                })
            }
        }
    }
    
    //MARK: Data queries
    
    func createStreamingDistanceQuery(workoutStartDate: NSDate) -> HKQuery {
        let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: .None)
        
        let distanceQuery = HKAnchoredObjectQuery(type: self.distanceType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addDistanceSamples(samples)
        }
        
        distanceQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.addDistanceSamples(samples)
        }
        
        return distanceQuery
    }
    
    
    func addDistanceSamples(samples: [HKSample]?) {
        guard let distanceSamples = samples as? [HKQuantitySample] else { return }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.distanceSamples += distanceSamples
            
            self.delegate?.workoutSessionManager(self, didUpdateDistanceQuantity: self.currentDistanceQuantity)
        }
    }
    
    func createStreamingStepQuery(workoutStartDate: NSDate) -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples(workoutStartDate)
        
        let distanceQuery = HKAnchoredObjectQuery(type: self.stepType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addStepSamples(samples)
        }
        
        distanceQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.addStepSamples(samples)
        }
        
        return distanceQuery
    }
    
    
    func addStepSamples(samples: [HKSample]?) {
        guard let stepSamples = samples as? [HKQuantitySample] else { return }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.stepSamples += stepSamples
            
            self.delegate?.workoutSessionManager(self, didUpdateStepQuantity: self.currentStepQuantity)
        }
    }
    
    func createStreamingEnergyQuery(workoutStartDate: NSDate) -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples(workoutStartDate)
        
        let energyQuery = HKAnchoredObjectQuery(type: self.energyType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addEnergySamples(samples)
        }
        
        energyQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.addEnergySamples(samples)
        }
        
        return energyQuery
    }
    
    func addEnergySamples(samples: [HKSample]?) {
        guard let energySamples = samples as? [HKQuantitySample] else { return }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.energySamples += energySamples
            
            self.delegate?.workoutSessionManager(self, didUpdateEnergyQuantity: self.currentEnergyQuantity)
        }
    }
    
    func createStreamingHeartRateQuery(workoutStartDate: NSDate) -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples(workoutStartDate)
        
        // sum the new quantities with the current heartrate quantity
        let sampleHandler = { (samples: [HKQuantitySample]) -> Void in
            var mostRecentSample = self.currentHeartRateSample
            var mostRecentStartDate = mostRecentSample?.startDate ?? NSDate.distantPast()
            
            for sample in samples {
                if mostRecentStartDate.compare(sample.startDate) == .OrderedAscending {
                    mostRecentSample = sample
                    mostRecentStartDate = sample.startDate
                }
            }
            
            self.currentHeartRateSample = mostRecentSample
            
            self.heartRateSamples += samples
            
            if let sample = mostRecentSample {
                self.delegate?.workoutSessionManager(self, didUpdateHeartRateSample: sample)
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
    
    func predicateFromWorkoutSamples(startDate: NSDate) -> NSPredicate {
        return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: nil, options: .None)
    }
    
}

