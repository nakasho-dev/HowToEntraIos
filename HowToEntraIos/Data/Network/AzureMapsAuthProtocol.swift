import Foundation

final class AzureMapsAuthProtocol: URLProtocol {

    private static let handledKey = "AzureMapsAuthProtocol.handled"
    static let targetHost = "atlas.microsoft.com"

    nonisolated(unsafe) private(set) static var bearerToken = ""
    nonisolated(unsafe) private(set) static var azureMapsClientId = ""

    private var dataTask: URLSessionDataTask?

    // MARK: - Public API

    static func configure(token: String, clientId: String) {
        bearerToken = token
        azureMapsClientId = clientId
    }

    static func reset() {
        bearerToken = ""
        azureMapsClientId = ""
    }

    static func makeSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [AzureMapsAuthProtocol.self] + (config.protocolClasses ?? [])
        return config
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        guard URLProtocol.property(forKey: handledKey, in: request) == nil,
              let host = request.url?.host,
              host.contains(targetHost) else {
            return false
        }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)
        mutableRequest.setValue("Bearer \(Self.bearerToken)", forHTTPHeaderField: "Authorization")
        mutableRequest.setValue(Self.azureMapsClientId, forHTTPHeaderField: "x-ms-client-id")

        let session = URLSession(configuration: .default)
        dataTask = session.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self else { return }
            if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
    }
}

