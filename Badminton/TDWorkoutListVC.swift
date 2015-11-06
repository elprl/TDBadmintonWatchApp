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

class TDWorkoutListVC: UITableViewController {
    
    var workouts : [HKSample] = [HKSample]()
    var HUD : JGProgressHUD?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveUserInfo:", name:"didReceiveUserInfo", object: nil)
        
        createWorkoutsQuery()

        HUD = JGProgressHUD(style: JGProgressHUDStyle.Dark)
        HUD?.textLabel.text = "Loading workouts...";
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
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
    
    func didReceiveUserInfo(notification: NSNotification) {
        createWorkoutsQuery()
        
//        dispatch_async(dispatch_get_main_queue()) { () -> Void in
//
//            if let userInfo = notification.userInfo {
//                if let startDate = userInfo["workoutStartDate"] as? NSDate {
//                    NSLog("\(startDate)")
//                    let workout = TDWorkout()
//                    workout.startDate = startDate
//                    if let endDate = userInfo["workoutEndDate"] as? NSDate {
//                        NSLog("\(endDate)")
//                        workout.endDate = endDate
//                    }
//                    
//                    if let score = userInfo["score"] as? [[Int]] {
//                        NSLog("\(score)")
//                        workout.score = score
//                    }
//                    
////                    self.workouts.append(workout)
//                    
//                    self.tableView.reloadData()
//
//                }
//                
//            }
//        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellId", forIndexPath: indexPath)
        cell.textLabel?.text = "\(workouts[indexPath.row].startDate)"
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showWorkoutId", sender: indexPath.row)
    }
    
    func createWorkoutsQuery() {
        let predicate = HKQuery.predicateForSamplesWithStartDate(nil, endDate: nil, options: .None)
        
        let workoutsQuery = HKAnchoredObjectQuery(type: HKObjectType.workoutType(), predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            if error == nil {
                if let workoutSamples = samples {
                    self.workouts = workoutSamples
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.HUD?.dismissAnimated(true)
                        self.tableView.reloadData()
                    }
                }
            }
        }

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.healthStore.executeQuery(workoutsQuery)
        }
    }
}

