//
//  TDWorkoutDetailView.swift
//  Badminton
//
//  Created by Paul Leo on 04/08/2018.
//Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import UIKit
import Viperit

//MARK: TDWorkoutDetailView Class
final class TDWorkoutDetailView: UserInterface {
}

//MARK: - TDWorkoutDetailView API
extension TDWorkoutDetailView: TDWorkoutDetailViewApi {
}

// MARK: - TDWorkoutDetailView Viper Components API
private extension TDWorkoutDetailView {
    var presenter: TDWorkoutDetailPresenterApi {
        return _presenter as! TDWorkoutDetailPresenterApi
    }
    var displayData: TDWorkoutDetailDisplayData {
        return _displayData as! TDWorkoutDetailDisplayData
    }
}
