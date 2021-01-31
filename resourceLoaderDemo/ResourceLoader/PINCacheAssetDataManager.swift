//
//  PINCacheAssetDataManager.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//
import PINCache
import Foundation

class PINCacheAssetDataManager: NSObject, AssetDataManager {
    
    static let Cache: PINCache = PINCache(name: "ResourceLoader")
    let cacheKey: String
    
    init(cacheKey: String) {
        self.cacheKey = cacheKey
        super.init()
    }
    
    func saveContentInformation(_ contentInformation: AssetDataContentInformation) {
        let assetData = AssetData()
        assetData.contentInformation = contentInformation
        PINCacheAssetDataManager.Cache.setObjectAsync(assetData, forKey: cacheKey, completion: nil)
    }
    
    func saveDownloadedData(_ data: Data, offset: Int) {
        guard let assetData = self.retrieveAssetData() else {
            return
        }
        
        if let mediaData = self.mergeDownloadedDataIfIsContinuted(from: assetData.mediaData, with: data, offset: offset) {
            assetData.mediaData = mediaData
            
            PINCacheAssetDataManager.Cache.setObjectAsync(assetData, forKey: cacheKey, completion: nil)
        }
    }
    
    func retrieveAssetData() -> AssetData? {
        guard let assetData = PINCacheAssetDataManager.Cache.object(forKey: cacheKey) as? AssetData else {
            return nil
        }
        return assetData
    }
}

