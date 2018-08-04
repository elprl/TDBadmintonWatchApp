//
//  TDWorkoutListRouter.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import Viperit

// MARK: - TDWorkoutListRouter class
final class TDWorkoutListRouter: Router {
}

// MARK: - TDWorkoutListRouter API
extension TDWorkoutListRouter: TDWorkoutListRouterApi {
}

// MARK: - TDWorkoutList Viper Components
private extension TDWorkoutListRouter {
    var presenter: TDWorkoutListPresenterApi {
        return _presenter as! TDWorkoutListPresenterApi
    }
}
