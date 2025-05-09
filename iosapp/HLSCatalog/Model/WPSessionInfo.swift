/*
See LICENSE folder for this sample's licensing information.

*/

import Foundation
import SwiftyJSON

struct TimelineItem: Codable {
    var sessionId: String
    var dspOffset: UInt64
}

extension TimelineItem {
    init(json: JSON) {
        self.sessionId = json["sessionId"].stringValue
        self.dspOffset = json["dspOffset"].uInt64Value
    }
}

struct BroadcastPersistentState {
    var startSessionTimersTimestamp: UInt64?
    var timeline: Array<TimelineItem>
    var discarded: Array<TimelineItem>
}

extension BroadcastPersistentState: Codable {
    init(json: JSON) {
        self.startSessionTimersTimestamp = json["startSessionTimersTimestamp"].uInt64
        self.timeline = json["timeline"].map({index, json in
            return TimelineItem(json: json)
        })
        //TODO
        self.discarded = Array<TimelineItem>()
    }
}

enum SessionRenderType: String, Codable {
    case realTime = "realTime"
    case preRendered = "preRendered"
    case predictiveComposed = "predictiveComposed"
}

struct WPSession : Codable {
    var id: String
    var renderType: SessionRenderType
    var score: SessionScore
    var variableInputs: VariableInputs
    var canClientStartEarly: Bool
    var broadcastState: BroadcastPersistentState?
    var duration: UInt64
    var endTime: UInt64?
}

extension WPSession {
    init(json: JSON, duration: UInt64, endTime: UInt64?) {
        self.id = json["id"].stringValue
        self.renderType = SessionRenderType(rawValue: json["renderType"].stringValue) ?? .predictiveComposed
        self.score = SessionScore(json: json["score"])
        self.variableInputs = VariableInputs(json: json["variableInputs"])
        self.canClientStartEarly = json["canClientStartEarly"].boolValue
        self.broadcastState = BroadcastPersistentState(json: json["broadcastState"])
        self.duration = duration
        self.endTime = endTime
    }
    
    @MainActor
    static func fetch(sessionInfo: WPSessionInfo) async -> WPSession? {
        do {
            let freudBaseUrl = FreudUtils.getFreudBaseUrl(env: sessionInfo.freudEnv)
            let sessionInfoUrl = URL(string: "\(freudBaseUrl)/sessions/my/\(sessionInfo.broadcastIdentifier)")!
            var request = URLRequest(url: sessionInfoUrl)
            let anonymousToken = ConfigurationManager.singleton.anonymousId
            request.setValue("anonymous \(anonymousToken)", forHTTPHeaderField: "Authorization")
            
            let (dataWebsiteSession, _) = try await URLSession.shared.data(for: request)

            let websiteSessionJSONResult: NSDictionary = try JSONSerialization.jsonObject(with: dataWebsiteSession, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            print("websiteSessionJSONResult:")
            print(websiteSessionJSONResult)
                        
            guard let sessionId = websiteSessionJSONResult["id"] as? String else {  
                print("Failed to get session id")
                return nil
            }
            let sessionDuration = UInt64(websiteSessionJSONResult["duration"] as? NSNumber ?? 0)
            print("sessionDuration: \(sessionDuration)")
            let sessionEndTime = websiteSessionJSONResult["endTime"] as? NSNumber != nil ? UInt64(websiteSessionJSONResult["endTime"] as! NSNumber) : nil
            
            let sessionUrl = URL(string: "\(freudBaseUrl)/sessions/\(sessionId)")!
            var sessionRequest = URLRequest(url: sessionUrl)
            sessionRequest.setValue("anonymous \(anonymousToken)", forHTTPHeaderField: "Authorization")
            let (dataSession, _) = try await URLSession.shared.data(for: sessionRequest)

            let sessionJSONResult = JSON(dataSession)
            let session = WPSession(json: sessionJSONResult, duration: sessionDuration, endTime: sessionEndTime)
            print("session:")
            dump(session)
                                            
            return session
        } catch {
            print("Failed to fetch website session \(error)")
            return nil
        }
    }
}

class WPSessionInfo: Codable {
    
    // MARK: Types
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case playlistURL = "playlist_url"
        case broadcastIdentifier = "broadcastIdentifier"
        case freudEnv = "freudEnv"
        case freeVOPlayback = "freeVOPlayback"

    }
    
    // MARK: Properties
    
    /// The name of the stream.
    let name: String
    
    /// The URL pointing to the HLS stream.
    let playlistURL: String
    
    let broadcastIdentifier: String
    
    let freudEnv: String
    let freeVOPlayback: Bool

    init(name: String, playlistUrl: String, broadcastIdentifier: String, freudEnv: String, freeVOPlayback: Bool) {
        self.name = name
        self.playlistURL = playlistUrl
        self.broadcastIdentifier = broadcastIdentifier
        self.freudEnv = freudEnv
        self.freeVOPlayback = freeVOPlayback
    }
}

extension WPSessionInfo: Equatable {
    static func ==(lhs: WPSessionInfo, rhs: WPSessionInfo) -> Bool {
        return (lhs.name == rhs.name) && (lhs.playlistURL == rhs.playlistURL)
    }
}
