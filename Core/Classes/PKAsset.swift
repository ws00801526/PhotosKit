//  PKAsset.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/15
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKAsset

import Foundation
import Photos

public struct PKAsset {
    
}

public struct PKAlbum {
    
    public var name: String = ""
    public var count: Int = 0
    public var result: PHFetchResult<PHAsset>?
    
    internal var assets: [PKAsset] = []
    internal var selectedAssets: [PKAsset] = []
}
