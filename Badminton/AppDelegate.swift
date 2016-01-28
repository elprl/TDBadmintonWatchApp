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
import NSLogger


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    let healthStore = HKHealthStore()
    var session: WCSession!


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        #if TD_DEBUG
            LoggerStart(LoggerGetDefaultLogger())
        #endif
        
        session = WCSession.defaultSession()
        session.delegate = self
        
        if WCSession.isSupported() {
            session.activateSession()
        }
        
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DefaultToSpeaker)
            try avSession.setActive(true)
        } catch {
            
        }
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // authorization from watch
    func applicationShouldRequestHealthAuthorization(application: UIApplication) {        
        self.healthStore.handleAuthorizationForExtensionWithCompletion { success, error in
            if success {
                NSNotificationCenter.defaultCenter().postNotificationName("handledAuthorization", object:nil, userInfo: nil)
            }
        }
    }
    
    // MARK: WCSessionDelegate
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("didReceiveUserInfo in AppDelegate")
        NSNotificationCenter.defaultCenter().postNotificationName("didReceiveUserInfo", object:nil, userInfo: userInfo)
    }

    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("didReceiveApplicationContext in AppDelegate")
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("didReceiveMessage handler in AppDelegate")
        NSNotificationCenter.defaultCenter().postNotificationName("didReceiveUserInfo", object:nil, userInfo: message)

    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        print("didReceiveMessage in AppDelegate")
        NSNotificationCenter.defaultCenter().postNotificationName("didReceiveUserInfo", object:nil, userInfo: message)

    }
    
    func isAuthorized() -> Bool {
        let status = self.healthStore.authorizationStatusForType(HKObjectType.workoutType())
        if status == .SharingAuthorized {
            return true
        }
        
        return false
    }
}

