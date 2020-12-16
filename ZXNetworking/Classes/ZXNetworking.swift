//
//  ZXNetworking.swift
//  SwiftTest
//
//  Created by Mac on 2020/12/4.
//

import Alamofire

public typealias ZXNSuccessClosure = (_ json: Any) -> Void
public typealias ZXNFailedClosure = (_ error: ZXNetworkingError) -> Void
public typealias ZXNProgressHandler = (Progress) -> Void

public enum ZXNReachabilityStatus {
    case unknown
    case notReachable
    case ethernetOrWiFi
    case cellular
}

public let ZXN = ZXNetworking.shared
public let kNetworkStatusNotification = NSNotification.Name("kNetworkStatusNotification")

public class ZXNetworking {
    public static let shared = ZXNetworking()
    var sessionManager: Alamofire.Session!
    var reachability: NetworkReachabilityManager?
    var networkStatus: ZXNReachabilityStatus = .unknown
    var downloadRequest: DownloadRequest?
    var downloadResumeData: Data?
    
    private init() {
        let config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 30
        
//        config.headers.add(name: "authorization", value: "token")
        
        sessionManager = Alamofire.Session(configuration: config)
    }
    
    
    public func request(url: String,
                        method: HTTPMethod = .get,
                        parameters: [String: Any]?,
                        headers: [String: String]? = nil,
                        encoding: ParameterEncoding = URLEncoding.default) -> ZXNetworkRequest {
        let task = ZXNetworkRequest()
        
        var h: HTTPHeaders?
        if let temp_Headers = headers {
            h = HTTPHeaders(temp_Headers)
        }
        
        task.request = sessionManager.request(url,
                                              method: method,
                                              parameters: parameters,
                                              encoding: encoding,
                                              headers: h).validate().responseJSON(completionHandler: { (response) in
                                                task.handleResponse(response)
                                              })
        
        return task
    }
    
    func upload(url: String,
                method: HTTPMethod = .post,
                parameters: [String: String]?,
                datas: [ZXMultipartData],
                headers: [String: String]? = nil) -> ZXNetworkRequest {
        let task = ZXNetworkRequest()

//        var headers = ["content-type":"multipart/form-data"]
        var h: HTTPHeaders?
        if let tempHeaders = headers {
            h = HTTPHeaders(tempHeaders)
        }
        
        sessionManager.upload(multipartFormData: { (multipartFormData) in
            // 参数
            for kv in parameters ?? [:] {
                multipartFormData.append(kv.value.data(using: .utf8)!, withName: kv.key)
            }
            // 数据
            for data in datas {
                multipartFormData.append(data.data, withName: data.name, fileName: data.fileName, mimeType: data.mimeType)
            }
            
        }, to: url, method: method, headers: h).uploadProgress { (progress) in
            task.handleProgress(progress: progress)
        }.validate().responseJSON { (response) in
            task.handleResponse(response)
        }
        
        return task
    }
    
    func download(url: String,
                  method: HTTPMethod = .get,
                  fileName: String,
                  parameters: [String: Any]?,
                  headers: [String: String]? = nil) -> ZXNetworkRequest {
        let task = ZXNetworkRequest()
        
        var h: HTTPHeaders?
        if let tempHeaders = headers {
            h = HTTPHeaders(tempHeaders)
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(fileName)

            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        if downloadResumeData != nil { // 恢复下载
            downloadRequest = sessionManager.download(resumingWith: downloadResumeData!, to: destination).downloadProgress(closure: { (progress) in
                task.handleProgress(progress: progress)
            }).validate().response(completionHandler: { (downloadResponse) in
                self.downloadResumeData = nil
                task.handleDownloadResponse(downloadResponse)
            })
        } else { // 新下载
            downloadRequest = sessionManager.download(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: h, to: destination).downloadProgress(closure: { (progress) in
                task.handleProgress(progress: progress)
            }).validate().response(completionHandler: { (downloadResponse) in
                self.downloadResumeData = nil
                task.handleDownloadResponse(downloadResponse)
            })
//            .responseJSON { [unowned self] (response) in
//                self.downloadResumeData = nil
//                task.handleDownloadResponse(response)
//            }
        }
        
        return task
    }
    
    
    /// 发送 Encodable 格式参数的请求（String, Array）
    func request<Parameters: Encodable>(url: String,
                                        method: HTTPMethod = .post,
                                        parameters: Parameters,
                                        headers: [String: String]? = nil) -> ZXNetworkRequest  {
        let task = ZXNetworkRequest()
        
        guard let u = URL(string: url) else{
            debugPrint("url is unknow!")
            return task
        }
        
        var urlRequest = URLRequest(url: u)
        urlRequest.httpMethod = method.rawValue
        
        for (key, value) in headers ?? [:] {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        switch parameters {
        case is String:
            urlRequest.httpBody = (parameters as! String).data(using: .utf8)
        case is Array<Any>:
            let data = try? JSONSerialization.data(withJSONObject: parameters)
            urlRequest.httpBody = data
        default:
            print("parameters unkonw!")
            return task
        }
        
        sessionManager.request(urlRequest).responseJSON { (response) in
            task.handleResponse(response)
        }
        return task
    }
    
    
    /// 发送GET请求
    @discardableResult
    public func GET(url: String, parameters: [String: Any]?, headers: [String: String]? = nil) -> ZXNetworkRequest {
        request(url: url, method: .get, parameters: parameters, headers: headers)
    }
    
    /// 发送POST请求
    @discardableResult
    public func POST(url: String, parameters: [String: Any]?, headers: [String: String]? = nil) -> ZXNetworkRequest {
        request(url: url, method: .post, parameters: parameters, headers: headers)
    }
    
    
    
//    func aaa() {
//        var urlRequest =  URLRequest(url: URL(string: "www.baidu.com")!)
//        urlRequest.httpMethod = "POST"
//        let encoder = URLEncodedFormParameterEncoder(encoder: URLEncodedFormEncoder(arrayEncoding: .brackets))
////        let encodedURLRequest = try! encoder.encode([1,2], into: urlRequest)
//
//        sessionManager.request("http://association.cdzhongche.com/login", method: HTTPMethod.post, parameters: [1,2], encoder: JSONParameterEncoder.default, headers: nil).responseJSON { (res) in
//            print(res)
//        }
//    }
    
//    func request<Parameters: Encodable>(url: String,
//                                        method: HTTPMethod = .get,
//                                        parameters: Parameters?,
//                                        headers: [String: String]? = nil,
//                                        encoding: ParameterEncoding = URLEncoding.default) -> ZXNetworkRequest {
//        switch parameters {
//        case is String:
//            print("str")
//        case is Array<Any>:
//            print("arr")
//        default:
//            print("parameters unkonw!")
//        }
//
//        //
//        let u = URL(string: url)
//        if u == nil {
//            fatalError("URL有误!")
//        }
//
//        var urlRequest =  URLRequest(url: u!)
//        urlRequest.httpMethod = method.rawValue
//        let encoder = URLEncodedFormParameterEncoder(encoder: URLEncodedFormEncoder(arrayEncoding: .brackets))
//        let encodedURLRequest = try! encoder.encode(parameters, into: urlRequest)
//
//        let r = sessionManager.request(encodedURLRequest).responseJSON { (res) in
//
//        }
//
//        let task = ZXNetworkRequest()
//        task.request = r
//        return task
//    }
}

extension ZXNetworking {
    
    
    /// 取消/暂停下载
    func downloadCancel() {
        downloadRequest?.cancel { [unowned self] data in
            self.downloadResumeData = data
        }
    }
    
    /// 监控网络状态
    public func startMonitoring() {
        if reachability == nil {
            reachability = NetworkReachabilityManager.default
        }

        reachability?.startListening(onQueue: .main, onUpdatePerforming: { [unowned self] (status) in
            switch status {
            case .notReachable:
                self.networkStatus = .notReachable
            case .unknown:
                self.networkStatus = .unknown
            case .reachable(.ethernetOrWiFi):
                self.networkStatus = .ethernetOrWiFi
            case .reachable(.cellular):
                self.networkStatus = .cellular
            }
            // Sent notification
            NotificationCenter.default.post(name: kNetworkStatusNotification, object: nil)
            debugPrint("ZXNetworking Network Status: \(self.networkStatus)")
        })
    }
    
    
    /// 停止网络状态监控
    public func stopMonitoring() {
        guard reachability != nil else { return }
        reachability?.stopListening()
    }
    
    /// 添加header
    public func addHeader(_ headers: [String: String]) {
        for (key, value) in headers {
            sessionManager.sessionConfiguration.headers.add(name: key, value: value)
        }
    }
    
    func disposeUrl(DOMAIN basePath:String, _ url: String) -> String {
        var path: String = basePath
        let subPath: String = url
        
        var fullUrl = path
        if path.count != 0, subPath.count != 0  {
            if path.hasSuffix("/"),subPath.hasPrefix("/") {
                path = String(path.prefix(path.count - 1))
            } else if !path.hasSuffix("/"),!subPath.hasPrefix("/") {
                path = path + "/"
            }
            fullUrl = path + subPath
        } else if path.count == 0 {
            fullUrl = subPath
        } else if subPath.count == 0 {
            fullUrl = path
        }
        
        return fullUrl
    }
}

public class ZXNetworkRequest: Equatable {
    
    var request: Alamofire.Request?
    private var successHandler: ZXNSuccessClosure?
    private var failedHandler: ZXNFailedClosure?
    private var progressHandler: ZXNProgressHandler?
    
    func handleResponse(_ response: AFDataResponse<Any>) {
        switch response.result {
        case .failure(let error):
            if let closure = failedHandler {
                let err = ZXNetworkingError(code: error.responseCode ?? -1, desc: error.localizedDescription)
                closure(err)
            }
        case .success(let json):
            if let closure = successHandler {
                closure(json)
            }
        }
        
        clearReference()
    }
    
    func handleProgress(progress: Progress) {
        if let closure = progressHandler {
            closure(progress)
        }
    }
    
    func handleDownloadResponse(_ response: DownloadResponse<URL?, AFError>) {
        switch response.result {
        case .failure(let error):
            if let closure = failedHandler {
                let err = ZXNetworkingError(code: error.responseCode ?? -1, desc: error.localizedDescription)
                closure(err)
            }
        case .success(let fileURL):
            if let closure = successHandler {
                closure(fileURL?.path ?? "")
            }
        }
        
        clearReference()
    }
    
    @discardableResult
    public func success(_ closure: @escaping ZXNSuccessClosure) -> Self {
        successHandler = closure
        return self
    }
    
    @discardableResult
    public func failed(_ closure: @escaping ZXNFailedClosure) -> Self {
        failedHandler = closure
        return self
    }
    
    @discardableResult
    public func progress(closure: @escaping ZXNProgressHandler) -> Self {
        progressHandler = closure
        return self
    }
    
    func cancel() {
        request?.cancel()
    }
    
    func clearReference() {
        successHandler = nil
        failedHandler = nil
        progressHandler = nil
    }
    
    public static func == (lhs: ZXNetworkRequest, rhs: ZXNetworkRequest) -> Bool {
        return lhs.request?.id == rhs.request?.id
    }
}

