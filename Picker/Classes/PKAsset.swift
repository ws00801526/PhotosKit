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
    public var isGIF: Bool = false
    
    private struct ValueKey {
        static let identifier = "uniformTypeIdentifier"
    }
    
    required init(_ asset: PHAsset) {
        self.asset = asset
    
        guard case .image = asset.mediaType else { return }
        
//        this is the correct way to get correct type identifier, but its too expensive cost while photos is too much
//        let resources = PHAssetResource.assetResources(for: asset)
//        self.isGIF = resources.map { $0.uniformTypeIdentifier }.contains("com.compuserve.gif")
        
        if let identifier = asset.value(forKey: ValueKey.identifier) as? String, identifier == "com.compuserve.gif" {
            self.isGIF = true
        }
    }
    
    public var description: String { return "\(asset)" }
    public var debugDescription: String { return "\(asset)" }
}

extension PKAsset : Equatable {
    public static func == (lhs: PKAsset, rhs: PKAsset) -> Bool {
        return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}

internal extension PKAsset {
    
    /// calculate the suitable size for container 
    func sizeThatFits(_ size: CGSize = CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT)) -> CGSize {
        
        guard size != .zero                               else { return CGSize(width: SCREEN_WIDTH, height: 300.0) }
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else { return CGSize(width: SCREEN_WIDTH, height: 300.0) }
        
        let scale           =   CGFloat(2.0)
        let widthPercent    =   CGFloat(asset.pixelWidth)  / size.width
        let heightPercent   =   CGFloat(asset.pixelHeight) / size.height

        if widthPercent <= scale, heightPercent <= scale, !(asset.mediaType == .video || isGIF) {
            return CGSize(width: ceil(CGFloat(asset.pixelWidth) / scale), height: ceil(CGFloat(asset.pixelHeight) / scale))
        } else {
            if widthPercent > heightPercent {
                return CGSize(width: size.width, height: ceil(CGFloat(asset.pixelHeight) / widthPercent))
            } else {
                return CGSize(width: ceil(CGFloat(asset.pixelWidth) / heightPercent), height: size.height)
            }
        }
    }
    
    internal func canMultipleSelectable(with rule: PKPhotoPickingRule = PKPhotoConfig.default.pickingRule) -> Bool {
        switch rule {
            
        case .singleVideo               : fallthrough
        case .singlePhoto               : return false
            
        case .multipleVideos            : fallthrough
        case .multiplePhotos            : fallthrough
        case .multiplePhotosVideos      : return true
            
        case .multiplePhotosSingleVideo : return asset.mediaType == .image
        }
    }
}

public class PKAlbum : CustomStringConvertible, CustomDebugStringConvertible {
    
    public var name: String = ""
    
    public var count: Int { return results?.count ?? 0 }
    public var selectedCount: Int = 0
    
    // MARK: internal properties
    internal var pickingOrigin: Bool = false
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
        
        guard let results = self.results else { return }
        guard (force || self.assets.count != results.count) else { return }
        var assets: [PKAsset] = []
        results.enumerateObjects { (asset, _, _) in assets.append(PKAsset(asset)) }
        self.assets = assets
    }
    
    internal typealias PKPhotoState = (UIControl.State, PKPhotoError?)
    internal func state(of asset: PKAsset,
                        maximumCount: Int = PKPhotoConfig.default.maximumCount,
                        rule: PKPhotoPickingRule = PKPhotoConfig.default.pickingRule) -> PKPhotoState {
        var selectable: Bool = false
        switch rule {
            
        case .singleVideo               : fallthrough
        case .singlePhoto               : selectable = selectedCount <= 0
            
        case .multipleVideos            : fallthrough
        case .multiplePhotos            : fallthrough
        case .multiplePhotosVideos      : selectable = selectedCount < maximumCount
            
        case .multiplePhotosSingleVideo :
            if case .video = asset.asset.mediaType {
                selectable = selectedCount <= 0
            } else if case .image = asset.asset.mediaType {
                selectable = selectedCount < maximumCount
            }
        }
        return (selectable ? .normal : .disabled, selectable ? nil : PKPhotoError.overMaxCount)
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
        if onlyPhotos { options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue) }
        if onlyVideos { options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue) }
        
        guard let collection = collections.firstObject else { return PKAlbum("", results: nil) }
        let results = PHAsset.fetchAssets(in: collection, options: options)
        return PKAlbum(collection.localizedTitle(), results: results, fetchAssets: true)
    }
}
