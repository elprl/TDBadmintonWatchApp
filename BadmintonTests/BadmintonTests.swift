//
//  BadmintonTests.swift
//  BadmintonTests
//
//  Created by Paul Leo on 25/10/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import XCTest
@testable import Badminton
import Viperit
import Quick
import Nimble
import HealthKit

class TDWorkoutListMockView: UserInterface, TDWorkoutListViewApi {
    //TEST PROPERTIES
    var expectation: XCTestExpectation!
    var expectedMessage: String!
    
    func displayHUD(with message: String) {
        expect(message).to(equal(expectedMessage))
        expectation.fulfill()
    }
    
    func hideHUD() {
        //
    }
    
    func refreshView() {
        //
    }
}

class TDWorkoutListMockView2: TDWorkoutListView {
    //TEST PROPERTIES
    var expectedMessage: String!
    
    override func displayHUD(with message: String) {
        super.displayHUD(with: message)
        expect(message).to(equal(expectedMessage))
    }
}



class TDWorkoutListViewSpec: QuickSpec {
    override func spec() {
        var view: TDWorkoutListMockView2!
        var presenter: TDWorkoutListPresenter!
        
        beforeEach {
            var mod = AppModules.tDWorkoutList.build()
            view = TDWorkoutListMockView2()
            presenter = (mod.presenter as! TDWorkoutListPresenter)
            mod.injectMock(view: view)
        }
        
        describe(".viewDidLoad()") {
            beforeEach {
                // Method #1: Access the view to trigger viewDidLoad().
//                view.expectation = QuickSpec.current.expectation(description: "Test expectation description")
                view.expectedMessage = "Awaiting Authorisation..."
//                view.expectation.expectedFulfillmentCount = 2
                let _ =  view.view
            }
            
            context("when the view loads for the first time and the user hasn't authorised") {
                it("shows awaiting authorisation hud text") {
                    view.expectedMessage = "Awaiting Authorisation..."
//                    QuickSpec.current.waitForExpectations(timeout: 5)
                }
            }
            
            context("when the view loads for the first time and the user has authorised") {
                it("shows loading workouts hud text") {
                    view.expectedMessage = "Loading workouts..."
                    presenter.didHandledAuthorization(notification: Notification(name: Notification.Name("test")))
//                    QuickSpec.current.waitForExpectations(timeout: 5)
                }
            }
        }
        
       
    }
}


class TDWorkoutListMockPresenter: Presenter, TDWorkoutListPresenterApi {
    var workouts: [HKSample] = [
        HKWorkout(activityType: .badminton, start: Date(), end: Date()),
        HKWorkout(activityType: .badminton, start: Date(), end: Date()),
        HKWorkout(activityType: .badminton, start: Date(), end: Date())
    ]
    
    func didFinishLoadingData() {
        //
    }
    
    func setWorkouts(with workouts: [HKSample]) {
        //
    }
    
    func insertNewSamples(samples: [HKSample]?) {
        //
    }
    
    func didHandledAuthorization(notification: Notification) {
        //
    }
    
    func didReceiveUserInfo(notification: Notification) {
        //
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        //
    }
}

class TDWorkoutListPresenterSpec: QuickSpec {
    override func spec() {
        var view: TDWorkoutListView!
        var presenter: TDWorkoutListMockPresenter!
        
        beforeEach {
            var mod = AppModules.tDWorkoutList.build()
            view = (mod.view as! TDWorkoutListView)
            presenter = TDWorkoutListMockPresenter()
            mod.injectMock(presenter: presenter)
        }
        
        describe("TDWorkoutListPresenterSpec") {
            beforeEach {
                let _ =  view.view
            }
            
            context("when the tableview is loaded") {
                it("should have 3 rows") {
                    expect(view.tableView.numberOfRows(inSection: 0)).to(equal(3))
                }
            }
           
        }
        
        
    }
}
