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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    let healthStore = HKHealthStore()
    var session: WCSession!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        session = WCSession.default
        session.delegate = self
        
        if WCSession.isSupported() {
            session.activate()
        }
        
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)
            try avSession.setActive(true)
        } catch {
            
        }
        
        
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
    
    // authorization from watch
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        self.healthStore.handleAuthorizationForExtension { success, _ in
            if success {
//                NotificationCenter.default.post(name: NSNotification.Name("handledAuthorization"), object: nil)
            }
        }
    }
    
    // MARK: WCSessionDelegate
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith in AppDelegate")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("didReceiveUserInfo in AppDelegate")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didReceiveUserInfo"), object:nil, userInfo: userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("didReceiveApplicationContext in AppDelegate")
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        print("didReceiveMessage handler in AppDelegate")
        let decoder = NSKeyedUnarchiver(forReadingWith: messageData)
        defer {
            decoder.finishDecoding()
        }
        
        let type = decoder.decodeObject(forKey: "type") as! String
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didReceiveUserInfo"), object:nil, userInfo: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("didReceiveMessage in AppDelegate")
        let decoder = NSKeyedUnarchiver(forReadingWith: messageData)
        defer {
            decoder.finishDecoding()
        }
        
        let type = decoder.decodeObject(forKey: "type") as! String
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didReceiveUserInfo"), object:nil, userInfo: nil)
    }
    
    func isAuthorized() -> Bool {
        let status = self.healthStore.authorizationStatus(for: HKObjectType.workoutType())
        if status == .sharingAuthorized {
            return true
        }
        
        return false
    }
}

