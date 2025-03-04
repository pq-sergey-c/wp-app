import Foundation

@_implementationOnly
import WpPlayerLib

public enum WpPhase: Int32 {
    case none = 0     // WP_PHASE_NONE
    case pre = 1      // WP_PHASE_PRE
    case session = 2  // WP_PHASE_SESSION
    case post = 3     // WP_PHASE_POST
}

public struct WpStream {
    public let id: String
    public let phase: WpPhase
    public let url: String
    public let fromTime: UInt64
    public let toTime: UInt64
    public let fadeOutTime: UInt64
    public let loopContent: Bool
    public let gain: Float
    public let usesSidechain: Bool
    public let sidechainGain: Float
    public init(id: String, phase: WpPhase, url: String, fromTime: UInt64, toTime: UInt64, fadeOutTime: UInt64, loopContent: Bool, gain: Float, usesSidechain: Bool, sidechainGain: Float) {
        self.id = id
        self.phase = phase
        self.url = url
        self.fromTime = fromTime
        self.toTime = toTime
        self.fadeOutTime = fadeOutTime
        self.loopContent = loopContent
        self.gain = gain
        self.usesSidechain = usesSidechain
        self.sidechainGain = sidechainGain
    }
}

enum WpPlayerLibError: Error {
    case runtimeError(String)
}

typealias WpNetworkRequestCallback = @convention(c) (
    UnsafeRawPointer?,
    UInt32,
    UnsafePointer<CChar>?,
    Int64
) -> Void

typealias WpCancelNetworkRequestCallback = @convention(c) (
    UnsafeRawPointer?,
    UInt32
) -> Void


public class WpPlayerLibBridge {
    private let networkRequestCallback: WpNetworkRequestCallback;
    private let cancelNetworkRequestCallback: WpCancelNetworkRequestCallback;

    private var _wpPlayerLib: OpaquePointer? = Optional.none;

    public init(bufferLookahead: Int64) throws {
      NetworkManager.shared.cleanupTemporaryFiles()
      self._wpPlayerLib = wp_playerlib_create(48000.0, bufferLookahead)
      if self._wpPlayerLib == nil {
          throw WpPlayerLibError.runtimeError("Failed to create WpPlayerLib")
      }
      self.networkRequestCallback = { (context, requestId, urlC, time) in
          if let context = context {
              let me = Unmanaged<WpPlayerLibBridge>.fromOpaque(context).takeUnretainedValue()
              let retained = Unmanaged.passRetained(me)
              guard let urlC = urlC else {
                  print("Request \(requestId) for nil URL")
                  retained.release()
                  return
              }
              let urlString = String(cString: urlC)
              print("Downloading \(urlString)")
              let url = urlString.starts(with: "/") ? URL(fileURLWithPath: urlString) : URL(string: urlString)!
              NetworkManager.shared.downloadTask(with: url, id: Int(requestId), time: time) { [me] localUrl, response, error in
                  defer { retained.release() }
                  guard let wpPlayerLib = me._wpPlayerLib else {
                      print("WpPlayerLib is not initialized in network request callback")
                      return
                  }
                  if let localUrl = localUrl {
                      let localPathC = strdup(localUrl.path)
                      defer {
                          free(localPathC)
                      }
                      wp_playerlib_on_network_response(wpPlayerLib, requestId, 0, localPathC)
                  } else {
                      print("Error downloading \(url): \(error?.localizedDescription ?? "Unknown error")")
                      wp_playerlib_on_network_response(wpPlayerLib, requestId, 1, nil)
                  }
              }
          } else {
              print("networkRequestCallback: context is nil")
          }
      }
      self.cancelNetworkRequestCallback = { (context, requestId) in
          print("Cancelling request \(requestId)")
          NetworkManager.shared.cancelDownloadTask(with: Int(requestId))
      }
      if let wpPlayerLib = self._wpPlayerLib {
          let context = Unmanaged.passRetained(self).toOpaque()
          wp_playerlib_register_network_request_callbacks(wpPlayerLib, self.networkRequestCallback, self.cancelNetworkRequestCallback, context)
      }
    }

    public func setSession(streams: [WpStream]) throws {
        let streamCount = streams.count
        let streamsC = UnsafeMutablePointer<WpPlayerLibStream>.allocate(capacity: streamCount)        
        for i in 0..<streamCount {
            let idString = strdup(streams[i].id)
            let urlString = strdup(streams[i].url)
            streamsC[i] = WpPlayerLibStream(
                id: idString,
                phase: WpPlayerLibPhase(UInt32(streams[i].phase.rawValue)),
                url: urlString,
                fromTime: streams[i].fromTime,
                toTime: streams[i].toTime,
                fadeOutTime: streams[i].fadeOutTime,
                loopContent: streams[i].loopContent ? UInt8(1) : UInt8(0),
                gain: streams[i].gain,
                usesSidechain: streams[i].usesSidechain ? UInt8(1) : UInt8(0),
                sidechainGain: streams[i].sidechainGain
            )
        }        
        defer {
            for i in 0..<streamCount {
                free(UnsafeMutablePointer(mutating: streamsC[i].id))
                free(UnsafeMutablePointer(mutating: streamsC[i].url))
            }
            streamsC.deallocate()
        }
        
        if let wpPlayerLib = self._wpPlayerLib {
            let result = wp_playerlib_set_session(wpPlayerLib, streamsC, Int32(streamCount))
            if result != 0 {
                throw WpPlayerLibError.runtimeError("Failed to set session (error code \(result))")
            }
        } else {
            throw WpPlayerLibError.runtimeError("WpPlayerLib is not initialized in setSession")
        }
    }

    public func setPhase(phase: WpPhase, atTimeInPhase: Int64) throws {
        if let wpPlayerLib = self._wpPlayerLib {
            let result = wp_playerlib_set_phase(wpPlayerLib, WpPlayerLibPhase(UInt32(phase.rawValue)), atTimeInPhase)
            if result != 0 {
                throw WpPlayerLibError.runtimeError("Failed to set phase (error code \(result))")
            }
        } else {
            throw WpPlayerLibError.runtimeError("WpPlayerLib is not initialized in setTimelineState")
        }
    }

    public func start() throws {
        if let wpPlayerLib = self._wpPlayerLib {
            let result = wp_playerlib_start(wpPlayerLib)
            if result != 0 {
                throw WpPlayerLibError.runtimeError("Failed to start WpPlayerLib (error code \(result))")
            }
        }
    }

    public func stop() throws {
        if let wpPlayerLib = self._wpPlayerLib {
            let result = wp_playerlib_stop(wpPlayerLib)
            if result != 0 {
                throw WpPlayerLibError.runtimeError("Failed to stop WpPlayerLib (error code \(result))")
            }
        }
    }

    public func isStarted() -> Bool {
        if let wpPlayerLib = self._wpPlayerLib {
            return wp_playerlib_is_started(wpPlayerLib)
        }
        return false
    }

    public func setVolume(volume: Float) {
        if let wpPlayerLib = self._wpPlayerLib {
            wp_playerlib_set_volume(wpPlayerLib, volume)
        }
    }

    public func getBufferedTime() -> Float {
        if let wpPlayerLib = self._wpPlayerLib {
            return wp_playerlib_get_buffered_time(wpPlayerLib)
        }
        return 0.0
    }

    public func destroy() {
        if let wpPlayerLib = self._wpPlayerLib {
            self._wpPlayerLib = nil
            let context = wp_playerlib_get_network_request_callback_context(wpPlayerLib)
            if let context = context {
                Unmanaged<WpPlayerLibBridge>.fromOpaque(context).release()
            }
            wp_playerlib_destroy(wpPlayerLib)
        }
    }
}
