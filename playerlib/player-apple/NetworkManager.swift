import Foundation

class NetworkManager {

    static let shared = NetworkManager()

    private let serialQueue = DispatchQueue(label: "com.wavepaths.networkmanager")
    private let session = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return configuration
    }())

    static let temporaryDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("wpplayerlib", isDirectory: true)
    }()
    
    private var ongoingDownloads: NSMapTable<NSNumber, URLSessionDownloadTask>

    private init() {
        ongoingDownloads = NSMapTable(keyOptions: .strongMemory, valueOptions: .weakMemory)
        createDirectories()
        print("Undertone temporary directory: \(NetworkManager.temporaryDirectoryURL.path)")
    }

    private func createDirectories() {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: NetworkManager.temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directories: \(error)")
        }
    }



    func downloadTask(with url: URL, id: Int, time: Int64, completion: @escaping (URL?, URLResponse?, Error?) -> Void) {
        let task = serialQueue.sync {
            var request: URLRequest
            if url.isFileURL {
                request = URLRequest(url: url)
            } else {
                request = URLRequest(url: url)
                request.addValue("*/*", forHTTPHeaderField: "Accept")
            }

            let task = session.downloadTask(with: request) { localUrl, response, error in
                defer {
                    self.serialQueue.sync {
                        self.ongoingDownloads.removeObject(forKey: id as NSNumber)
                    }
                }
                
                var statusError: Error? = nil
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    statusError = NSError(domain: NSURLErrorDomain,
                                          code: httpResponse.statusCode,
                                          userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
                }
                
                if let error = error ?? statusError {
                    if let nsError = error as? NSError, nsError.code == NSURLErrorCancelled {
                        print("Download task cancelled")
                        return
                    }
                    print("Error downloading \(url): \(error)")
                    completion(nil, nil, error)
                } else if let localUrl = localUrl {
                    let destinationURL = self.generateTempFileURL()
                    do {
                        try FileManager.default.moveItem(at: localUrl, to: destinationURL)
                        completion(destinationURL, response, nil)
                    } catch {
                        print("Error moving downloaded file: \(error)")
                        completion(nil, nil, error)
                    } 
                }
            }
            ongoingDownloads.setObject(task, forKey: id as NSNumber)
            return task
        }
        let currentTime = Date().timeIntervalSince1970 * 1000.0
        let delayMillis = Double(time) - currentTime
        let delayInterval = TimeInterval(max(0, delayMillis) / 1000.0)
        if delayInterval > 0 {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delayInterval) { [task] in
                task.resume()
            }
        } else {
            task.resume()
        }
    }

    private func generateTempFileURL() -> URL {
        return NetworkManager.temporaryDirectoryURL.appendingPathComponent(UUID().uuidString)
    }

    func cancelDownloadTask(with id: Int) {
        serialQueue.sync {
            if let task = ongoingDownloads.object(forKey: id as NSNumber) {
                print("Cancelling download with id \(id)")
                task.cancel()
                ongoingDownloads.removeObject(forKey: id as NSNumber)
            }
        }
    }

    func cleanupTemporaryFiles() {
        serialQueue.sync {
            let fileManager = FileManager.default
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: NetworkManager.temporaryDirectoryURL, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    try fileManager.removeItem(at: fileURL)
                }
                print("Cleaned up all files in temporary directory")
            } catch {
                print("Error cleaning up temporary files: \(error)")
            }
        }
    }
}
