//
//  TDWorkoutDetailInteractor.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import Viperit

// MARK: - TDWorkoutDetailInteractor Class
final class TDWorkoutDetailInteractor: Interactor {
}

// MARK: - TDWorkoutDetailInteractor API
extension TDWorkoutDetailInteractor: TDWorkoutDetailInteractorApi {
}

// MARK: - Interactor Viper Components Api
private extension TDWorkoutDetailInteractor {
    var presenter: TDWorkoutDetailPresenterApi {
        return _presenter as! TDWorkoutDetailPresenterApi
    }
}
