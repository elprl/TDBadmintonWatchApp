//
//  InterfaceController.swift
//  Badminton WatchKit Extension
//
//  Created by Paul Leo on 25/10/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity

enum TDState {
    case ReadyToBegin
    case Started
    case Ended
}


class InterfaceController: WKInterfaceController, TDWorkoutSessionManagerDelegate {
    @IBOutlet var myMinusBtn: WKInterfaceButton!
    @IBOutlet var myPlusBtn: WKInterfaceButton!
    @IBOutlet var themMinusBtn: WKInterfaceButton!
    @IBOutlet var themPlusBtn: WKInterfaceButton!
    @IBOutlet var timerLbl: WKInterfaceTimer!
    @IBOutlet var scoreLbl: WKInterfaceLabel!
    @IBOutlet var heartRateLbl: WKInterfaceLabel!
    @IBOutlet var mySetScoreLbl: WKInterfaceLabel!
    @IBOutlet var themSetScoreLbl: WKInterfaceLabel!
    @IBOutlet var heartIV: WKInterfaceImage!
    
    var canSaveGame = false
    var canSaveMatch = false
    
    var overallScore : [[Int]] = [[0,0]]
    var isMySaveActive = false
    var isThemSaveActive = false
    var currentState = TDState.ReadyToBegin
    
    let healthStore = HKHealthStore()
    private let _userDefaults = NSUserDefaults.standardUserDefaults()
    
    var sessionContext: TDWorkoutSessionContext?
    var workoutManager : TDWorkoutSessionManager?
    var isAuthorized = false
    
    var transfer : WCSessionUserInfoTransfer?
    
//    private var _timer: NSTimer?
//    private var _ticks: Double = 0.0
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        setScoreString()
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            displayNotAllowed()
            return
        }
        
        guard let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            displayNotAllowed()
            return
        }
        
        guard let stepType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else {
            displayNotAllowed()
            return
        }
        
        guard let energyType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned) else {
            displayNotAllowed()
            return
        }
        
        guard let distanceType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning) else {
            displayNotAllowed()
            return
        }
        
        let typesToShare = Set([HKObjectType.workoutType(),heartRateType,stepType,energyType,distanceType])
        let dataTypes = Set([heartRateType,stepType,energyType,distanceType])
        healthStore.requestAuthorizationToShareTypes(typesToShare, readTypes: dataTypes) { (success, error) -> Void in
            if success {
                self.isAuthorized = true
            } else {
                self.isAuthorized = false
                self.displayNotAllowed()
            }
            
            self.resetMenuItems()
            
            if error != nil {
                print(error?.localizedDescription)
            }
        }

//        if self._timer == nil && self.currentState == .Started {
//            self._timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("timerTick"), userInfo: nil, repeats: true)
//        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
//        _timer?.invalidate()
//        _timer = nil
    }
    
    func resetMenuItems() {
        self.clearAllMenuItems()
        self.addMenuItemWithItemIcon(WKMenuItemIcon.Repeat, title: "Reset Score", action: Selector("resetMenuPressed"))
        if isAuthorized {
            switch currentState {
            case .ReadyToBegin:
                self.addMenuItemWithItemIcon(WKMenuItemIcon.Play, title: "Start", action: Selector("startBtnPressed"))
                break
            case .Started:
                self.addMenuItemWithItemIcon(WKMenuItemIcon.Decline, title: "End", action: Selector("endBtnPressed"))
                break
            case .Ended:
                self.addMenuItemWithItemIcon(WKMenuItemIcon.Play, title: "Start", action: Selector("startBtnPressed"))
                break
                
            }
        }
    }
    
    //MARK: Menu Button events
    
    @IBAction func startBtnPressed() {
        if self.sessionContext == nil || self.workoutManager == nil {
            self.sessionContext = TDWorkoutSessionContext(healthStore: self.healthStore, activityType: .Badminton, locationType: .Indoor)
            self.workoutManager = TDWorkoutSessionManager(context: self.sessionContext!)
            self.workoutManager?.delegate = self
        }
        
        workoutManager?.startWorkout()
//        _timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("timerTick"), userInfo: nil, repeats: true)
        currentState = .Started
        timerLbl.start()
        
        resetMenuItems()
    }
    
    @IBAction func endBtnPressed() {
        workoutManager?.stopWorkoutAndSave()
        currentState = .ReadyToBegin
        timerLbl.stop()
        heartRateLbl.setText("--")

        resetMenuItems()
        
//        _timer?.invalidate()
//        _timer = nil
    }
    
    
    @IBAction func resetMenuPressed() {
        reset()
    }
    
    //MARK: Button events
    
    @IBAction func myMinusBtnPressed() {
        dispatch_async(dispatch_get_main_queue(), {
            let currentSetScore = self.overallScore[self.overallScore.count - 1]
            let mySetScore = currentSetScore[0]
            let themSetScore = currentSetScore[1]

            if mySetScore == 0 {
                return
            }

            let newMySetScore = mySetScore - 1
            self.overallScore[self.overallScore.count - 1][0] = newMySetScore
            self.mySetScoreLbl.setText("\(newMySetScore)")
            
            self.updateVisualState(newMySetScore, themSetScore: themSetScore)
        });

    }

    
    @IBAction func themMinusBtnPressed() {
        dispatch_async(dispatch_get_main_queue(), {
            let currentSetScore = self.overallScore[self.overallScore.count - 1]
            let mySetScore = currentSetScore[0]
            let themSetScore = currentSetScore[1]

            if themSetScore == 0 {
                return
            }
            
            let newMySetScore = themSetScore - 1
            self.overallScore[self.overallScore.count - 1][1] = newMySetScore
            self.themSetScoreLbl.setText("\(newMySetScore)")
            
            self.updateVisualState(mySetScore, themSetScore: newMySetScore)
        });
    }
    
    @IBAction func myPlusBtnPressed() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.isMySaveActive {
                self.saveScore()
                return
            }
            
            let currentSetScore = self.overallScore[self.overallScore.count - 1]
            let mySetScore = currentSetScore[0]
            let themSetScore = currentSetScore[1]
            
            if self.isValidScore(mySetScore, themSetScore: themSetScore) { // won
                let newMySetScore = mySetScore + 1
                self.overallScore[self.overallScore.count - 1][0] = newMySetScore
                self.mySetScoreLbl.setText("\(newMySetScore)")
                
                self.updateVisualState(newMySetScore, themSetScore: themSetScore)
                self.saveScoreMetric()
            }
        });
    }

    
    @IBAction func themPlusBtnPressed() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.isThemSaveActive {
                self.saveScore()
                return
            }
            
            let currentSetScore = self.overallScore[self.overallScore.count - 1]
            let mySetScore = currentSetScore[0]
            let themSetScore = currentSetScore[1]
            
            if self.isValidScore(mySetScore, themSetScore: themSetScore) { // won
                let newMySetScore = themSetScore + 1
                self.overallScore[self.overallScore.count - 1][1] = newMySetScore
                self.themSetScoreLbl.setText("\(newMySetScore)")
                
                self.updateVisualState(mySetScore, themSetScore: newMySetScore)
                self.saveScoreMetric()
            }
        });
    }

    
    //MARK: validation
    
    func isValidScore(mySetScore: Int, themSetScore: Int) -> Bool {
        if mySetScore > themSetScore {
            let difference = mySetScore - themSetScore
            
            if (mySetScore >= 21 && difference > 1) || mySetScore == 30 { // won
                return false
            }
        } else {
            let difference = themSetScore - mySetScore
            
            if (themSetScore >= 21 && difference > 1) || themSetScore == 30 { // won
                return false
            }
        }
        
        return true
    }
    
    func saveScoreMetric() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { // do some task
            guard let manager = self.workoutManager else {return}
            let dateString = "\(NSDate().timeIntervalSince1970)"
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(self.overallScore, options: NSJSONWritingOptions(rawValue: 0))
                let scoreString = String(data: data, encoding: NSUTF8StringEncoding)
                manager.workoutMetadata[dateString] = scoreString
            } catch {
                return
            }
        }
    }
    
    func updateVisualState(mySetScore: Int, themSetScore: Int) {
        setScoreString()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { // do some task
            let userInfo : [String: AnyObject] = ["score": self.overallScore]
            let myDelegate = WKExtension.sharedExtension().delegate as! ExtensionDelegate
            if myDelegate.session.reachable {
                myDelegate.session.sendMessage(userInfo, replyHandler: nil, errorHandler: { error in
                        print(error.localizedDescription)
                })
            }
//            else {
//                self.transfer = myDelegate.session.transferUserInfo(userInfo)
//            }
        }
        
        if mySetScore > themSetScore {
            let difference = mySetScore - themSetScore

            if (mySetScore >= 21 && difference > 1) || mySetScore == 30 { // won
                showSaveSet(true)
                return
            }
        } else {
            let difference = themSetScore - mySetScore
            
            if (themSetScore >= 21 && difference > 1) || themSetScore == 30 { // won
                // set save btn
                showSaveSet(false)
                return
            }
        }
   
        hideSaveSet()        
    }

    func showSaveSet(isMeWon: Bool) {
        if isMeWon {
            myPlusBtn.setBackgroundImageNamed("acceptBtn")
            isMySaveActive = true
        } else {
            themPlusBtn.setBackgroundImageNamed("acceptBtn")
            isThemSaveActive = true
        }
        
        if self.overallScore.count == 3 {
            canSaveMatch = true
        } else {
            canSaveGame = true
        }
    }
    
    func hideSaveSet() {
        myPlusBtn.setBackgroundImageNamed("plusBtn")
        themPlusBtn.setBackgroundImageNamed("plusBtn")
        
        isMySaveActive = false
        isThemSaveActive = false
    }
    
    func saveScore() {
        if overallScore.count < 3 {
            overallScore.append([0,0])
        }
        
        mySetScoreLbl.setText("\(0)")
        themSetScoreLbl.setText("\(0)")

        hideSaveSet()
        
        isMySaveActive = false
        isThemSaveActive = false
        
        setScoreString()
    }
    
    func setScoreString() {
        if overallScore.count == 1 {
            scoreLbl.setText("Score: \(overallScore[0][0]) \(overallScore[0][1])")
        } else if overallScore.count == 2 {
            scoreLbl.setText("\(overallScore[0][0]) \(overallScore[0][1]), \(overallScore[1][0]) \(overallScore[1][1])")
        } else {
            scoreLbl.setText("\(overallScore[0][0]) \(overallScore[0][1]), \(overallScore[1][0]) \(overallScore[1][1]), \(overallScore[2][0]) \(overallScore[2][1])")
        }
    }
    
    func reset() {
        mySetScoreLbl.setText("\(0)")
        themSetScoreLbl.setText("\(0)")
        
        hideSaveSet()
        
        isMySaveActive = false
        isThemSaveActive = false
        
        overallScore = [[0,0]]
        setScoreString()
    }
    
    func displayNotAllowed() {
        heartRateLbl.setText("n/a")
//        stateLbl.setText("Not authorised")
    }
    
    
    func animateHeart() {
        self.animateWithDuration(0.2) {
            self.heartIV.setWidth(20)
            self.heartIV.setHeight(20)
        }
        
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * double_t(NSEC_PER_SEC)))
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_after(when, queue) {
            dispatch_async(dispatch_get_main_queue(), {
                self.animateWithDuration(0.2, animations: {
                    self.heartIV.setWidth(16)
                    self.heartIV.setHeight(16)
                })
            })
        }
    }
    
//    func timerTick() {
//        // Timers are not guaranteed to tick at the nominal rate specified, so this isn't technically accurate.
//        // However, this is just an example to demonstrate how to stop some ongoing activity, so we can live with that inaccuracy.
//        if let startDate = self.workoutManager?.workoutStartDate {
//            let now = NSDate()
//            let interval = now.timeIntervalSinceDate(startDate)
//            let seconds = fmod(interval, 60.0)
//            let minutes = fmod(trunc(interval / 60.0), 60.0)
//            let hours = trunc(interval / 3600.0)
//            let clockString = String.localizedStringWithFormat("%02.0f:%02.0f:%02.0f", hours, minutes, seconds)
//            self.stateLbl.setText(clockString)
//        }
//    }

    // MARK: TDWorkoutSessionManagerDelegate
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didStartWorkoutWithDate startDate: NSDate) {
        currentState = .Started
        resetMenuItems()
        _userDefaults.setDouble(startDate.timeIntervalSince1970, forKey: "workoutStartDate")
        let userInfo : [String: AnyObject] = ["workoutStarted": true]
        let myDelegate = WKExtension.sharedExtension().delegate as! ExtensionDelegate
        if myDelegate.session.reachable {
            myDelegate.session.sendMessage(userInfo, replyHandler: nil, errorHandler: { error in
                print(error.localizedDescription)
            })
        }
    }
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didStopWorkoutWithDate endDate: NSDate) {
        currentState = .ReadyToBegin
        resetMenuItems()
        _userDefaults.setDouble(endDate.timeIntervalSince1970, forKey: "workoutEndDate")
    }
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didSaveWorkout workout: HKWorkout) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let userInfo : [String: AnyObject] = ["workoutStartDate": workout.startDate, "workoutEndDate": workout.endDate, "finalScore": self.overallScore]
            let myDelegate = WKExtension.sharedExtension().delegate as! ExtensionDelegate
            if myDelegate.session.reachable {
                myDelegate.session.sendMessage(userInfo, replyHandler: nil, errorHandler: { error in
                    print(error.localizedDescription)
                })
            }
//            else {
//                self.transfer = myDelegate.session.transferUserInfo(userInfo)
//            }
        }
    }
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateEnergyQuantity energyQuantity: HKQuantity) {
        
    }
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateDistanceQuantity distanceQuantity: HKQuantity) {
        
    }
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateStepQuantity stepQuantity: HKQuantity) {
        
    }
    
    func workoutSessionManager(workoutSessionManager: TDWorkoutSessionManager, didUpdateHeartRateSample heartRateSample: HKQuantitySample) {
        let value = heartRateSample.quantity.doubleValueForUnit(self.workoutManager!.countPerMinuteUnit)
        self.heartRateLbl.setText(String(UInt16(value)))
        self.animateHeart()
    }
    
    // MARK: 
}
