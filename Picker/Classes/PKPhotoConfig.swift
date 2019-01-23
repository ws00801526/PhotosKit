//  PKPhotoConfig.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/16
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoConfig
//  @version    <#class version#>
//  @abstract   <#class description#>

import Foundation

internal let SCREEN_WIDTH = UIScreen.main.bounds.width
internal let SCREEN_HEIGHT = UIScreen.main.bounds.height

internal let iPhoneXStyle   =         iPhoneX || iPhoneXR || iPhoneXSM
internal let iPhone4S       =         (Int(SCREEN_WIDTH) == 480)  ||  (Int(SCREEN_HEIGHT) == 480)
internal let iPhone5S       =         (Int(SCREEN_WIDTH) == 568)  ||  (Int(SCREEN_HEIGHT) == 568)
internal let iPhone6S       =         (Int(SCREEN_WIDTH) == 667)  ||  (Int(SCREEN_HEIGHT) == 667)
internal let iPhonePlus     =         (Int(SCREEN_WIDTH) == 736)  ||  (Int(SCREEN_HEIGHT) == 736)
internal let iPhoneX        =         (Int(SCREEN_WIDTH) == 812)  ||  (Int(SCREEN_HEIGHT) == 812)
internal let iPhoneXR       =         (Int(SCREEN_WIDTH) == 828)  ||  (Int(SCREEN_HEIGHT) == 828)
internal let iPhoneXSM      =         (Int(SCREEN_WIDTH) == 1242) ||  (Int(SCREEN_HEIGHT) == 1242)

public enum PKPhotoPickingRule {
    
    /// only one photo is pickable, will ignored videos in albums
    case singlePhoto
    /// only one video is pickable, will ignored photos in albums
    case singleVideo
    /// multiple photos is pickable, , will ignored videos in albums
    case multiplePhotos
    /// multiple videos is pickable, , will ignored videos in albums
    case multipleVideos
    /// multiple photos & videos is pickable
    case multiplePhotosVideos
    /// multiple photos | one video is pickable
    case multiplePhotosSingleVideo
}

public enum PKPhotoError: String, Error {
    
    case unknown = "Unknown Error Happened"
    case overMaxCount = "Select a maximum of %zd photos"
    
    public var localizedDescription: String {
        return PKPhotoConfig.localizedString(for: rawValue)
    }
}

public class PKPhotoConfig {
    
    public static let `default` = PKPhotoConfig()
    
    //MARK: - properties of collection controller style
    
    public var albumCellHeight          :       CGFloat = 60.0
    public var numOfColumn              :       Int = 4
    public var itemSpacing              :       CGFloat = 5.0
    public var previewItemSpacing       :       CGFloat = 20.0
    
    //MARK: - properties of picking control
    
    public var pickingRule              = PKPhotoPickingRule.multiplePhotosSingleVideo
    public var allowsPickingOrigin      = true
    public var allowsJumpingSetting     = true
    public var preferredDefaultAlbum    = true
    public var ignoreEmptyAlbum         = false
    public var maximumCount             = 9
    public var minimumCount             = 0
    
    //MARK: - properties of lanunage and resources
    
    public var preferredLanguage: PKPhotoLanguage = .system {
        
        didSet {
            if case .system = self.preferredLanguage {
                self.languageBundle = Bundle(for: PKPhotoConfig.self)
            } else {
                let bundle = Bundle(for: PKPhotoConfig.self)
                guard let path = bundle.path(forResource: self.preferredLanguage.rawValue, ofType: "lproj") else { return }
                if let tmp = Bundle(path: path) { self.languageBundle = tmp }
            }
        }
    }
    
    public var languageBundle: Bundle = Bundle(for: PKPhotoConfig.self)
    public var resourcesBundle: Bundle = Bundle(for: PKPhotoConfig.self)
}

public enum PKPhotoLanguage: String {
    case system = "system"
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case vietnamese = "vi"
}

internal extension PKPhotoConfig {
    
    internal class func thumbSize() -> CGSize {
        
        let width = SCREEN_WIDTH - CGFloat(PKPhotoConfig.default.numOfColumn + 1) * PKPhotoConfig.default.itemSpacing
        let itemWidth = (floor(width / CGFloat(PKPhotoConfig.default.numOfColumn)))
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    internal class func thumbPixelSize() -> CGSize {
        return self.thumbSize().applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
    }
}

internal extension PKPhotoConfig {
    
    internal class func localizedString(for key: String, value: String? = nil, table tableName: String? = nil) -> String {
        return PKPhotoConfig.default.languageBundle.localizedString(forKey: key, value: value, table: tableName)
    }
    
    internal class func localizedImage(with name:String) -> UIImage? {
        return UIImage(named: name, in: PKPhotoConfig.default.resourcesBundle, compatibleWith: nil)
    }
}
