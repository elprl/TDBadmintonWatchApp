//
//  TDWorkoutListView.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import UIKit
import Viperit
import JGProgressHUD
import MHPrettyDate

//MARK: TDWorkoutListView Class
open class TDWorkoutListView: UserInterface {
    @IBOutlet weak var tableView: UITableView!
    var HUD: JGProgressHUD?

    
    func displayHUD(with message: String) {
        HUD = JGProgressHUD(style: .dark)
        HUD?.textLabel.text = message
        HUD?.show(in: self.view)
        HUD?.dismiss(afterDelay: 15.0)
    }
}

//MARK: - UITableView Methods
extension TDWorkoutListView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.workouts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        let workout = presenter.workouts[indexPath.row]
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
    
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        performSegue(withIdentifier: "showCPGraphWorkoutId", sender: indexPath.row)
    }
}

//MARK: - TDWorkoutListView API
extension TDWorkoutListView: TDWorkoutListViewApi {

    
    func hideHUD() {
        self.HUD?.dismiss(animated: true)
    }
    
    func refreshView() {
        self.tableView.reloadData()
    }
    
}

// MARK: - TDWorkoutListView Viper Components API
private extension TDWorkoutListView {
    var presenter: TDWorkoutListPresenterApi {
        return _presenter as! TDWorkoutListPresenterApi
    }
    var displayData: TDWorkoutListDisplayData {
        return _displayData as! TDWorkoutListDisplayData
    }
}
