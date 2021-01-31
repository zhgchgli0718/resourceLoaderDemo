//
//  AssetDataManager.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//

import Foundation

protocol AssetDataManager: NSObject {
    func retrieveAssetData() -> AssetData?
    func saveContentInformation(_ contentInformation: AssetDataContentInformation)
    func saveDownloadedData(_ data: Data, offset: Int)
    func mergeDownloadedDataIfIsContinuted(from: Data, with: Data, offset: Int) -> Data?
}

extension AssetDataManager {
    func mergeDownloadedDataIfIsContinuted(from: Data, with: Data, offset: Int) -> Data? {
        if offset <= from.count && (offset + with.count) > from.count {
            let start = from.count - offset
            var data = from
            data.append(with.subdata(in: start..<with.count))
            return data
        }
        return nil
    }
}
