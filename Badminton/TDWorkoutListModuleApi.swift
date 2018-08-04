//
//  TDWorkoutListModuleApi.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Viperit
import HealthKit

//MARK: - TDWorkoutListRouter API
protocol TDWorkoutListRouterApi: RouterProtocol {
}

//MARK: - TDWorkoutListView API
protocol TDWorkoutListViewApi: UserInterfaceProtocol {
    func displayHUD(with message: String)
    func hideHUD()
    func refreshView()
}

//MARK: - TDWorkoutListPresenter API
protocol TDWorkoutListPresenterApi: PresenterProtocol {
    var workouts: [HKSample] { get set }
    func didFinishLoadingData()
    func setWorkouts(with workouts: [HKSample])
    func insertNewSamples(samples: [HKSample]?)
    func didHandledAuthorization(notification: Notification)
    func didReceiveUserInfo(notification: Notification)
}

//MARK: - TDWorkoutListInteractor API
protocol TDWorkoutListInteractorApi: InteractorProtocol {
    func createWorkoutsQuery()
}
