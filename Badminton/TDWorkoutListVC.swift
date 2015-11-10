//
//  TDWorkoutListVC.swift
//  Badminton
//
//  Created by Paul Leo on 25/10/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import UIKit
import HealthKit
import JGProgressHUD
import MHPrettyDate


class TDWorkoutListVC: UITableViewController {
    
    var workouts : [HKSample] = [HKSample]()
    var HUD : JGProgressHUD?
    let speaker = TDSpeechManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveUserInfo:", name:"didReceiveUserInfo", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didHandledAuthorization:", name:"handledAuthorization", object: nil)
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.Dark)
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if appDelegate.isAuthorized() {
                createWorkoutsQuery()
                HUD?.textLabel.text = "Loading workouts...";
            } else {
                HUD?.textLabel.text = "Awaiting Authorisation...";
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let destination = segue.destinationViewController as? TDGraphVC {
            if let index = sender as? Int {
                let startDate = workouts[index].startDate
                let endDate = workouts[index].endDate
                destination.startDate = startDate
                destination.endDate = endDate
            }
        }
    }

    // MARK: WCSessionDelegate
    
    func didHandledAuthorization(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.createWorkoutsQuery()
            
            self.HUD = JGProgressHUD(style: JGProgressHUDStyle.Dark)
            self.HUD?.textLabel.text = "Loading workouts...";
            self.HUD?.showInView(self.view)
            self.HUD?.dismissAfterDelay(15.0)
        }
    }
    
    func didReceiveUserInfo(notification: NSNotification) {
        if let score = notification.userInfo?["score"] as? [[Int]] {
            if speaker.canSpeak() {
                dispatch_async(dispatch_get_main_queue()) {
                    self.speaker.speakScore(score)
                }
            }
        }
        
        guard let startDate = notification.userInfo?["workoutStartDate"] as? NSDate,
            endDate = notification.userInfo?["workoutEndDate"] as? NSDate else { return }
        let workout = HKWorkout(activityType: .Badminton, startDate: startDate, endDate: endDate)
        self.workouts.insert(workout, atIndex: 0)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellId", forIndexPath: indexPath)
        let startDate = workouts[indexPath.row].startDate
        cell.textLabel?.text = MHPrettyDate.prettyDateFromDate(startDate, withFormat: MHPrettyDateFormatWithTime)
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showWorkoutId", sender: indexPath.row)
    }
    
    func createWorkoutsQuery() {
        let predicate = HKQuery.predicateForSamplesWithStartDate(nil, endDate: nil, options: .None)
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let workoutsQuery = HKAnchoredObjectQuery(type: HKObjectType.workoutType(), predicate: predicate,  anchor: nil, limit: Int(HKObjectQueryNoLimit)) { query, samples, deletedObjects, anchor, error in

            if error == nil {
                if let workoutSamples = samples {
                    self.workouts = workoutSamples.reverse()
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.HUD?.dismissAnimated(true)
                        self.tableView.reloadData()
                    }
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        workoutsQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            if error == nil {
                if let workoutSamples = samples {
                    self.workouts += workoutSamples.reverse()
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.HUD?.dismissAnimated(true)
                        self.tableView.reloadData()
                    }
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.healthStore.executeQuery(workoutsQuery)
        }
    }
}

