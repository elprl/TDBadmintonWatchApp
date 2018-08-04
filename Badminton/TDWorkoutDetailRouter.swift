//
//  TDWorkoutDetailRouter.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import Viperit

// MARK: - TDWorkoutDetailRouter class
final class TDWorkoutDetailRouter: Router {
}

// MARK: - TDWorkoutDetailRouter API
extension TDWorkoutDetailRouter: TDWorkoutDetailRouterApi {
}

// MARK: - TDWorkoutDetail Viper Components
private extension TDWorkoutDetailRouter {
    var presenter: TDWorkoutDetailPresenterApi {
        return _presenter as! TDWorkoutDetailPresenterApi
    }
}
