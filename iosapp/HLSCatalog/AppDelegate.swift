import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("Starting...")
        print(ConfigurationManager.singleton.anonymousId)
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("Starting with URL...")
        return openSessionViaActivationUrl(url: url)
    }
    
    func openSessionViaActivationUrl(url: URL) -> Bool {
        print("Opening URL while running \(url)")
        
        print("URL: \(url)")

        // Process the URL.
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let path = components.path else {
                print("Invalid URL : \(url) ")
                return false
            }
        
        let pathParts = path.components(separatedBy: "/")
        
        guard let broadcastIdentifier = pathParts.last else {
            print("No broadcastIdentifier")
            return false
        }
        let freudEnv = pathParts.first { x in
            x == "dev" || x == "dev-local" || x == "prod"
        } ?? "prod"
        
        let freeVOPlayback = pathParts.filter({ x in
            x == "free"
        }).count > 0 ? true : false

        let usePlayerLib = pathParts.filter({ x in
            x == "playerlib"
        }).count > 0 ? true : false
        
        let FREUD_STREAMS_BASE_URL = freudEnv == "dev" || freudEnv == "dev-local" ? "freud-streams-dev.wavepaths.com" : "freud-streams.wavepaths.com"
        
        let streamUrl = "https://\(FREUD_STREAMS_BASE_URL)/streamdata/\(broadcastIdentifier)/stream.m3u8"
        
        print("Stream that activated: \(streamUrl)")
        
        let sessionInfo = WPSessionInfo(name: "Wavepaths", playlistUrl: streamUrl, broadcastIdentifier: broadcastIdentifier, freudEnv: freudEnv, freeVOPlayback: freeVOPlayback)
        
        Task { @MainActor in
            await AssetPlaybackManagerFactory.shared.initManager(usePlayerLib: usePlayerLib, sessionInfo: sessionInfo)
            print("Setting last opened URL to \(url)")
        }
        return true
    }
}
