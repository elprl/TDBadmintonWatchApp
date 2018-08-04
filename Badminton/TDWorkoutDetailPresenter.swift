//
//  TDWorkoutDetailPresenter.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import Viperit

// MARK: - TDWorkoutDetailPresenter Class
final class TDWorkoutDetailPresenter: Presenter {
}

// MARK: - TDWorkoutDetailPresenter API
extension TDWorkoutDetailPresenter: TDWorkoutDetailPresenterApi {
}

// MARK: - TDWorkoutDetail Viper Components
private extension TDWorkoutDetailPresenter {
    var view: TDWorkoutDetailViewApi {
        return _view as! TDWorkoutDetailViewApi
    }
    var interactor: TDWorkoutDetailInteractorApi {
        return _interactor as! TDWorkoutDetailInteractorApi
    }
    var router: TDWorkoutDetailRouterApi {
        return _router as! TDWorkoutDetailRouterApi
    }
}
