//
//  CachingAVURLAsset.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//

import AVFoundation
import Foundation

class CachingAVURLAsset: AVURLAsset {
    
    static let customScheme = "cachingPlayerItemScheme"
    let originalURL: URL
    private var _resourceLoader: ResourceLoader?
    
    var cacheKey: String {
        return self.url.lastPathComponent
    }
    
    static func isSchemeSupport(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        return ["http", "https"].contains(components.scheme)
    }
    
    override init(url URL: URL, options: [String: Any]? = nil) {
        self.originalURL = URL
        
        guard var components = URLComponents(url: URL, resolvingAgainstBaseURL: false) else {
            super.init(url: URL, options: options)
            return
        }
        
        components.scheme = CachingAVURLAsset.customScheme
        guard let url = components.url else {
            super.init(url: URL, options: options)
            return
        }
        
        super.init(url: url, options: options)
        
        let resourceLoader = ResourceLoader(asset: self)
        self.resourceLoader.setDelegate(resourceLoader, queue: resourceLoader.loaderQueue)
        self._resourceLoader = resourceLoader
    }
}
