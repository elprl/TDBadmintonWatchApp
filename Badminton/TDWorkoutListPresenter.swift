//
//  TDWorkoutListPresenter.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import Viperit
import HealthKit
import WatchConnectivity

// MARK: - TDWorkoutListPresenter Class
final class TDWorkoutListPresenter: Presenter {
    var workouts: [HKSample] = [HKSample]()
    let speaker = TDSpeechManager()
    
    override func viewHasLoaded() {
        super.viewHasLoaded()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TDWorkoutListPresenter.didReceiveUserInfo), name:NSNotification.Name(rawValue: "didReceiveUserInfo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TDWorkoutListPresenter.didHandledAuthorization), name:NSNotification.Name(rawValue: "handledAuthorization"), object: nil)
        
        if TDHealthKitSessionManager.sharedManager.isAuthorized() {
            interactor?.createWorkoutsQuery()
            view?.displayHUD(with: "Loading workouts...")
        } else {
            view?.displayHUD(with: "Awaiting Authorisation...")
        }
    }
}

// MARK: - TDWorkoutListPresenter API
extension TDWorkoutListPresenter: TDWorkoutListPresenterApi {
    
    func didSelectRow(at indexPath: IndexPath) {
        //performSegue(withIdentifier: "showCPGraphWorkoutId", sender: indexPath.row)
    }
    
    func didFinishLoadingData() {
        view?.hideHUD()
        view?.refreshView()
    }
    
    func setWorkouts(with workouts: [HKSample]) {
        self.workouts = workouts
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
            DispatchQueue.main.async() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.didFinishLoadingData()
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
    
    @objc func didHandledAuthorization(notification: Notification) {
        DispatchQueue.main.async() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.interactor?.createWorkoutsQuery()
            strongSelf.view?.displayHUD(with: "Loading workouts...")
        }
    }
    
    @objc func didReceiveUserInfo(notification: Notification) {
        if let _ = notification.userInfo?["workoutStarted"] as? Bool {
            if speaker.canSpeak() {
                DispatchQueue.main.async() { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.speaker.speakMessage(message: "Workout started")
                }
            }
        }
        
        if let score = notification.userInfo?["score"] as? [[Int]] {
            if speaker.canSpeak() {
                DispatchQueue.main.async() { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.speaker.speakScore(score: score)
                }
            }
        }
        
        guard let startDate = notification.userInfo?["workoutStartDate"] as? Date,
            let endDate = notification.userInfo?["workoutEndDate"] as? Date else { return }
        let workout = HKWorkout(activityType: .badminton, start: startDate, end: endDate)
        
        self.workouts.insert(workout, at: 0)
        
        DispatchQueue.main.async() { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.speaker.canSpeak() {
                strongSelf.speaker.speakMessage(message: "Workout ended")
            }
            strongSelf.didFinishLoadingData()
        }
    }
}

// MARK: - TDWorkoutList Viper Components
private extension TDWorkoutListPresenter {
    var view: TDWorkoutListViewApi? {
        return _view as? TDWorkoutListViewApi
    }
    var interactor: TDWorkoutListInteractorApi? {
        return _interactor as? TDWorkoutListInteractorApi
    }
    var router: TDWorkoutListRouterApi? {
        return _router as? TDWorkoutListRouterApi
    }
}
