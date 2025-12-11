import Foundation

enum ForegroundServiceMethod: String {
  case start = "start"
  case startSessionEarly = "startSessionEarly"
  case broadcastUserAdvanceFromPrelude = "broadcastUserAdvanceFromPrelude"
  case resume = "resume"
  case pause = "pause"
  case dispose = "dispose"

  func serialize() -> String? {
    let payload: [String: String] = ["type": rawValue]
    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
}
