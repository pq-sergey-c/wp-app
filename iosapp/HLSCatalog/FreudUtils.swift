import Foundation

struct FreudUtils {
    static func getFreudBaseUrl(env: String) -> String {
        switch env {
        case "dev-local":
            return "http://localhost:8080"
        case "dev":
            return "https://freud-dev.wavepaths.com"
        default:
            return "https://freud.wavepaths.com"
        }
    }
}