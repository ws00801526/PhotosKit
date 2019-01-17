//  PKAsset.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/15
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKAsset

import Foundation
import Photos

public class PKAsset {
    public var asset: PHAsset
    
    required init(_ asset: PHAsset) {
        self.asset = asset
    }
}

public class PKAlbum : CustomDebugStringConvertible {
    
    public var name: String = ""
    
    public var count: Int { return results?.count ?? 0 }
    public var selectedCount: Int = 0
    
    // MARK: internal properties

    internal var results: PHFetchResult<PHAsset>?
    internal var assets: [PKAsset] = [] {
        didSet { self.refreshSelectedCount() }
    }
    
    internal var selectedAssets: [PKAsset] = [] {
        didSet { self.refreshSelectedCount() }
    }
    
    public var debugDescription: String { return "\(name)-\(count)"  }
}

internal extension PKAlbum {
    
    internal func set(_ results: PHFetchResult<PHAsset>?, fetchAssets: Bool = false) {
        self.results = results
        guard fetchAssets else { return }
        self.fetchAssets()
    }
    
    internal func fetchAssets(_ force: Bool = false) {
        guard let results = self.results else { return }
        guard (force || self.assets.count != results.count) else { return }
        var assets: [PKAsset] = []
        results.enumerateObjects { (asset, _, _) in assets.append(PKAsset(asset)) }
        self.assets = assets
    }
    
    convenience init(_ name: String?, results: PHFetchResult<PHAsset>?, fetchAssets: Bool = false) {
        self.init()
        self.name = name ?? ""
        self.set(results, fetchAssets: fetchAssets)
    }
}

fileprivate extension PKAlbum {
    
    fileprivate func refreshSelectedCount() {
        let all = Set(arrayLiteral: self.assets.compactMap { $0.asset })
        let selected = Set(arrayLiteral: self.selectedAssets.compactMap { $0.asset })
        self.selectedCount = all.intersection(selected).count
    }
}

extension PKAlbum {
    
    func coverAsset() -> PKAsset? {
        guard let asset = self.results?.lastObject else { return nil }
        return PKAsset(asset)
    }

    class func `default`(allowsPickVideo: Bool = false, allowsPickPhoto: Bool = true) -> PKAlbum {
        
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        
        let options = PHFetchOptions()
        if allowsPickPhoto == false { options.predicate = NSPredicate(format: "mediaType != %d", PHAssetMediaType.image.rawValue) }
        if allowsPickVideo == false { options.predicate = NSPredicate(format: "mediaType != %d", PHAssetMediaType.video.rawValue) }
        
        guard let collection = collections.firstObject else { return PKAlbum("", results: nil) }
        let results = PHAsset.fetchAssets(in: collection, options: options)
        return PKAlbum(collection.localizedTitle, results: results, fetchAssets: true)
    }
}
