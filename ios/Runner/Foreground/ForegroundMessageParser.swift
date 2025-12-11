import Foundation

struct ForegroundMessageParser {
  static func type(from message: String) -> String? {
    guard let json = jsonObject(from: message) else { return nil }
    return json["type"] as? String
  }

  static func dataObject(from message: String) -> [String: Any]? {
    guard let json = jsonObject(from: message) else { return nil }
    return json["data"] as? [String: Any]
  }

  static func dataMilliseconds(from message: String) -> TimeInterval? {
    guard let json = jsonObject(from: message), let value = json["data"] else { return nil }
    if let number = value as? NSNumber {
      return number.doubleValue / 1000.0
    }
    if let integer = value as? Int {
      return Double(integer) / 1000.0
    }
    return nil
  }

  static func jsonObject(from message: String) -> [String: Any]? {
    guard let data = message.data(using: .utf8) else { return nil }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
    return json as? [String: Any]
  }
}
