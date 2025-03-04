import UIKit
import SwiftyJSON
import Combine

import SocketIO


struct IncomingMessage<T> {
    var event: String
    var data: T
}

enum SessionEventType: String, Codable {
    case reviseSessionPlan
}
struct VoiceoverStageTiming: Codable {
    var from: UInt64
    var to: UInt64
}

extension VoiceoverStageTiming {
    init(json: JSON) {
        self.from = json["from"].uInt64Value
        self.to = json["to"].uInt64Value
    }
}

struct VoiceoverStage : Codable {
    var stage: String
    var timing: VoiceoverStageTiming
    var volume: Float
    var musicGain: Float
    var duration: UInt64
    var fileNameWithoutExtension: String
    var description: String
    var custom_voiceover_id: String
}

extension VoiceoverStage {
    init(json: JSON) {
        self.stage = json["stage"].stringValue
        self.timing = VoiceoverStageTiming(json: json["timing"])
        self.volume = json["volume"].floatValue
        self.musicGain = json["musicGain"].floatValue
        self.duration = json["duration"].uInt64Value
        self.fileNameWithoutExtension = json["fileNameWithoutExtension"].stringValue
        self.description = json["description"].stringValue
        self.custom_voiceover_id = json["custom_voiceover_id"].stringValue
    }
}

struct SessionScore: Codable {
    var voiceover: Array<VoiceoverStage>?
    var name: String?
}

extension SessionScore {
    init(json: JSON) {
        self.voiceover = json["voiceover"].map({ index, json in
            return VoiceoverStage(json: json)
        })
        self.name = json["name"].stringValue
    }
}

struct VariableInputs: Codable {
    var name: String?
}

extension VariableInputs {
    init(json: JSON) {
        self.name = json["name"].stringValue
    }
}

struct ReviseSessionPlanEvent : Codable {

    var timestamp: UInt64
    
    var dspTimeMs: UInt64
    
    var event: SessionEventType
    
    var revisedScore: SessionScore
}

extension ReviseSessionPlanEvent {
    init(json: JSON) {
        self.timestamp = json["timestamp"].uInt64Value
        self.dspTimeMs = json["dspTimeMs"].uInt64Value
        self.event = .reviseSessionPlan
        self.revisedScore = SessionScore(json: json["revisedScore"])
    }
}

protocol TimestampedSessionEventBase: Codable {
    var timestamp: UInt64 { get set }
    var dspTimeMs: UInt64 { get set }
    var event: SessionEventType { get set }
}

struct InboundSessionEvent {
    var index: UInt64
    var event: ReviseSessionPlanEvent
    var sessionId: String
}

extension InboundSessionEvent: Codable {
    init(json: JSON) {
        self.index = json["index"].uInt64Value
        self.sessionId = json["sessionId"].stringValue
        self.event = ReviseSessionPlanEvent(json: json["event"])
    }
}

enum WPSessionState: String, Codable {
    case planned, prelude, mainPhase, postlude, ended, pause
}

struct WPTick {
    var sessionState: WPSessionState
    var timeUntilStart: UInt64
    var absoluteTime: UInt64
    var effectiveTime: UInt64
    var timeSinceInit: UInt64
    var sessionDuration: UInt64
}

extension WPTick: Codable {
    init(dictionary: [String: Any]) throws {

        //doesnt work on large INTs????
        //let decoder = JSONDecoder()
        //self = try decoder.decode(WPTick.self, from: JSONSerialization.data(withJSONObject: dictionary))
        self.sessionState = WPSessionState(rawValue: dictionary["sessionState"] as! String)!
        self.absoluteTime = UInt64(dictionary["absoluteTime"] as! NSNumber)
        self.timeUntilStart = UInt64(dictionary["timeUntilStart"] as! NSNumber)
        self.effectiveTime = UInt64(dictionary["effectiveTime"] as! NSNumber)
        self.timeSinceInit = UInt64(dictionary["timeSinceInit"] as! NSNumber)
        self.sessionDuration = UInt64(dictionary["sessionDuration"] as! NSNumber)
    }

}

struct SetUserEmitMessage {
    var type: String
    var anonymousToken: String
}

protocol FreudConnection {
    var broadcastStatePublisher: AnyPublisher<IncomingMessage<BroadcastPersistentState>, Never> { get }
    var inboundSessionEventPublisher: AnyPublisher<IncomingMessage<InboundSessionEvent>, Never> { get }
    var tickPublisher: AnyPublisher<IncomingMessage<WPTick>, Never> { get }
    
    func connect()
    func disconnect()
    func startSessionEarly()
    func broadcastUserAdvanceFromPrelude()
    func pause()
    func resume()
}

class FreudConnectionOnline: NSObject, URLSessionWebSocketDelegate, FreudConnection {
    
    private let broadcastStateEmitter = PassthroughSubject<IncomingMessage<BroadcastPersistentState>, Never>()
    lazy var broadcastStatePublisher = broadcastStateEmitter.eraseToAnyPublisher()
    
    private let inboundSessionEventEmitter = PassthroughSubject<IncomingMessage<InboundSessionEvent>, Never>()
    lazy var inboundSessionEventPublisher = inboundSessionEventEmitter.eraseToAnyPublisher()
    
    private let tickEmitter = PassthroughSubject<IncomingMessage<WPTick>, Never>()
    lazy var tickPublisher = tickEmitter.eraseToAnyPublisher()
    
    
    var socket: SocketIOClient?
    var socketManager: SocketManager?
    let broadcastIdentifier: String
    let freudEnv: String
    let sessionId: String

    init(broadcastIdentifier: String, freudEnv: String, sessionId: String) {
        print("Online FreudConnection")

        self.broadcastIdentifier = broadcastIdentifier
        self.freudEnv = freudEnv
        self.sessionId = sessionId

        super.init()
        print("Init FreudConnection instance")
    }
    
    
    func connect () {
        print("initWebsocketConnection")
        
        let url = URL(string:  "\(FreudUtils.getFreudBaseUrl(env: freudEnv))/broadcastMetadata/\(broadcastIdentifier)")!

        self.socketManager = SocketManager(socketURL: url, config: [
            //.extraHeaders(socketOptions),
            .log(false), .version(.two), //.forceNew(true), //.forceWebsockets(true),
            .reconnects(true), .reconnectWait(1), .reconnectWaitMax(10), .reconnectAttempts(10000)])

        self.socket = socketManager!.socket(forNamespace: "/broadcastMetadata/\(broadcastIdentifier)")
        self.socket!.on(clientEvent: .error) { data, ack in
            print("Error : \(data.description) \(data.debugDescription)")
            if data.first as? String == "Invalid namespace" {
                print("Reconnecting in 3s in hope that will be valid after start...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    print("Reconnecting now...")
                    self.socket?.connect()
                }
            }
        }
        self.socket!.on(clientEvent: .ping) { data, ack in
//            print("Ping")
//            print(data)
        }
        self.socket!.on(clientEvent: .pong) { data, ack in
//            print("Pong")
//            print(data)
        }

        self.socket!.onAny { (data) in
                    if data.event == "reconnectAttempt" {
                        print("Reconnecting manager")
                        self.socketManager?.disconnect()
                        self.socket?.connect()
                    }
                }

        self.socket!.on(clientEvent: .connect) { data, ack in
            print("Socket connected with id: \(ConfigurationManager.singleton.anonymousId)")
            self.socket?.emit("setUser", ["type": "anonymous", "anonymousToken": ConfigurationManager.singleton.anonymousId])
        }
        
        self.socket!.on("broadcastStateUpdate", callback: { data, ack in
            //print("broadcastStateUpdate")
            //dump(data)
            let incomingMessage = IncomingMessage(event: "broadcastStateUpdate", data: BroadcastPersistentState(json: JSON(data[0])))
            self.broadcastStateEmitter.send(incomingMessage)
        })
        
        self.socket!.on("sessionEvent", callback: { data, ack in
            //print("sessionEvent")
            //dump(data)
            let jsonResponse = JSON(data[0])
            let incomingMessage = IncomingMessage(event: "sessionEvent", data: InboundSessionEvent(json: jsonResponse))
            //dump(incomingMessage)
            self.inboundSessionEventEmitter.send(incomingMessage)
        })
        
        
        
        self.socket!.on("tick", callback: { data, ack in
//            print("tick")
//            print(data)
            do {
                let incomingMessage = IncomingMessage<WPTick>(event: "tick", data: try WPTick(dictionary: data.first as! [String: Any]))
                self.tickEmitter.send(incomingMessage)
            } catch {
                print("Error parsing tick: \(error) data: \(data.first)")
                dump(data.first)
            }
        })
        
        print("Connecting to SocketIO")
        self.socket!.connect()
    }
    
    deinit {
        print("deinit")
        disconnect()
    }
    
    func disconnect() {
        print("Disconnecting")
        socket?.disconnect()
        socket = nil
        socketManager?.disconnect()
        socketManager = nil
    }
    
    func startSessionEarly() {
        print("startSessionEarly...")
        let sessionInfoUrl = URL(string: "\(FreudUtils.getFreudBaseUrl(env: freudEnv))/sessions/my/\(self.sessionId)")!
        var request = URLRequest(url: sessionInfoUrl)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let anonymousToken = ConfigurationManager.singleton.anonymousId ?? ""
        request.setValue("anonymous \(anonymousToken)", forHTTPHeaderField: "Authorization")
        
        let json: [String: Any] = ["scheduledStart": 1]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let workItem = URLSession.shared.dataTask(with: request)
        
        workItem.resume()
    }
    
    func broadcastUserAdvanceFromPrelude() {
        let workItem = DispatchWorkItem{
            print("broadcastUserAdvanceFromPrelude...")

            self.socket?.emit("broadcastUserAdvanceFromPrelude")
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    
    func pause(){
        let workItem = DispatchWorkItem{
            print("Pausing...")
            self.socket?.emit("controlRequest", ["type": "pause"])
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    
    func resume(){
        let workItem = DispatchWorkItem{
            print("Resuming...")
            self.socket?.emit("controlRequest", ["type": "resume"])
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    

}


class FreudConnectionOffline: FreudConnection {
    private let session: WPSession
    private let broadcastStateSubject = PassthroughSubject<IncomingMessage<BroadcastPersistentState>, Never>()
    private let tickSubject = PassthroughSubject<IncomingMessage<WPTick>, Never>()
    private var tickTimer: Timer?
    
    private enum PlaybackState {
        case paused(accumulatedTime: UInt64)
        case playing(accumulatedTime: UInt64, startedAt: Date)
        case ended
        
        var sessionState: WPSessionState {
            switch self {
            case .paused: return .pause
            case .playing: return .mainPhase
            case .ended: return .ended
            }
        }
        
        func getCurrentTime(sessionDuration: UInt64) -> UInt64 {
            switch self {
            case .paused(let accumulatedTime):
                return accumulatedTime
            case .playing(let accumulatedTime, let startedAt):
                let timeSinceTransition = UInt64(-startedAt.timeIntervalSinceNow * 1000)
                return accumulatedTime + timeSinceTransition
            case .ended:
                return sessionDuration
            }
        }
    }
    
    private var playbackState: PlaybackState = .paused(accumulatedTime: 0)
    
    var broadcastStatePublisher: AnyPublisher<IncomingMessage<BroadcastPersistentState>, Never> {
        return broadcastStateSubject.eraseToAnyPublisher()
    }
    
    var inboundSessionEventPublisher: AnyPublisher<IncomingMessage<InboundSessionEvent>, Never> {
        return Empty().eraseToAnyPublisher()
    }
    
    var tickPublisher: AnyPublisher<IncomingMessage<WPTick>, Never> {
        return tickSubject.eraseToAnyPublisher()
    }
    
    init(session: WPSession) {
        print("Offline FreudConnection")
        self.session = session
    }
    
    func connect() {
        if let broadcastState = session.broadcastState {
            let stateToSend: BroadcastPersistentState
            if broadcastState.timeline.isEmpty {
                stateToSend = BroadcastPersistentState(
                    startSessionTimersTimestamp: broadcastState.startSessionTimersTimestamp,
                    timeline: [TimelineItem(
                      sessionId: session.id,
                      dspOffset: 0,
                      broadcastOffset: 0
                    )],
                    discarded: broadcastState.discarded
                )
            } else {
                stateToSend = broadcastState
            }
            let message = IncomingMessage(event: "broadcastStateUpdate", data: stateToSend)
            broadcastStateSubject.send(message)
        }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    func disconnect() {
        tickTimer?.invalidate()
        tickTimer = nil
    }
    
    private func tick() {
        let currentTime = playbackState.getCurrentTime(sessionDuration: session.duration)
        
        if currentTime >= session.duration && playbackState.sessionState != .ended {
            playbackState = .ended
        }
        
        let tick = WPTick(
            sessionState: playbackState.sessionState,
            timeUntilStart: currentTime,
            absoluteTime: currentTime,
            effectiveTime: currentTime,
            timeSinceInit: currentTime,
            sessionDuration: session.duration
        )
        
        tickSubject.send(IncomingMessage(event: "tick", data: tick))
    }
    
    func startSessionEarly() {
    }
    
    func broadcastUserAdvanceFromPrelude() {
    }
    
    func pause() {
        if case .playing = playbackState {
            let currentTime = playbackState.getCurrentTime(sessionDuration: session.duration)
            playbackState = .paused(accumulatedTime: currentTime)
        }
    }
    
    func resume() {
        if case .paused(let accumulatedTime) = playbackState {
            playbackState = .playing(accumulatedTime: accumulatedTime, startedAt: Date())
        }
    }
}
