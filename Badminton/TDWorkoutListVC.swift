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

func == (left: HKSample, right: HKSample) -> Bool {
    if left.startDate.compare(right.startDate) == ComparisonResult.orderedSame {
        return true
    }
    return false
}

class TDWorkoutListVC: UITableViewController {
    
//    var workouts: [TDWorkoutProtocol] = [TDWorkoutEntity]()
    var workouts: [HKSample] = [HKSample]()
    var HUD: JGProgressHUD?
    let speaker = TDSpeechManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(TDWorkoutListVC.didReceiveUserInfo), name:NSNotification.Name(rawValue: "didReceiveUserInfo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TDWorkoutListVC.didHandledAuthorization), name:NSNotification.Name(rawValue: "handledAuthorization"), object: nil)
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.dark)
        HUD?.show(in: self.view)
        HUD?.dismiss(afterDelay: 15.0)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destination = segue.destination as? TDShinobiGraphVC {
            if let index = sender as? Int {
                let startDate = workouts[index].startDate
                let endDate = workouts[index].endDate
                destination.startDate = startDate
                destination.endDate = endDate
            }
        } else if let destination = segue.destination as? TDGraphVC {
            if let index = sender as? Int {
                let startDate = workouts[index].startDate
                let endDate = workouts[index].endDate
                destination.plotFactory.startDate = startDate
                destination.plotFactory.endDate = endDate
            }
        }
    }

    // MARK: WCSessionDelegate
    
    @objc func didHandledAuthorization(notification: Notification) {
        DispatchQueue.main.async() {
            self.createWorkoutsQuery()
            
            self.HUD = JGProgressHUD(style: JGProgressHUDStyle.dark)
            self.HUD?.textLabel.text = "Loading workouts...";
            self.HUD?.show(in: self.view)
            self.HUD?.dismiss(afterDelay: 15.0)
        }
    }
    
    
    
    @objc func didReceiveUserInfo(notification: Notification) {
        if let _ = notification.userInfo?["workoutStarted"] as? Bool {
            if speaker.canSpeak() {
                DispatchQueue.main.async() {
                    self.speaker.speakMessage(message: "Workout started")
                }
            }
        }
        
        if let score = notification.userInfo?["score"] as? [[Int]] {
            if speaker.canSpeak() {
                DispatchQueue.main.async() {
                    self.speaker.speakScore(score: score)
                }
            }
        }
        
        guard let startDate = notification.userInfo?["workoutStartDate"] as? Date,
            let endDate = notification.userInfo?["workoutEndDate"] as? Date else { return }
        let workout = HKWorkout(activityType: .badminton, start: startDate, end: endDate)
        
//        self.workouts.insert(TDWorkoutEntity(workoutRecord: workout, samples: nil, scoreData: nil, isProcessing: true), at: 0)
        
        DispatchQueue.main.async() {
            if self.speaker.canSpeak() {
                self.speaker.speakMessage(message: "Workout ended")
            }
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        let workout = workouts[indexPath.row]
        let dateString = MHPrettyDate.prettyDate(from: workout.startDate, with: MHPrettyDateFormatWithTime)
//        if workout is TDWorkout {
//            cell.textLabel?.text = dateString! + " (Processing)"
//            cell.selectionStyle = .none
//            cell.accessoryType = .none
//        } else {
            cell.textLabel?.text = dateString
//            cell.selectionStyle = .gray
//            cell.accessoryType = .disclosureIndicator
//        }
        
        print(workout.metadata ?? "no metadata")
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showCPGraphWorkoutId", sender: indexPath.row)
//        performSegueWithIdentifier("showShinobiWorkoutId", sender: indexPath.row)
    }
    
    func createWorkoutsQuery() {
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: HKQueryOptions(rawValue: 0))
//        let sortDescriptor = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let workoutsQuery = HKAnchoredObjectQuery(type: HKObjectType.workoutType(), predicate: predicate,  anchor: nil, limit: Int(HKObjectQueryNoLimit)) { query, samples, deletedObjects, anchor, error in

            if error == nil {
                if let workoutSamples = samples {
                    self.workouts = workoutSamples.reversed()
                    DispatchQueue.main.async() {
                        self.HUD?.dismiss(animated: true)
                        self.tableView.reloadData()
                    }
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        workoutsQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            if error == nil {
                self.insertNewSamples(samples: samples)
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.healthStore.execute(workoutsQuery)
        }
    }
    
    func insertNewSamples(samples: [HKSample]?) {
        if let workoutSamples = samples {
            for workout in workoutSamples {
                let index = indexOfWorkout(myWorkout: workout)
                if index >= 0 {
                    self.workouts.remove(at: index)
                }
                self.workouts.insert(workout, at: 0)
            }
            DispatchQueue.main.async() {
                self.HUD?.dismiss(animated: true)
                self.tableView.reloadData()
            }
        }
    }
    
    func indexOfWorkout(myWorkout: HKSample) -> Int {
        for (index, value) in self.workouts.enumerated() {
            if value == myWorkout {
                return index
            }
        }
        
        return -1
    }
}


