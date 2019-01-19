//  PKAsset.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/15
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKAsset

import Foundation
import Photos

public class PKAsset : CustomStringConvertible, CustomDebugStringConvertible {
    
    public var asset: PHAsset
    
    required init(_ asset: PHAsset) {
        self.asset = asset
    }
    
    public var description: String { return "\(asset)" }
    public var debugDescription: String { return "\(asset)" }
}

extension PKAsset : Equatable {
    public static func == (lhs: PKAsset, rhs: PKAsset) -> Bool {
        return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}

public class PKAlbum : CustomStringConvertible, CustomDebugStringConvertible {
    
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
    
    public var description: String { return "\(name)-\(count)" }
    public var debugDescription: String { return "\(name)-\(count)" }
    
}

extension PKAlbum : Equatable {
    
    public static func == (lhs: PKAlbum, rhs: PKAlbum) -> Bool {
        guard let lresults = lhs.results else { return false }
        guard let rresults = rhs.results else { return false }
        return lresults == rresults
    }
}

internal extension PKAlbum {
    
    internal  func refreshSelectedCount() {
        let all = Set(assets.compactMap { $0.asset })
        let selected = Set(selectedAssets.compactMap { $0.asset })
        selectedCount = all.intersection(selected).count
    }

    internal func set(_ results: PHFetchResult<PHAsset>?, fetchAssets: Bool = false) {
        self.results = results
        guard fetchAssets else { return }
        self.fetchAssets()
    }
    
    internal func fetchAssets(_ force: Bool = false) {
        guard let results = results else { return }
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

extension PKAlbum {
    
    func coverAsset() -> PKAsset? {
        guard let asset = self.results?.lastObject else { return nil }
        return PKAsset(asset)
    }

    class func `default`(rule: PKPhotoPickingRule = PKPhotoConfig.default.pickingRule) -> PKAlbum {

        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        
        let options = PHFetchOptions()
        let onlyPhotos = (rule == PKPhotoPickingRule.singlePhoto) || (rule == PKPhotoPickingRule.multiplePhotos)
        let onlyVideos = (rule == PKPhotoPickingRule.singleVideo) || (rule == PKPhotoPickingRule.multipleVideos)
        if onlyPhotos { options.predicate = NSPredicate(format: "mediaType != %d", PHAssetMediaType.image.rawValue) }
        if onlyVideos { options.predicate = NSPredicate(format: "mediaType != %d", PHAssetMediaType.video.rawValue) }
        
        guard let collection = collections.firstObject else { return PKAlbum("", results: nil) }
        let results = PHAsset.fetchAssets(in: collection, options: options)
        return PKAlbum(collection.localizedTitle(), results: results, fetchAssets: true)
    }
}
