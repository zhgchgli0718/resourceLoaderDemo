//
//  ResourceLoader.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//

import AVFoundation
import Foundation

class ResourceLoader: NSObject {
    
    let loaderQueue = DispatchQueue(label: "li.zhgchg.resourceLoader.queue")
    
    private var requests: [AVAssetResourceLoadingRequest: ResourceLoaderRequest] = [:]
    private let cacheKey: String
    private let originalURL: URL
    
    init(asset: CachingAVURLAsset) {
        self.cacheKey = asset.cacheKey
        self.originalURL = asset.originalURL
        super.init()
    }

    deinit {
        self.requests.forEach { (request) in
            request.value.cancel()
        }
    }
}

extension ResourceLoader: AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        let type = ResourceLoader.resourceLoaderRequestType(loadingRequest)
        let assetDataManager = PINCacheAssetDataManager(cacheKey: self.cacheKey)

        if let assetData = assetDataManager.retrieveAssetData() {
            if type == .contentInformation {
                loadingRequest.contentInformationRequest?.contentLength = assetData.contentInformation.contentLength
                loadingRequest.contentInformationRequest?.contentType = assetData.contentInformation.contentType
                loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = assetData.contentInformation.isByteRangeAccessSupported
                loadingRequest.finishLoading()
                return true
            } else {
                let range = ResourceLoader.resourceLoaderRequestRange(type, loadingRequest)
                if assetData.mediaData.count > 0 {
                    let end: Int64
                    switch range.end {
                    case .requestTo(let rangeEnd):
                        end = rangeEnd
                    case .requestToEnd:
                        end = assetData.contentInformation.contentLength
                    }
                    
                    if assetData.mediaData.count >= end {
                        let subData = assetData.mediaData.subdata(in: Int(range.start)..<Int(end))
                        loadingRequest.dataRequest?.respond(with: subData)
                        loadingRequest.finishLoading()
                       return true
                    } else if range.start <= assetData.mediaData.count {
                        // has cache data...but not enough
                        let subEnd = (assetData.mediaData.count > end) ? Int((end)) : (assetData.mediaData.count)
                        let subData = assetData.mediaData.subdata(in: Int(range.start)..<subEnd)
                        loadingRequest.dataRequest?.respond(with: subData)
                    }
                }
            }
        }
        
        let range = ResourceLoader.resourceLoaderRequestRange(type, loadingRequest)
        let resourceLoaderRequest = ResourceLoaderRequest(originalURL: self.originalURL, type: type, loaderQueue: self.loaderQueue, assetDataManager: assetDataManager)
        resourceLoaderRequest.delegate = self
        self.requests[loadingRequest]?.cancel()
        self.requests[loadingRequest] = resourceLoaderRequest
        resourceLoaderRequest.start(requestRange: range)
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let resourceLoaderRequest = self.requests[loadingRequest] else {
            return
        }
        
        resourceLoaderRequest.cancel()
        requests.removeValue(forKey: loadingRequest)
    }
}

extension ResourceLoader: ResourceLoaderRequestDelegate {
    func contentInformationDidComplete(_ resourceLoaderRequest: ResourceLoaderRequest, _ result: Result<AssetDataContentInformation, Error>) {
        guard let loadingRequest = self.requests.first(where: { $0.value == resourceLoaderRequest })?.key else {
            return
        }
        
        switch result {
        case .success(let contentInformation):
            loadingRequest.contentInformationRequest?.contentType = contentInformation.contentType
            loadingRequest.contentInformationRequest?.contentLength = contentInformation.contentLength
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = contentInformation.isByteRangeAccessSupported
            loadingRequest.finishLoading()
        case .failure(let error):
            loadingRequest.finishLoading(with: error)
        }
    }
    
    func dataRequestDidReceive(_ resourceLoaderRequest: ResourceLoaderRequest, _ data: Data) {
        guard let loadingRequest = self.requests.first(where: { $0.value == resourceLoaderRequest })?.key else {
            return
        }
        
        loadingRequest.dataRequest?.respond(with: data)
    }
    
    func dataRequestDidComplete(_ resourceLoaderRequest: ResourceLoaderRequest, _ error: Error?, _ downloadedData: Data) {
        guard let loadingRequest = self.requests.first(where: { $0.value == resourceLoaderRequest })?.key else {
            return
        }
        
        loadingRequest.finishLoading(with: error)
        requests.removeValue(forKey: loadingRequest)
    }
}

extension ResourceLoader {
    static func resourceLoaderRequestType(_ loadingRequest: AVAssetResourceLoadingRequest) -> ResourceLoaderRequest.RequestType {
        if let _ = loadingRequest.contentInformationRequest {
            return .contentInformation
        } else {
            return .dataRequest
        }
    }
    
    static func resourceLoaderRequestRange(_ type: ResourceLoaderRequest.RequestType, _ loadingRequest: AVAssetResourceLoadingRequest) -> ResourceLoaderRequest.RequestRange {
        if type == .contentInformation {
            return ResourceLoaderRequest.RequestRange(start: 0, end: .requestTo(1))
        } else {
            if loadingRequest.dataRequest?.requestsAllDataToEndOfResource == true {
                let lowerBound = loadingRequest.dataRequest?.currentOffset ?? 0
                return ResourceLoaderRequest.RequestRange(start: lowerBound, end: .requestToEnd)
            } else {
                let lowerBound = loadingRequest.dataRequest?.currentOffset ?? 0
                let length = Int64(loadingRequest.dataRequest?.requestedLength ?? 1)
                let upperBound = lowerBound + length
                return ResourceLoaderRequest.RequestRange(start: lowerBound, end: .requestTo(upperBound))
            }
        }
    }
}

