//  PKPhotoManagerTests.swift
//  PhotosKit
//
//  Created by  XMFraker on 2019/1/16
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoManagerTests
//  @version    <#class version#>
//  @abstract   <#class description#>

import Quick
import Nimble
@testable import PhotosKit

class PKPhotoConfigSpec: QuickSpec {
    
    override func spec() {
        
        describe("test language resources") {
            
            it("test preferred", closure: {
                
                var ok = PKPhotoConfig.localizedString(for: "OK")
                expect(ok).to(equal("确定"))
                
                PKPhotoConfig.default.preferredLanguage = .english
                ok = PKPhotoConfig.localizedString(for: "OK")
                expect(ok).to(equal("OK"))
                
                PKPhotoConfig.default.preferredLanguage = .chineseSimplified
                ok = PKPhotoConfig.localizedString(for: "OK")
                expect(ok).to(equal("确定"))
                
                PKPhotoConfig.default.preferredLanguage = .chineseTraditional
                ok = PKPhotoConfig.localizedString(for: "OK")
                expect(ok).to(equal("確定"))
                
                PKPhotoConfig.default.preferredLanguage = .vietnamese
                ok = PKPhotoConfig.localizedString(for: "OK")
                expect(ok).to(equal("Xác nhận"))
            })
        }
    }
}

class PKPhotoManagerSpec: QuickSpec {
    
    override func spec() {
        
        var albums: [PKAlbum] = []

        describe("test of PKPhotoManager") {
            

            beforeEach { albums = [] }
            afterEach { print("albums after fetch \(albums)") }
            context("fetch albums", {
                
                it("fetch all albums", closure: {
                    PKPhotoManager.default.fetchAlbums { albums = $0 }
                    expect(albums.count).toEventually(beGreaterThanOrEqualTo(1))
                })
                
                context("fetch all albums and ignore empty album", {
                    
                    afterEach {
                        expect(albums.count).toEventually(beGreaterThanOrEqualTo(2))
                    }
                    
                    it("fetch unempty albums", closure: {
                        PKPhotoManager.default.fetchAlbums(allowsPickVideo: true, allowsPickPhoto: true, ignoreEmptyAlbum: true, closure:  { albums = $0 })
                    })
                    
                    it("fetch unempty video albums", closure: {
                        PKPhotoManager.default.fetchAlbums(allowsPickVideo: true, allowsPickPhoto: false, ignoreEmptyAlbum: true, closure:  { albums = $0 })
                    })
                    
                    it("fetch unempty photo albums", closure: {
                        PKPhotoManager.default.fetchAlbums(ignoreEmptyAlbum: true, closure:  { albums = $0 })
                    })
                })
            })
        }
    }
}
