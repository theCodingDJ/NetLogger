import Foundation
import ObjectiveC

extension URLSession {
    
    private static let swizzleOnce: Void = {
        let selector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let swizzledSelector = #selector(URLSession.netLogger_dataTask(with:completionHandler:))
        
        guard let originalMethod = class_getInstanceMethod(URLSession.self, selector),
              let swizzledMethod = class_getInstanceMethod(URLSession.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    static func startSwizzling() {
        _ = swizzleOnce
    }
    
    @objc func netLogger_dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        let requestId = UUID().uuidString
        
        Task { @MainActor in
            NetRecorder.shared.record(id: requestId, request: request)
        }
        
        let newCompletionHandler: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            Task { @MainActor in
                NetRecorder.shared.record(response: response, data: data, error: error, forRequestId: requestId)
            }
            completionHandler(data, response, error)
        }
        
        return netLogger_dataTask(with: request, completionHandler: newCompletionHandler)
    }
}
