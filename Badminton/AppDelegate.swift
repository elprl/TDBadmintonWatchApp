//
//  AppDelegate.swift
//  Badminton
//
//  Created by Paul Leo on 25/10/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity
import AVFoundation
import Viperit

//MARK: - VIPER Application modules
enum AppModules: String, ViperitModule {
    case tDWorkoutList
    case tDWorkoutDetail
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let healthStore = HKHealthStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set up and activate your session early here!
        TDWatchSessionManager.sharedManager.startSession()
        
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)
            try avSession.setActive(true)
        } catch {
            
        }        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let module = AppModules.tDWorkoutList.build()
        module.router.show(inWindow: window, embedInNavController: true)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}


// MARK: -- Healthkit authorization from watch
extension AppDelegate {
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        self.healthStore.handleAuthorizationForExtension { success, _ in
            if success {
                NotificationCenter.default.post(name: NSNotification.Name("handledAuthorization"), object: nil)
            }
        }
    }
    
    func isAuthorized() -> Bool {
        let status = self.healthStore.authorizationStatus(for: HKObjectType.workoutType())
        if status == .sharingAuthorized {
            return true
        }
        
        return false
    }
}

