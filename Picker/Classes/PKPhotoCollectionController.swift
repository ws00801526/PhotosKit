//  PKPhotoCollectionController.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/18
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoCollectionController
//  @version    <#class version#>
//  @abstract   <#class description#>

import UIKit
import Photos

class PKPhotoThumbStateButton : UIControl {
    
    lazy var stateView: UIImageView = {
        let imageView = UIImageView(image: PKPhotoConfig.localizedImage(with: "photo_list_mul_def"))
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: 22.5, height: 22.5)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12.0)
        return label
    }()
    
    override open var isSelected: Bool {
        didSet {
            if isSelected { stateView.image = PKPhotoConfig.localizedImage(with: "photo_list_mul_sel") }
            else { stateView.image = PKPhotoConfig.localizedImage(with: "photo_list_mul_def") }
        }
    }
    
    override var isEnabled: Bool {
        didSet { self.isHidden = !isEnabled }
    }
    
    required init(frame: CGRect, isLargeStyle: Bool = false) {
        super.init(frame: frame)
        addSubview(stateView)
        addSubview(titleLabel)
        isSelected = false
        
        if isLargeStyle {
            
            let center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
            stateView.bounds = CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            titleLabel.bounds = CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            stateView.center = center
            titleLabel.center = center
            titleLabel.font = UIFont.systemFont(ofSize: 14.0)
        } else {
            let x = bounds.width - stateView.bounds.width - 2.5
            stateView.frame = CGRect(origin: CGPoint(x: x, y: 2.5), size: stateView.bounds.size)
            titleLabel.frame = CGRect(origin: CGPoint(x: x, y: 2.5), size: stateView.bounds.size)
            titleLabel.font = UIFont.systemFont(ofSize: 12.0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

typealias PhotoReversalClosure = (_ cell: PKPhotoThumbCell) -> Void
class PKPhotoThumbCell : UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame:CGRect(origin: .zero, size: PKPhotoConfig.thumbSize()))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var stateButton: PKPhotoThumbStateButton = {
        let button = PKPhotoThumbStateButton(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
        button.addTarget(self, action: #selector(reverseState(of:)), for: .touchUpInside)
        return button
    }()
    
    lazy var durationLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.white
        label.minimumScaleFactor = 10.0
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: 12.0)
        return label
    }()
    
    lazy var disabledLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = contentView.bounds
        layer.backgroundColor = UIColor(white: 1, alpha: 0.7).cgColor
        return layer
    }()
    
    var closure: PhotoReversalClosure?
    @objc func reverseState(of button: PKPhotoThumbStateButton) {
        if let closure = closure { closure(self) }
    }
    
    func setup(serialNumber number: Int = 0, duration: TimeInterval = 0.0, isGIF: Bool = false) {
        if number <= 0 { stateButton.titleLabel.text = "" }
        else { stateButton.titleLabel.text = "\(number)" }
        
        durationLabel.isHidden = (duration <= 0.0 && isGIF == false)
        guard durationLabel.isHidden == false else { return }
        
        if duration > 0.0 {
            durationLabel.attributedText = durationAttribuetdString(with: duration)
        } else if isGIF {
            durationLabel.attributedText = gifAttribuetdString()
        } else {
            durationLabel.isHidden = true
        }
    }
    
    func setup(state: UIControl.State = .normal, multiple: Bool?) {
        
        if let multiple = multiple { stateButton.isHidden = !multiple }
        
        stateButton.isSelected = state == .selected
    
        if state == .disabled { contentView.layer.addSublayer(disabledLayer) }
        else { disabledLayer.removeFromSuperlayer() }
    }
    
    private func durationAttribuetdString(with duration: TimeInterval = 0.0) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = PKPhotoConfig.localizedImage(with: "photo_list_video")
        attachment.bounds = CGRect(origin: CGPoint(x: 0.0, y: -1.5), size: attachment.image?.size ?? .zero)
        let attributed = NSAttributedString.init(attachment: attachment).mutableCopy() as! NSMutableAttributedString
        attributed.append(NSAttributedString(string: "  "))
        attributed.append(NSAttributedString(string: duration.formatted()))
        return attributed.copy() as! NSAttributedString
    }
    
    private func gifAttribuetdString() -> NSAttributedString {
        let attributed = NSMutableAttributedString.init(string: "  GIF  ")
        attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 12.0), range: NSMakeRange(0, attributed.length))
        return attributed.copy() as! NSAttributedString
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(stateButton)
        contentView.addSubview(durationLabel)
        
        let x = contentView.bounds.width - stateButton.bounds.width
        let y = contentView.bounds.height - 25.0
        stateButton.frame = CGRect(origin: CGPoint(x: x, y: 0.0), size: stateButton.bounds.size)
        durationLabel.frame = CGRect(x: 5.0, y: y, width: contentView.bounds.width - 10.0, height: 25.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

internal let PKPhotoBottomViewHeight = 45.0
fileprivate let bottomMargin = CGFloat(PKPhotoBottomViewHeight + (iPhoneXStyle ? 34.0 : 0.0))
class PKPhotoBottomView: UIView {
    
    override open class var layerClass: AnyClass { return CAGradientLayer.self }
    private var gradientLayer : CAGradientLayer { return (self.layer as! CAGradientLayer) }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(_ allowsPickingOrigin: Bool = PKPhotoConfig.default.allowsPickingOrigin, isPreviewing: Bool = false) {
        let frame = CGRect(x: 0, y: UIScreen.main.bounds.height - bottomMargin, width: SCREEN_WIDTH, height: bottomMargin)
        self.isPreviewing = isPreviewing
        super.init(frame: frame)
        if isPreviewing == false { addSubview(previewButton) }
        if allowsPickingOrigin   { addSubview(originButton) }
        addSubview(sendButton)
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        
        let colors = [UIColor(hex6: 0x292e33), UIColor(hex6: 0x282c35), UIColor(hex6: 0x272b33)]
        if isPreviewing { gradientLayer.colors = colors.map { $0.withAlphaComponent(0.8) }.map { $0.cgColor } }
        else { gradientLayer.colors = colors.map { $0.cgColor } }
    }
    
    fileprivate let isPreviewing: Bool

    /// should pick origin photo
    internal var pickingOrigin: Bool {
        set { self.originButton.isSelected = newValue }
        get { return self.originButton.isHidden == false && self.originButton.isSelected }
    }
    
    func setup(numberOfPhotos number: Int = 0) {
        
        if number <= 0 { self.sendButton.setTitle(PKPhotoConfig.localizedString(for: "OK"), for: .normal) }
        else { self.sendButton.setTitle("\(PKPhotoConfig.localizedString(for: "OK"))(\(number))", for: .normal) }
        // send button is always enabled is previewing
        self.sendButton.isEnabled = (number > 0 || isPreviewing)
        self.previewButton.isEnabled = (number > 0 || isPreviewing)
    }
    
    lazy var previewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.setTitle(PKPhotoConfig.localizedString(for: "Preview"), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        button.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
        button.sizeToFit()
        button.frame = CGRect(x: 0.0, y: 0.0, width: Double(button.bounds.width), height: PKPhotoBottomViewHeight)
        return button
    }()
    
    lazy var originButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle(PKPhotoConfig.localizedString(for: "Full image"), for: .normal)
        button.setImage(PKPhotoConfig.localizedImage(with: "photo_original_def"), for: .normal)
        button.setImage(PKPhotoConfig.localizedImage(with: "photo_original_sel"), for: .selected)
        button.addTarget(self, action: #selector(updateSendButton), for: .touchUpInside)
        button.titleEdgeInsets   = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 0.0)
        button.imageEdgeInsets   = UIEdgeInsets(top: 0.0, left: -5.0, bottom: 0.0, right: 0.0)
        button.sizeToFit()
        button.frame = CGRect(origin: .zero, size: CGSize(width: Double(button.bounds.width + 30.0), height: PKPhotoBottomViewHeight))
        button.center = CGPoint(x: Double(SCREEN_WIDTH / 2.0), y: Double(PKPhotoBottomViewHeight / 2.0))
        return button
    }()
    
    @objc func updateSendButton() {
        self.originButton.isSelected = !self.originButton.isSelected
    }
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5.0
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
        button.setTitle(PKPhotoConfig.localizedString(for: "OK"), for: .normal)
        let size = CGSize(width: 1.0, height: 1.0)
        button.setBackgroundImage(UIImage.image(with: UIColor.grassGreen, size: size), for: .normal)
        button.setBackgroundImage(UIImage.image(with: UIColor.grassGreen.withAlphaComponent(0.5), size: size), for: .disabled)
        button.setBackgroundImage(UIImage.image(with: UIColor.grassGreen.withAlphaComponent(0.5), size: size), for: .highlighted)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        button.sizeToFit()
        let width = Double(max((button.bounds.width + 30.0), 60.0))
        let x = (Double(SCREEN_WIDTH) - width - 15.0)
        let height = PKPhotoBottomViewHeight - 8.0 * 2.0
        button.frame = CGRect(x: x, y: 8.0, width: width, height: height)
        return button
    }()
}

/// display photo.thumbs of album
class PKPhotoCollectionController : UIViewController {
    
    /// create default album while
    fileprivate var album: PKAlbum
    fileprivate var isBottomAvailable: Bool {
        let rule = configController().pickingRule
        return rule != .singlePhoto && rule != .singleVideo
    }
    
    lazy var collectionView: UICollectionView = {
        
        let bottomMargin = isBottomAvailable ? CGFloat(PKPhotoBottomViewHeight) : 0.0
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 10, *) { collectionView.prefetchDataSource = self }
        collectionView.backgroundColor = UIColor.white
        collectionView.alwaysBounceVertical = true
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottomMargin, right: 0.0)
        collectionView.contentInset = UIEdgeInsets(top: 5.0, left: 5.0, bottom: bottomMargin + 5.0, right: 5.0)
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
    
    lazy var bottomView: PKPhotoBottomView = {
        let view =  PKPhotoBottomView()
        view.setup(numberOfPhotos: album.selectedCount)
        view.previewButton.addTarget(self, action: #selector(previewSelectedAssets), for: .touchUpInside)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        if isBottomAvailable { view.addSubview(bottomView) }
        view.backgroundColor = UIColor.white
        
        navigationItem.title = album.name
        let cancelTitle = PKPhotoConfig.localizedString(for: "Cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(dismissPhotoController))
        
        // prefetch assets
        let maxLength = Int(ceil(UIScreen.main.bounds.height / PKPhotoConfig.thumbSize().height)) * PKPhotoConfig.default.numOfColumn
        let prefetchAssets = Array(album.assets.suffix(maxLength))
        PKPhotoManager.startCachingThumbs(for: prefetchAssets)
        
        // collection view scroll bottom
        DispatchQueue.main.async { [unowned self] in
            // scroll bottom latter in order to collectionView did layouted its subviews
            guard self.album.assets.count > 0 else { return }
            let indexPath = IndexPath(item: self.album.assets.count - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    deinit {
        PKPhotoManager.stopCachingThumbs()
    }
    
    required init(_ album: PKAlbum = PKAlbum.default()) {
        self.album = album
        self.album.fetchAssets()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // reload data in case of album.selectedAssets changed
        collectionView.reloadData()
        if isBottomAvailable { bottomView.setup(numberOfPhotos:album.selectedCount) }
        if configController().allowsPickingOrigin { bottomView.pickingOrigin = album.pickingOrigin }
    }
    
    @objc func previewSelectedAssets() {
        album.pickingOrigin = bottomView.pickingOrigin
        let preview = PKPhotoPreviewController(album: album, preferredSelectedAssets: true)
        navigationController?.pushViewController(preview, animated: true)
    }
}

@available(iOS 10.0, *)
extension PKPhotoCollectionController : UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let sorted = indexPaths.map { $0.item }.sorted()
        guard let first = sorted.first else { return }
        guard let last  = sorted.last  else { return }
        let assets = album.assets[first...last]
        PKPhotoManager.startCachingThumbs(for: Array(assets))
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let sorted = indexPaths.map { $0.item }.sorted()
        guard let first = sorted.first else { return }
        guard let last  = sorted.last  else { return }
        let assets = album.assets[first...last]
        PKPhotoManager.stopCachingThumbs(for: Array(assets))
    }
}

extension PKPhotoCollectionController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoThumbCell", for: indexPath) as! PKPhotoThumbCell
        let asset = album.assets[indexPath.row]
        
        let selectable = asset.canMultipleSelectable(with: pickingRule())
        if album.selectedAssets.contains(asset), let index = album.selectedAssets.firstIndex(of: asset) {
            cell.setup(serialNumber: (index + 1), duration: asset.asset.duration, isGIF: asset.isGIF)
            cell.setup(state: .selected, multiple: selectable)
        } else {
            let state = album.state(of: asset, maximumCount: maximumCount(), rule: pickingRule())
            cell.setup(serialNumber: 0, duration: asset.asset.duration, isGIF: asset.isGIF)
            cell.setup(state: state.0, multiple: selectable)
        }

        cell.imageView.setThumb(with: asset)
        cell.closure = { [unowned self] in

            guard let indexPath = self.collectionView.indexPath(for: $0) else { return }
            guard indexPath.item < self.album.assets.count else { return }
            let asset = self.album.assets[indexPath.item]
            
            if self.album.selectedAssets.contains(asset) {
                // just remove all exists assets and reload UI
                self.album.selectedAssets.removeAll(where: { $0 == asset })
                self.album.refreshSelectedCount()
                self.collectionView.reloadData()
            } else {
                
                // prevent too mach photo or videos picked
                let state = self.album.state(of: asset, maximumCount: self.maximumCount(), rule: self.pickingRule())
                guard case .normal = state.0 else {
                    if let error = state.1 {  self.configController().showError(error) }
                    return
                }

                // using deassign album.selectedAssets to trigger KVC and refresh selectedCount value
                // self.album.selectedAssets += [asset]
                
                // or just append it and refreshSelectedCount manually
                self.album.selectedAssets.append(asset)
                self.album.refreshSelectedCount()

                // refresh current cell stateUI
                guard let index = self.album.selectedAssets.firstIndex(of: asset) else { return }
                $0.setup(serialNumber: (index + 1))
                $0.setup(state: .selected, multiple: nil)
                $0.stateButton.stateView.showOscillatoryAnimation()
                
                // refresh other visiable cells state UI if needed
                let refreshable = self.album.selectedCount >= self.maximumCount()
                if (refreshable || self.pickingRule() == .multiplePhotosSingleVideo) {
                    let indexPaths = self.collectionView.indexPathsForVisibleItems.filter { $0 != indexPath }
                    self.collectionView.reloadItems(at: indexPaths)
                }
            }
            
            // refresh bottomView UI
            if self.isBottomAvailable { self.bottomView.setup(numberOfPhotos: self.album.selectedCount) }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let asset = album.assets[indexPath.item]
        let state = album.state(of: asset, maximumCount: maximumCount(), rule: pickingRule())
        
        guard [PHAssetMediaType.image, PHAssetMediaType.video].contains(asset.asset.mediaType) else { return }
        
        let selected = album.selectedAssets.contains(asset)
        guard (selected || (.normal == state.0)) else { return }

        switch pickingRule() {
        case .singlePhoto: fallthrough
        case .singleVideo:
            // TODO: just pick it
            print("will pick asset \(asset)")
            break
        case .multiplePhotos: fallthrough
        case .multipleVideos: fallthrough
        case .multiplePhotosVideos:  fallthrough
        case .multiplePhotosSingleVideo:
            album.pickingOrigin = bottomView.pickingOrigin
            let preview = PKPhotoPreviewController(album: album, initialAsset: asset)
            navigationController?.pushViewController(preview, animated: true)
            break
        }
    }
}
