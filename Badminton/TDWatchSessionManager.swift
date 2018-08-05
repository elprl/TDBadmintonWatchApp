//
//  TDWatchSessionManager.swift
//  Badminton
//
//  Created by Paul Leo on 05/08/2018.
//  Copyright © 2018 TapDigital Ltd. All rights reserved.
//

import Foundation
import WatchConnectivity

class TDWatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedManager = TDWatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith state: \(activationState.rawValue)")
        if let err = error {
            debugPrint(err)
        }
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
#endif

    var validSession: WCSession? {
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
#if os(iOS)
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
#elseif os(watchOS)
        return session
#endif
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension TDWatchSessionManager {
    
    // Sender
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // handle receiving application context
        print("didReceiveApplicationContext")
        DispatchQueue.main.async {
            // make sure to put on the main queue to update UI!
        }
    }
}

// MARK: User Info
// use when your app needs all the data
// FIFO queue
extension TDWatchSessionManager {
    
    // Sender
    func transferUserInfo(userInfo: [String : Any]) -> WCSessionUserInfoTransfer? {
        return validSession?.transferUserInfo(userInfo)
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
        print("didFinish userInfoTransfer")
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        // handle receiving user info
        print("didReceiveUserInfo")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didReceiveUserInfo"), object: nil, userInfo: userInfo)
    }
    
}

// MARK: Transfer File
extension TDWatchSessionManager {
    
    // Sender
    func transferFile(file: NSURL, metadata: [String : Any]) -> WCSessionFileTransfer? {
        return validSession?.transferFile(file as URL, metadata: metadata)
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        // handle filed transfer completion
    }
    
    // Receiver
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // handle receiving file
        DispatchQueue.main.async {
            // make sure to put on the main queue to update UI!
        }
    }
}


// MARK: Interactive Messaging
extension TDWatchSessionManager {
    
    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        if let session = validSession , session.isReachable {
            return session
        }
        return nil
    }
    
    // Sender
    func sendMessage(message: [String : Any],
                     replyHandler: (([String : Any]) -> Void)? = nil,
                     errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendMessageData(data: Data,
                         replyHandler: ((Data) -> Void)? = nil,
                         errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // handle receiving message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didReceiveUserInfo"), object: nil, userInfo: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // handle receiving message data
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didReceiveUserInfo"), object: nil, userInfo: nil)
    }
}
