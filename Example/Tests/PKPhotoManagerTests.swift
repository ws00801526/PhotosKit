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


class PKExtensionSepc: QuickSpec {
    
    override func spec() {
        describe("test timeinterval") {
            
            it("test video duration format", closure: {
                let a = TimeInterval(30.0).formatted()
                expect(a).to(equal("00:30"))
                
                let b = TimeInterval(30.9).formatted()
                expect(b).to(equal("00:31"))
                
                let f = TimeInterval(30.3).formatted()
                expect(f).to(equal("00:30"))
                
                let c = TimeInterval(63).formatted()
                expect(c).to(equal("01:03"))
                
                let d = TimeInterval(3603).formatted()
                expect(d).to(equal("01:00:03"))

                let e = TimeInterval(3903).formatted()
                expect(e).to(equal("01:05:03"))
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
                        PKPhotoManager.default.fetchAlbums(rule: .multiplePhotosVideos, ignoreEmptyAlbum: true, closure:  { albums = $0 })
                    })
  
                    it("fetch unempty video albums", closure: {
                        PKPhotoManager.default.fetchAlbums(rule: .multipleVideos, ignoreEmptyAlbum: true, closure:  { albums = $0 })
                    })
  
                    it("fetch unempty photo albums", closure: {
                        PKPhotoManager.default.fetchAlbums(ignoreEmptyAlbum: true, closure:  { albums = $0 })
                    })
                })
            })
        }
    }
}
