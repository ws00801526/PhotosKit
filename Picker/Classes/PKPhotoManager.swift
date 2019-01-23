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


public   typealias AlbumClosure         = ([PKAlbum]) -> Void
public   typealias ThumbClosure         = (UIImage?) -> Void
public   typealias ImageClosure         = (UIImage?) -> Void
public   typealias ImageDataClosure     = (Data?) -> Void
public   typealias VideoClosure         = (AVPlayerItem?, [AnyHashable : Any]?) -> Void
public   typealias PKAssetProgressClosure = PHAssetVideoProgressHandler

/// Methods for get albums
public extension PKPhotoManager {

    public func fetchAlbums(rule: PKPhotoPickingRule? = PKPhotoConfig.default.pickingRule,
                            ignoreEmptyAlbum ignored: Bool? = false,
                            closure: @escaping AlbumClosure) {

        DispatchQueue.global().async { [unowned self] in
            var albums: [PKAlbum] = []
            
            let options = PHFetchOptions()
            let onlyPhotos = (rule == PKPhotoPickingRule.singlePhoto) || (rule == PKPhotoPickingRule.multiplePhotos)
            let onlyVideos = (rule == PKPhotoPickingRule.singleVideo) || (rule == PKPhotoPickingRule.multipleVideos)
            if onlyPhotos { options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue) }
            if onlyVideos { options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue) }
            
            // get albums from smart collections
            let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            albums += self.mapAlbums(from: collections, options: options)
            
            // get albums from normal collections
            let otherCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            albums += self.mapAlbums(from: otherCollections, options: options)
            
            if ignored == true { albums = albums.filter { $0.count > 0 } }
            
            DispatchQueue.main.async { closure(albums) }
        }
    }
    
    fileprivate func mapAlbums(from collection: PHFetchResult<PHAssetCollection>, options: PHFetchOptions? = nil) -> [PKAlbum] {
        var albums: [PKAlbum] = []
        collection.enumerateObjects { (collection, _, _) in
            
            let subtype = collection.assetCollectionSubtype
            if subtype != .smartAlbumAllHidden, subtype.rawValue != PHAssetCollectionSubtype.smartAlbumRecentlyDeleted {
                let results = PHAsset.fetchAssets(in: collection, options: options)
                let album = PKAlbum(collection.localizedTitle(), results: results)
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary { albums.insert(album, at: 0) }
                else { albums.append(album) }
            }
        }
        return albums
    }
}

/// Internal Methods of get thumbs

extension PKPhotoManager {
    
    fileprivate static let imageManager        = PHCachingImageManager()
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

    internal class func startCachingThumbs(for assets: [PKAsset]) {
        guard assets.count > 0 else { return }
        cachingImageManager.startCachingImages(for: assets.map { $0.asset }, targetSize: PKPhotoConfig.thumbPixelSize(), contentMode: .aspectFill, options: defaultThumbOptions())
    }
    
    internal class func stopCachingThumbs(for assets: [PKAsset]? = nil) {
        if let assets = assets, assets.count > 0 {
            cachingImageManager.stopCachingImages(for: assets.map { $0.asset }, targetSize: PKPhotoConfig.thumbPixelSize(), contentMode: .aspectFill, options: defaultThumbOptions())
        } else {
            cachingImageManager.stopCachingImagesForAllAssets()
        }
    }
    
    internal class func requestThumb(for asset: PKAsset, closure: @escaping ThumbClosure) -> PHImageRequestID {
        return cachingImageManager.requestImage(for: asset.asset,
                                                targetSize: PKPhotoConfig.thumbPixelSize(),
                                                contentMode: .aspectFill,
                                                options: defaultThumbOptions())
        {   (image, _) in
            closure(image)
        }
    }
    
    internal class func requestCahcedThumb(for asset: PKAsset) -> UIImage? {
        
        let options = defaultThumbOptions()
        options.isSynchronous = true
        var ret: UIImage? = nil
        cachingImageManager.requestImage(for: asset.asset, targetSize: PKPhotoConfig.thumbPixelSize(), contentMode: .aspectFill, options: options) { (image, _) in
            ret = image
        }
        return ret
    }
    
    internal class func cancelRequest(with requestID: PHImageRequestID) {
        cachingImageManager.cancelImageRequest(requestID)
    }
}

/// Internal Methods of get images

internal extension PKPhotoManager {
    
    fileprivate class func `defaultImageOptions`(_ progressClosure: PKAssetProgressClosure? = nil) -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.resizeMode = .exact
        options.version = .current
        options.progressHandler = progressClosure
        return options
    }

    internal class func startCachingImage(for asset: PKAsset) {
        
        let scale = UIScreen.main.scale
        let size = asset.sizeThatFits().applying(CGAffineTransform.init(scaleX: scale, y: scale))
        cachingImageManager.startCachingImages(for: [asset.asset], targetSize: size, contentMode: .aspectFill, options: defaultImageOptions())
    }
    
    internal class func stopCachingImage(for asset: PKAsset? = nil) {

        if let asset = asset {
            let scale = UIScreen.main.scale
            let size = asset.sizeThatFits().applying(CGAffineTransform.init(scaleX: scale, y: scale))
            cachingImageManager.stopCachingImages(for: [asset.asset], targetSize: size, contentMode: .aspectFill, options: defaultImageOptions())
        } else {
            cachingImageManager.stopCachingImagesForAllAssets()
        }
    }

    internal class func requestImage(for asset: PKAsset, progressClosure: PKAssetProgressClosure? = nil, closure: @escaping ImageClosure) -> PHImageRequestID {
        
        let scale = UIScreen.main.scale
        var size = asset.sizeThatFits().applying(CGAffineTransform.init(scaleX: scale, y: scale))
        if case .video = asset.asset.mediaType { size = PHImageManagerMaximumSize }
        let options = defaultImageOptions(progressClosure)
        return cachingImageManager.requestImage(for: asset.asset, targetSize: size, contentMode: .aspectFill, options: options)
        {   (image, info) in
            closure(image)
        }
    }
    
    internal class func requestImageData(for asset: PKAsset, progressClosure: PKAssetProgressClosure? = nil, closure: @escaping ImageDataClosure) -> PHImageRequestID {
     
        let options = defaultImageOptions()
        options.resizeMode      = .none
        options.deliveryMode    = .highQualityFormat
        options.progressHandler = progressClosure
        return imageManager.requestImageData(for: asset.asset, options: nil, resultHandler: { (data, _, _, info) in
            if let _ = data { closure(data) }
            else if let URL = info?["PHImageFileURLKey"] as? URL, let data = try? Data(contentsOf: URL) { closure(data) }
            else { closure(nil) }
        })
    }
}

/// Internal Methods of get video

internal extension PKPhotoManager {
    
    internal class func requestVideo(for asset: PKAsset, progressClosure: PKAssetProgressClosure? = nil , closure: @escaping VideoClosure) -> PHImageRequestID {
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = progressClosure
        return imageManager.requestPlayerItem(forVideo: asset.asset, options: options, resultHandler: closure)
    }
    
    internal class func cancelVideoRequest(with requestID: PHImageRequestID) {
        imageManager.cancelImageRequest(requestID)
    }
}

/// Methods of get assets
public extension PKPhotoManager {
    
}


