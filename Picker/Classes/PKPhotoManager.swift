//  PKPhotoManager.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/16
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoManager
//  @version    <#class version#>
//  @abstract   <#class description#>

import Photos

public class PKPhotoManager {
    
    static public let `default` = PKPhotoManager()
    
    func xxxx() {
        // do nothing
    }
}

/// Auth status of Photo Library
public extension PKPhotoManager {

}

fileprivate extension PHAssetCollectionSubtype {
    static let smartAlbumRecentlyDeleted: Int = 1000000201
}

public   typealias AlbumClosure = (_ albums: [PKAlbum]) -> Void
internal typealias ThumbClosure = (_ thumb: UIImage?) -> Void

/// Methods for get albums
public extension PKPhotoManager {

    public func fetchAlbums(allowsPickVideo: Bool = false, allowsPickPhoto: Bool = true, ignoreEmptyAlbum: Bool = false, closure: @escaping AlbumClosure) {

        DispatchQueue.global().async { [unowned self] in
            var albums: [PKAlbum] = []
            
            let options = PHFetchOptions()
            if allowsPickPhoto == false { options.predicate = NSPredicate(format: "mediaType != %d", PHAssetMediaType.image.rawValue) }
            if allowsPickVideo == false { options.predicate = NSPredicate(format: "mediaType != %d", PHAssetMediaType.video.rawValue) }
            
            // get albums from smart collections
            let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            albums += self.mapAlbums(from: collections, options: options)
            
            // get albums from normal collections
            let otherCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            albums += self.mapAlbums(from: otherCollections, options: options)
            
            if ignoreEmptyAlbum == true { albums = albums.filter { $0.count > 0 } }
            
            DispatchQueue.main.async { closure(albums) }
        }
    }
    
    fileprivate func mapAlbums(from collection: PHFetchResult<PHAssetCollection>, options: PHFetchOptions? = nil) -> [PKAlbum] {
        var albums: [PKAlbum] = []
        collection.enumerateObjects { (collection, _, _) in
            
            let subtype = collection.assetCollectionSubtype
            if subtype != .smartAlbumAllHidden, subtype.rawValue != PHAssetCollectionSubtype.smartAlbumRecentlyDeleted {
                let results = PHAsset.fetchAssets(in: collection, options: options)
                let album = PKAlbum(collection.localizedTitle, results: results)
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary { albums.insert(album, at: 0) }
                else { albums.append(album) }
            }
        }
        return albums
    }
}


public extension PKPhotoManager {
    
}

/// Internal Methods of get thumbs

extension PKPhotoManager {
    
    fileprivate static let cachingImageManager = PHCachingImageManager()
    fileprivate static let thumbRequestOptions = PHImageRequestOptions()
    
    fileprivate class func `defaultThumbOptions`() -> PHImageRequestOptions {
        thumbRequestOptions.deliveryMode = .highQualityFormat
        thumbRequestOptions.isNetworkAccessAllowed = true
        thumbRequestOptions.isSynchronous = false
        thumbRequestOptions.resizeMode = .exact
        thumbRequestOptions.version = .current
        return thumbRequestOptions
    }
    
    internal class func startCachingImages(for assets: [PKAsset]) {
        guard assets.count > 0 else { return }
        cachingImageManager.startCachingImages(for: assets.map { $0.asset }, targetSize: PKPhotoConfig.thumbPixelSize(), contentMode: .aspectFill, options: defaultThumbOptions())
    }
    
    internal class func stopCachingImages(for assets: [PKAsset]? = nil) {
        if let assets = assets, assets.count > 0 {
            cachingImageManager.stopCachingImages(for: assets.map { $0.asset }, targetSize: PKPhotoConfig.thumbPixelSize(), contentMode: .aspectFill, options: defaultThumbOptions())
        } else {
            cachingImageManager.stopCachingImagesForAllAssets()
        }
    }
    
    internal class func requestThumb(for asset: PKAsset, closure: @escaping ThumbClosure) {
        cachingImageManager.requestImage(for: asset.asset, targetSize: PKPhotoConfig.thumbPixelSize(), contentMode: .aspectFill, options: defaultThumbOptions()) { (image, _) in
            closure(image)
        }
    }
}

/// Methods of get assets
public extension PKPhotoManager {
    
}


