//
//  TDSpeechManager.swift
//  Badminton
//
//  Created by Paul Leo on 09/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import Foundation
import AVFoundation

class TDSpeechManager {
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var langCodes : [String]?
    var voice : AVSpeechSynthesisVoice?

    init() {
        self.langCodes = AVSpeechSynthesisVoice.speechVoices().map {($0 as AVSpeechSynthesisVoice).language }
        
//        for voice in AVSpeechSynthesisVoice.speechVoices() {
//            let voiceLanguageCode = (voice as AVSpeechSynthesisVoice).language
//            
//            guard let languageName = NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: voiceLanguageCode) else {return}
//            
//            let dictionary = ["languageName": languageName, "languageCode": voiceLanguageCode]
//            print(dictionary)
//            
//            arrVoiceLanguages.append(dictionary)
//        }
        if canSpeak() {
            self.voice = AVSpeechSynthesisVoice(language: getPreferredLanguage())
        }
        
    }

    func canSpeak() -> Bool {
        if let codes = langCodes where codes.contains(getPreferredLanguage()) {
            return true
        }
        
        return false
    }
    
    func getPreferredLanguage() -> String {
        if let prefLanguage = NSLocale.preferredLanguages().first {
            return prefLanguage
        }
        
        return "en-GB"
    }
    
    func speakMessage(message: String) {
        if speechSynthesizer.speaking {
            stopSpeech()
        } 
        
        let speechUtterance = AVSpeechUtterance(string: message)
//        speechUtterance.postUtteranceDelay = 0.005
        speechUtterance.voice = self.voice
        speechSynthesizer.speakUtterance(speechUtterance)
    }
    
    func speakScore(score: [[Int]]) {
        var mySetScore = 0
        var themSetScore = 0
        if score.count == 1 {
            mySetScore = score[0][0]
            themSetScore = score[0][1]
        } else if score.count == 2 {
            mySetScore = score[1][0]
            themSetScore = score[1][1]
        } else {
            mySetScore = score[2][0]
            themSetScore = score[2][1]
        }
        var scoreString = "\(mySetScore) \(themSetScore)"
        
        if mySetScore > themSetScore {
            let difference = mySetScore - themSetScore
            if (mySetScore >= 21 && difference > 1) || mySetScore == 30 { // won set
                if score.count == 1 || (score.count == 2 && score[0][0] < score[0][1]) {
                    scoreString = "Game, \(mySetScore) \(themSetScore)" // won set
                } else if score.count == 2 {
                    scoreString = "Game and Match, \(score[0][0]) \(score[0][1]), \(mySetScore) \(themSetScore)"
                } else {
                    scoreString = "Game and Match, \(score[0][0]) \(score[0][1]), \(score[1][0]) \(score[1][1]), \(mySetScore) \(themSetScore)"
                }
            }
        } else {
            let difference = themSetScore - mySetScore
            if (themSetScore >= 21 && difference > 1) || themSetScore == 30 { // won
                if score.count == 1 || (score.count == 2 && score[0][1] < score[0][0]) {
                    scoreString = "Game \(mySetScore) \(themSetScore)" // won set
                } else if score.count == 2 {
                    scoreString = "Game and Match, \(score[0][0]) \(score[0][1]), \(mySetScore) \(themSetScore)"
                } else {
                    scoreString = "Game and Match, \(score[0][0]) \(score[0][1]), \(score[1][0]) \(score[1][1]), \(mySetScore) \(themSetScore)"
                }
            }
        }
        
        scoreString = scoreString.stringByReplacingOccurrencesOfString(" 0", withString: " love")
        
        speakMessage(scoreString)
        
//        switch (score.count, mySetScore, themSetScore) {
//        case (_, 0...30, 0...30):
//            scoreString = "\(mySetScore) \(themSetScore)"
//        case (2, 21, 0...19) where score[0][0] < score[0][1]:
//            scoreString = "Game \(mySetScore) \(themSetScore)"
//        case (2, 21, 0...19) where score[0][0] > score[0][1]:
//            scoreString = "Game and Match \(score[0][0]) \(score[0][1]) \(mySetScore) \(themSetScore)"
//        case (2, 0...19, 21) where score[0][0] > score[0][1]:
//            scoreString = "Game \(mySetScore) \(themSetScore)"
//        case (2, 0...19, 21) where score[0][0] < score[0][1]:
//            scoreString = "Game and Match \(score[0][0]) \(score[0][1]) \(mySetScore) \(themSetScore)"
//        case (3, 21, 0...19):
//            scoreString = "Game and Match \(score[0][0]) \(score[0][1]) \(score[1][0]) \(score[1][1]) \(mySetScore) \(themSetScore)"
//        case (3, 0...19, 21):
//            scoreString = "Game and Match \(score[0][0]) \(score[0][1]) \(score[1][0]) \(score[1][1]) \(mySetScore) \(themSetScore)"
//        default:
//            break
//        }
    }
    
    // workaround for stopping speach issue
    func stopSpeech() {
        if speechSynthesizer.speaking {
            speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
            let speechUtterance = AVSpeechUtterance(string: "")
            speechSynthesizer.speakUtterance(speechUtterance)
            speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
        }
    }
   
}