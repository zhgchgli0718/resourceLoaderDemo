//
//  AssetData.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//

import Foundation
import CryptoKit

class AssetDataContentInformation: NSObject, NSCoding {
    @objc var contentLength: Int64 = 0
    @objc var contentType: String = ""
    @objc var isByteRangeAccessSupported: Bool = false
    
    func encode(with coder: NSCoder) {
        coder.encode(self.contentLength, forKey: #keyPath(AssetDataContentInformation.contentLength))
        coder.encode(self.contentType, forKey: #keyPath(AssetDataContentInformation.contentType))
        coder.encode(self.isByteRangeAccessSupported, forKey: #keyPath(AssetDataContentInformation.isByteRangeAccessSupported))
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init()
        self.contentLength = coder.decodeInt64(forKey: #keyPath(AssetDataContentInformation.contentLength))
        self.contentType = coder.decodeObject(forKey: #keyPath(AssetDataContentInformation.contentType)) as? String ?? ""
        self.isByteRangeAccessSupported = coder.decodeObject(forKey: #keyPath(AssetDataContentInformation.isByteRangeAccessSupported)) as? Bool ?? false
    }
}

class AssetData: NSObject, NSCoding {
    @objc var contentInformation: AssetDataContentInformation = AssetDataContentInformation()
    @objc var mediaData: Data = Data()
    
    override init() {
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.contentInformation, forKey: #keyPath(AssetData.contentInformation))
        coder.encode(self.mediaData, forKey: #keyPath(AssetData.mediaData))
    }
    
    required init?(coder: NSCoder) {
        super.init()
        self.contentInformation = coder.decodeObject(forKey: #keyPath(AssetData.contentInformation)) as? AssetDataContentInformation ?? AssetDataContentInformation()
        self.mediaData = coder.decodeObject(forKey: #keyPath(AssetData.mediaData)) as? Data ?? Data()
    }
}
