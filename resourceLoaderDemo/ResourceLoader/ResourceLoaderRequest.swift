//
//  ResourceLoaderRequest.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//

import Foundation
import CoreServices

protocol ResourceLoaderRequestDelegate: AnyObject {
    func dataRequestDidReceive(_ resourceLoaderRequest: ResourceLoaderRequest, _ data: Data)
    func dataRequestDidComplete(_ resourceLoaderRequest: ResourceLoaderRequest, _ error: Error?, _ downloadedData: Data)
    func contentInformationDidComplete(_ resourceLoaderRequest: ResourceLoaderRequest, _ result: Result<AssetDataContentInformation, Error>)
}

class ResourceLoaderRequest: NSObject, URLSessionDataDelegate {
    struct RequestRange {
        var start: Int64
        var end: RequestRangeEnd
        
        enum RequestRangeEnd {
            case requestTo(Int64)
            case requestToEnd
        }
    }
    
    enum RequestType {
        case contentInformation
        case dataRequest
    }
    
    struct ResponseUnExpectedError: Error { }
    
    private let loaderQueue: DispatchQueue
    
    let originalURL: URL
    let type: RequestType
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var assetDataManager: AssetDataManager?
    
    private(set) var requestRange: RequestRange?
    private(set) var response: URLResponse?
    private(set) var downloadedData: Data = Data()
    
    private(set) var isCancelled: Bool = false {
        didSet {
            if isCancelled {
                self.dataTask?.cancel()
                self.session?.invalidateAndCancel()
            }
        }
    }
    private(set) var isFinished: Bool = false {
        didSet {
            if isFinished {
                self.session?.finishTasksAndInvalidate()
            }
        }
    }
    
    weak var delegate: ResourceLoaderRequestDelegate?
    
    init(originalURL: URL, type: RequestType, loaderQueue: DispatchQueue, assetDataManager: AssetDataManager?) {
        self.originalURL = originalURL
        self.type = type
        self.loaderQueue = loaderQueue
        self.assetDataManager = assetDataManager
        super.init()
    }
    
    func start(requestRange: RequestRange) {
        guard isCancelled == false, isFinished == false else {
            return
        }
        
        self.loaderQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            var request = URLRequest(url: self.originalURL)
            self.requestRange = requestRange
            let start = String(requestRange.start)
            let end: String
            switch requestRange.end {
            case .requestTo(let rangeEnd):
                end = String(rangeEnd)
            case .requestToEnd:
                end = ""
            }
            
            let rangeHeader = "bytes=\(start)-\(end)"
            request.setValue(rangeHeader, forHTTPHeaderField: "Range")
            
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.session = session
            let dataTask = session.dataTask(with: request)
            self.dataTask = dataTask
            dataTask.resume()
        }
    }
    
    func cancel() {
        self.isCancelled = true
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard self.type == .dataRequest else {
            return
        }
        
        self.loaderQueue.async {
            self.delegate?.dataRequestDidReceive(self, data)
            self.downloadedData.append(data)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.isFinished = true
        self.loaderQueue.async {
            if self.type == .contentInformation {
                guard error == nil,
                      let response = self.response as? HTTPURLResponse else {
                    let responseError = error ?? ResponseUnExpectedError()
                    self.delegate?.contentInformationDidComplete(self, .failure(responseError))
                    return
                }
                
                let contentInformation = AssetDataContentInformation()
                
                if let rangeString = response.allHeaderFields["Content-Range"] as? String,
                   let bytesString = rangeString.split(separator: "/").map({String($0)}).last,
                   let bytes = Int64(bytesString) {
                    contentInformation.contentLength = bytes
                }
                
                if let mimeType = response.mimeType,
                   let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() {
                    contentInformation.contentType = contentType as String
                }
                
                if let value = response.allHeaderFields["Accept-Ranges"] as? String,
                   value == "bytes" {
                    contentInformation.isByteRangeAccessSupported = true
                } else {
                    contentInformation.isByteRangeAccessSupported = false
                }
                
                self.assetDataManager?.saveContentInformation(contentInformation)
                self.delegate?.contentInformationDidComplete(self, .success(contentInformation))
            } else {
                if let offset = self.requestRange?.start, self.downloadedData.count > 0 {
                    self.assetDataManager?.saveDownloadedData(self.downloadedData, offset: Int(offset))
                }
                self.delegate?.dataRequestDidComplete(self, error, self.downloadedData)
            }
        }
    }
}
