class AssetPlaybackManagerFactory {
  static let shared = AssetPlaybackManagerFactory()

  private var hlsManager: HLSAssetPlaybackManager?;
  private var playerLibManager: PlayerLibPlaybackManager?;

  @MainActor
  func initManager(usePlayerLib: Bool, sessionInfo: WPSessionInfo) async {
    let session = await WPSession.fetch(sessionInfo: sessionInfo)
    guard let session = session else {
      print("AssetPlaybackManagerFactory initManager() failed to fetch session")
      return
    }
    if usePlayerLib {
      if playerLibManager == nil {
          playerLibManager = PlayerLibPlaybackManager()
      }
      do {
        try playerLibManager!.connect(sessionInfo: sessionInfo, session: session)
      } catch {
        print("AssetPlaybackManagerFactory initManager() failed to connect to PlayerLibPlaybackManager: \(error)")
      }
      if hlsManager != nil {
        hlsManager?.unloadAsset()
        hlsManager = nil
      }
    } else {
      let asset = Asset(sessionInfo: sessionInfo, session: session)
      if hlsManager == nil {
        hlsManager = HLSAssetPlaybackManager()
      }
      hlsManager!.setAssetForPlayback(asset)
      if playerLibManager != nil {
        playerLibManager = nil
      }
    }
  }

  func getManager() -> AssetPlaybackManagerProtocol {
    if playerLibManager != nil {
      return playerLibManager!
    }
    if hlsManager == nil {
      hlsManager = HLSAssetPlaybackManager()
    }
    return hlsManager!
  }
}
