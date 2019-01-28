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
    
    public var preferredDefaultAlbum    = PKPhotoConfig.default.preferredDefaultAlbum
    public var pickingRule              = PKPhotoConfig.default.pickingRule
    public var allowsPickingOrigin      = PKPhotoConfig.default.allowsPickingOrigin
    public var ignoreEmptyAlbum         = PKPhotoConfig.default.ignoreEmptyAlbum
    public var maximumCount             = PKPhotoConfig.default.maximumCount
    public var minimumCount             = PKPhotoConfig.default.minimumCount
    public var previewItemSpacing       = PKPhotoConfig.default.previewItemSpacing
    public var allowsPreviewThumb       = PKPhotoConfig.default.allowsPreviewThumb

    fileprivate var pan: UIPanGestureRecognizer? = nil
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.isTranslucent = true
        navigationBar.barStyle = .default
        navigationBar.tintColor = UIColor.textBlack
        
        let color = UIColor(hex6: 0xF0F0F0)
        // should consider status bar height while set background image for navigation bar before iOS10
        let height = CGFloat((iPhoneXStyle ? 44.0 : 20.0) + 44.0)
        let backgroundImage = UIImage.image(with: color, size: CGSize(width: SCREEN_WIDTH, height: height))
        navigationBar.setBackgroundImage(backgroundImage, for: .default)
        navigationBar.shadowImage = UIImage()
        
        view.backgroundColor = UIColor.white
        self.checkAuthorizationStatus { [unowned self] in self.setupViewControllers($0) }
        
        delegate = self
        
        guard let gesture = interactivePopGestureRecognizer else { return }
        // if pan gesture is already exists, donot add it again
        if let pan = self.pan, let gestures = gesture.view?.gestureRecognizers, gestures.contains(pan) { return }
        let pan = UIPanGestureRecognizer(target: gesture.delegate, action: Selector(("handleNavigationTransition:")))
        pan.delegate = self
        gesture.view?.addGestureRecognizer(pan)
        gesture.isEnabled = false
        self.pan = pan
    }
    
    internal let verticalTransition = PKVerticalInteractiveTransition()
}

extension PKPhotoController: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        if let gesture = pan, gesture == gestureRecognizer {
//            if otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) { return true }
//            if let view = otherGestureRecognizer.view as? UIScrollView { return view.contentOffset.x <= 0 }
//        }
//        return false
//    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == pan {
            // Ignore when no view controller is pushed into navigation stack
            guard viewControllers.count >= 2 else { return false }
            
            // Ignore translation.x > pop gesture offset
            let location = gestureRecognizer.location(in: topViewController?.view)
            guard location.x <= 50.0 else { return false }
            
            // Ignore pan gestrue is transitioning
            if let transitioning = value(forKey: "_isTransitioning") as? Bool, transitioning { return false }
        }

        return true
    }
}

extension PKPhotoController : UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if case .push = operation, fromVC.isKind(of: PKPhotoCollectionController.self), toVC.isKind(of: PKPhotoPreviewController.self) {
            return PKInteractivePushAnimation()
        }
        
        if case .pop = operation, fromVC.isKind(of: PKPhotoPreviewController.self), toVC.isKind(of: PKPhotoCollectionController.self) {
            if verticalTransition.interactiveInProgress { return PKInteractivePopAnimation(isVertical: true) }
            return PKInteractivePopAnimation()
        }
        
        return nil
    }
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return verticalTransition.interactiveInProgress ? verticalTransition : nil
    }
}

extension UIViewController {
    
    func configController() -> PKPhotoController {

        if let controller = self as? PKPhotoController                         { return controller }
        if let controller = navigationController as? PKPhotoController         { return controller }
        return PKPhotoController()
    }

    /// get pickingRule from configController
    func pickingRule() -> PKPhotoPickingRule {
        return configController().pickingRule
    }
    
    /// get maximumCount from configController
    func maximumCount() -> Int {
        return configController().maximumCount
    }
}

extension PKPhotoController {
    func showError(_ error: PKPhotoError) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        switch error {
        case .overMaxCount: alert.message = String(format: error.localizedDescription, arguments: [maximumCount])
        default: alert.message = error.localizedDescription
        }
        let action = UIAlertAction(title: PKPhotoConfig.localizedString(for: "OK"), style: .default, handler: nil)
        alert.addAction(action)
        showDetailViewController(alert, sender: nil)
    }
}

/// some logic of Photos Auth
extension PKPhotoController {
    
    func setupViewControllers(_ isAuthorized: Bool = false) {
        
        var viewControllers: [UIViewController] = [PKPhotoListController(isAuthorized)]
        if isAuthorized, preferredDefaultAlbum { viewControllers.append(PKPhotoCollectionController()) }
        setViewControllers(viewControllers, animated: false)
        
        let backItem = UIBarButtonItem(title: PKPhotoConfig.localizedString(for: "Photos"), style: .plain, target: nil, action: nil)
        viewControllers.first!.navigationItem.backBarButtonItem = backItem
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
        tableView.separatorInset = UIEdgeInsets(top: 0.0, left: PKPhotoConfig.default.albumCellHeight, bottom: 0.0, right: 0.0)
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
            
            PKPhotoManager.default.fetchAlbums(rule: pickingRule(), ignoreEmptyAlbum: configController().ignoreEmptyAlbum)
            {   [unowned self] in
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
        label.textColor = UIColor.textBlack
        view.addSubview(label)
        
        if PKPhotoConfig.default.allowsJumpingSetting {
            
            guard let settingURL = URL(string: UIApplication.openSettingsURLString) else { return }
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
        imageView.clipsToBounds = true
        imageView.contentMode = .center
        imageView.image = PKPhotoConfig.localizedImage(with: "album_placeholder")
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        contentView.addSubview(nameLabel)
        contentView.addSubview(avatarView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.contentMode = .center
        avatarView.image = PKPhotoConfig.localizedImage(with: "album_placeholder")
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
        
        let text = "\(albums[indexPath.row].name)  (\(albums[indexPath.row].count))"
        let attributed = NSMutableAttributedString(string: text)
        let range = NSMakeRange(albums[indexPath.row].name.count, text.count - albums[indexPath.row].name.count)
        attributed.addAttribute(.foregroundColor, value: UIColor.textGray, range: range)
        attributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0), range: range)
        cell.nameLabel.attributedText = attributed
        
        guard let asset = albums[indexPath.row].coverAsset() else { return cell }
        cell.avatarView.setThumb(with: asset, placeholder: PKPhotoConfig.localizedImage(with: "album_placeholder"))
        {   [weak cell] in
            guard let _ = cell else { return }
            cell?.avatarView.contentMode = $0 == nil ? .center : .scaleAspectFill
        }
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
