import Foundation

public struct HTTPRequestLog: Identifiable, Hashable {
    public let id: String
    public let url: URL?
    public let method: String?
    public let headers: [String: String]?
    public let body: Data?
    public let date: Date
    
    public var response: HTTPResponseLog?
    public var error: ErrorLog?
    public var duration: TimeInterval?
    
    public init(id: String, request: URLRequest) {
        self.id = id
        self.url = request.url
        self.method = request.httpMethod
        self.headers = request.allHTTPHeaderFields
        self.body = request.httpBody
        self.date = Date()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: HTTPRequestLog, rhs: HTTPRequestLog) -> Bool {
        lhs.id == rhs.id
    }
}

public struct HTTPResponseLog: Hashable {
    public let statusCode: Int
    public let headers: [String: String]?
    public let body: Data?
    public let date: Date
    
    public init(response: HTTPURLResponse, data: Data?) {
        self.statusCode = response.statusCode
        self.headers = response.allHeaderFields as? [String: String]
        self.body = data
        self.date = Date()
    }
}

public struct ErrorLog: Hashable {
    public let localizedDescription: String
    public let domain: String
    public let code: Int
    
    public init(error: Error) {
        self.localizedDescription = error.localizedDescription
        let nsError = error as NSError
        self.domain = nsError.domain
        self.code = nsError.code
    }
}

/// Records network requests and responses
/// Uses NotificationCenter to notify observers when requests change
@MainActor
public class NetRecorder {
    public static let shared = NetRecorder()
    
    public private(set) var requests: [HTTPRequestLog] = []
    
    private init() {}
    
    public func record(id: String, request: URLRequest) {
        let log = HTTPRequestLog(id: id, request: request)
        requests.insert(log, at: 0)
        notifyChange()
    }
    
    public func record(
        response: URLResponse?,
        data: Data?,
        error: Error?,
        forRequestId id: String
    ) {
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }
        
        var log = requests[index]
        log.duration = Date().timeIntervalSince(log.date)
        
        if let error {
            log.error = ErrorLog(error: error)
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            log.response = HTTPResponseLog(response: httpResponse, data: data)
        }
        
        requests[index] = log
        notifyChange()
    }
    
    public func clear() {
        requests.removeAll()
        notifyChange()
    }
    
    private func notifyChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("NetLoggerRequestsChanged"),
            object: nil
        )
    }
}
