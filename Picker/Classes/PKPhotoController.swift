//  PKPhotoController.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/16
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoController
//  @version    <#class version#>
//  @abstract   <#class description#>

import UIKit
import Photos

public class PKPhotoController : UINavigationController {
    
    var preferredDefaultAlbum: Bool = true
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.isTranslucent = true
        navigationBar.tintColor = UIColor.textBlack
        
        let color = UIColor(hex6: 0xF0F0F0)
        let backgroundImage = UIImage.image(with: color, size: navigationBar.bounds.size)
        navigationBar.setBackgroundImage(backgroundImage, for: .default)
        navigationBar.shadowImage = UIImage()
        
        view.backgroundColor = UIColor.white
        self.checkAuthorizationStatus { [unowned self] in self.setupViewControllers($0) }
    }
}

/// some logic of Photos Auth
extension PKPhotoController {
    
    func setupViewControllers(_ isAuthorized: Bool = false) {
        
        var viewControllers: [UIViewController] = [PKPhotoListController(isAuthorized)]
        if isAuthorized, preferredDefaultAlbum { viewControllers.append(PKPhotoCollectionController()) }
        setViewControllers(viewControllers, animated: false)
    }
    
    func checkAuthorizationStatus(closure: @escaping ((Bool) -> Void)) {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                let succ = status == .authorized
                // while request auth completed it will be in other queue
                DispatchQueue.main.async { closure(succ) }
            }
            break
        case .authorized:
            closure(true)
            break
        case .denied: fallthrough
        case .restricted:
            closure(false)
        }
    }
}

extension UIViewController {

    @objc func dismissPhotoController() {
        
        if let presenting = presentingViewController { presenting.dismiss(animated: true, completion: nil) }
        else { dismiss(animated: true, completion: nil) }
    }
    
    @objc func jumpSetting() {
        guard let URL = URL(string: UIApplicationOpenSettingsURLString) else { return }
        if #available(iOS 10, *) {
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL)
        }
    }
}

/// display albums list
class PKPhotoListController : UIViewController {
    
    var albums: [PKAlbum] = []
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = PKPhotoConfig.default.albumCellHeight
        tableView.estimatedRowHeight = PKPhotoConfig.default.albumCellHeight
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.separator
        tableView.separatorInset = UIEdgeInsetsMake(0.0, PKPhotoConfig.default.albumCellHeight, 0.0, 0.0)
        tableView.register(PKPhotoAlbumCell.self, forCellReuseIdentifier: "AlbumCell")
        return tableView
    }()
    
    fileprivate var isAuthorized: Bool = false
    required init(_ isAuthorized: Bool = false) {
        self.isAuthorized = isAuthorized
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        navigationItem.title = PKPhotoConfig.localizedString(for: "Photos")
        let cancelTitle = PKPhotoConfig.localizedString(for: "Cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(dismissPhotoController))

        if (isAuthorized) {
            view.addSubview(tableView)
            PKPhotoManager.default.fetchAlbums(allowsPickVideo: true) { [unowned self] in
                self.albums = $0
                self.tableView.reloadData()
            }
        } else {
            showUnauthorizedMessage()
        }
    }
    
    func showUnauthorizedMessage() {
        
        let label = UILabel(frame: view.bounds.insetBy(dx: 30.0, dy: 100.0))
        
        let text = PKPhotoConfig.localizedString(for: "Allow %@ to access your album in \"Settings -> Privacy -> Photos\"")
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            label.text = String(format: text, arguments: [name])
        } else if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            label.text = String(format: text, arguments: [name])
        } else {
            label.text = String(format: text, arguments: [""])
        }
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.darkText
        view.addSubview(label)
        
        if PKPhotoConfig.default.allowsJumpingSetting {
            
            guard let settingURL = URL(string: UIApplicationOpenSettingsURLString) else { return }
            guard UIApplication.shared.canOpenURL(settingURL) else { return }
            let button = UIButton(type: .system)
            button.setTitle(PKPhotoConfig.localizedString(for: "Setting"), for: .normal)
            button.frame = CGRect(x: view.center.x - 50.0, y: view.center.y + 50.0, width: 100.0, height: 60.0)
            button.addTarget(self, action: #selector(jumpSetting), for: .touchUpInside)
            view.addSubview(button)
        }
    }

}

class PKPhotoAlbumCell : UITableViewCell {
    
    lazy var nameLabel: UILabel = {
        let origin = CGPoint(x: PKPhotoConfig.default.albumCellHeight + 10.0, y: 0.0)
        let size = CGSize(width: contentView.frame.width - 50.0 - PKPhotoConfig.default.albumCellHeight, height: PKPhotoConfig.default.albumCellHeight)
        let label = UILabel(frame: CGRect(origin: origin, size: size))
        label.textColor = UIColor.textBlack
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        return label
    }()

    lazy var avatarView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: PKPhotoConfig.default.albumCellHeight, height: PKPhotoConfig.default.albumCellHeight))
        imageView.backgroundColor = UIColor.separator
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        contentView.addSubview(avatarView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PKPhotoListController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as! PKPhotoAlbumCell
        cell.nameLabel.text = albums[indexPath.row].name
        guard let asset = albums[indexPath.row].coverAsset() else { return cell }
        PKPhotoManager.requestThumb(for: asset) { [unowned cell] in cell.avatarView.image = $0 }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < albums.count else { return }
        let album = albums[indexPath.row]
        let controller = PKPhotoCollectionController(album)
        navigationController?.pushViewController(controller, animated: true)
    }
}

class PKPhotoThumbCell : UICollectionViewCell {
 
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame:CGRect(origin: .zero, size: PKPhotoConfig.thumbSize()))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.backgroundColor = UIColor.separator
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// display photo.thumbs of album
class PKPhotoCollectionController : UIViewController {
    
    /// create default album while
    fileprivate var album: PKAlbum
    
    fileprivate let bottomMargin = (CGFloat)(iPhoneXStyle ? (40.0 + 34.0) : 40.0)
    
    lazy var collectionView: UICollectionView = {
        
        let frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: view.bounds.height - 45.0))
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 10, *) { collectionView.prefetchDataSource = self }
        collectionView.backgroundColor = UIColor.white
        collectionView.alwaysBounceVertical = true
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, bottomMargin, 0)
        collectionView.contentInset = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0 + bottomMargin, right: 5.0)
        collectionView.register(PKPhotoThumbCell.self, forCellWithReuseIdentifier: "PhotoThumbCell")
        return collectionView
    }()

    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = PKPhotoConfig.thumbSize()
        layout.minimumLineSpacing = 5.0
        layout.minimumInteritemSpacing = 5.0
        return layout
    }()
    
    lazy var bottomView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - bottomMargin, width: self.view.bounds.width, height: bottomMargin))
        view.backgroundColor = UIColor(hex6: 0x262E36)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        view.backgroundColor = UIColor.white
        
        navigationItem.title = album.name
        let cancelTitle = PKPhotoConfig.localizedString(for: "Cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(dismissPhotoController))

        // prefetch assets
        let maxLength = Int(ceil(UIScreen.main.bounds.height / PKPhotoConfig.thumbSize().height)) * PKPhotoConfig.default.numOfColumn
        let prefetchAssets = Array(album.assets.suffix(maxLength))
        PKPhotoManager.startCachingImages(for: prefetchAssets)
        
        // collection view scroll bottom
        DispatchQueue.main.async { [unowned self] in
            // scroll bottom latter in order to collectionView did layouted its subviews
            guard self.album.assets.count > 0 else { return }
            let indexPath = IndexPath(item: self.album.assets.count - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    deinit {
        PKPhotoManager.stopCachingImages()
    }
    
    required init(_ album: PKAlbum = PKAlbum.default()) {
        self.album = album
        self.album.fetchAssets()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 10.0, *)
extension PKPhotoCollectionController : UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let sorted = indexPaths.map { $0.item }.sorted()
        guard let first = sorted.first else { return }
        guard let last  = sorted.last  else { return }
        let assets = album.assets[first...last]
        PKPhotoManager.startCachingImages(for: Array(assets))
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let sorted = indexPaths.map { $0.item }.sorted()
        guard let first = sorted.first else { return }
        guard let last  = sorted.last  else { return }
        let assets = album.assets[first...last]
        PKPhotoManager.stopCachingImages(for: Array(assets))
    }
}

extension PKPhotoCollectionController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoThumbCell", for: indexPath) as! PKPhotoThumbCell
        let asset = album.assets[indexPath.row]
        PKPhotoManager.requestThumb(for: asset) { [weak cell] in cell?.imageView.image = $0 }
        return cell
    }
}


/// display photo.preview of album
class PKPhotoPreviewController : UIViewController {
    
}
