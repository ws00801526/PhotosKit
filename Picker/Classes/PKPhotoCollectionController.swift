//  PKPhotoCollectionController.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/18
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoCollectionController
//  @version    <#class version#>
//  @abstract   <#class description#>

import UIKit

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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stateView)
        addSubview(titleLabel)
        isSelected = false
        
        let x = bounds.width - stateView.bounds.width - 2.5
        stateView.frame = CGRect(origin: CGPoint(x: x, y: 2.5), size: stateView.bounds.size)
        titleLabel.frame = CGRect(origin: CGPoint(x: x, y: 2.5), size: stateView.bounds.size)
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
    
    func setup(serialNumber number: Int = 0, duration: TimeInterval = 0.0) {
        if number <= 0 { stateButton.titleLabel.text = "" }
        else { stateButton.titleLabel.text = "\(number)" }
        
        durationLabel.isHidden = duration <= 0.0
        guard durationLabel.isHidden == false else { return }
        
        let attachment = NSTextAttachment()
        attachment.image = PKPhotoConfig.localizedImage(with: "photo_list_video")
        attachment.bounds = CGRect(origin: CGPoint(x: 0.0, y: -1.5), size: attachment.image?.size ?? .zero)
        let attributed = NSAttributedString.init(attachment: attachment).mutableCopy() as! NSMutableAttributedString
        attributed.append(NSAttributedString(string: "  "))
        attributed.append(NSAttributedString(string: duration.formatted()))
        durationLabel.attributedText = attributed
    }
    
    func setup(state: UIControl.State = .normal, multiple: Bool?) {
        
        if let multiple = multiple { stateButton.isHidden = !multiple }
        
        stateButton.isSelected = state == .selected
    
        if state == .disabled {
            contentView.layer.addSublayer(disabledLayer)
        } else {
            disabledLayer.removeFromSuperlayer()
        }
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

fileprivate let PKPhotoBottomViewHeight = 45.0
fileprivate let PKPhotoBottomViewItemSpacing = 8.0
fileprivate let bottomMargin = CGFloat(PKPhotoBottomViewHeight + (iPhoneXStyle ? 34.0 : 0.0))
class PKPhotoBottomView: UIView {
    
    override open class var layerClass: AnyClass { return CAGradientLayer.self }
    private var gradientLayer : CAGradientLayer { return (self.layer as! CAGradientLayer) }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(_ allowsPickingOrigin: Bool = PKPhotoConfig.default.allowsPickingOrigin, isPreviewing: Bool = false) {
        let frame = CGRect(x: 0, y: UIScreen.main.bounds.height - bottomMargin, width: SCREEN_WIDTH, height: bottomMargin)
        super.init(frame: frame)
        self.isPreviewing = isPreviewing
        backgroundColor = UIColor.darkSlateGray
        if isPreviewing == false { addSubview(previewButton) }
        if allowsPickingOrigin   { addSubview(originButton) }
        addSubview(sendButton)
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.colors = [UIColor(hex6: 0x292e33), UIColor(hex6: 0x282c35), UIColor(hex6: 0x272b33)].map { $0.cgColor }
    }
    
    /// should pick origin photo
    fileprivate var pickingOrigin: Bool { return self.originButton.isHidden == false && self.originButton.isSelected }
    
    fileprivate var isPreviewing = false
    fileprivate func setup(numberOfPhotos number: Int = 0) {
        
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
        let height = PKPhotoBottomViewHeight - PKPhotoBottomViewItemSpacing * 2.0
        button.frame = CGRect(x: x, y: PKPhotoBottomViewItemSpacing, width: width, height: height)
        return button
    }()
}

/// display photo.thumbs of album
class PKPhotoCollectionController : UIViewController {
    
    /// create default album while
    fileprivate var album: PKAlbum
    
    lazy var collectionView: UICollectionView = {
        
        let frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: view.bounds.height - 45.0))
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 10, *) { collectionView.prefetchDataSource = self }
        collectionView.backgroundColor = UIColor.white
        collectionView.alwaysBounceVertical = true
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: CGFloat(PKPhotoBottomViewHeight), right: 0.0)
        collectionView.contentInset = UIEdgeInsets(top: 5.0, left: 5.0, bottom: CGFloat(5.0 + PKPhotoBottomViewHeight), right: 5.0)
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
        
        if album.selectedAssets.contains(asset), let index = album.selectedAssets.firstIndex(of: asset) {
            cell.setup(serialNumber: (index + 1), duration: asset.asset.duration)
            cell.setup(state: .selected, multiple: isMultipleSelectable(of: asset))
        } else {
            cell.setup(serialNumber: 0, duration: asset.asset.duration)
            cell.setup(state: state(of: asset).0, multiple: isMultipleSelectable(of: asset))
        }

        cell.imageView.setAssetThumb(with: asset)
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
                let state = self.state(of: asset)
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
                let refreshable = self.album.selectedCount >= self.configController().maximumCount
                if (refreshable || self.configController().pickingRule == .multiplePhotosSingleVideo) {
                    let indexPaths = self.collectionView.indexPathsForVisibleItems.filter { $0 != indexPath }
                    self.collectionView.reloadItems(at: indexPaths)
                }
            }
            
            // refresh bottomView UI
            self.bottomView.setup(numberOfPhotos: self.album.selectedCount)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let asset = album.assets[indexPath.item]
        let state = self.state(of: asset)
        
        let selected = album.selectedAssets.contains(asset)
        guard (selected || (.normal == state.0)) else { return }

        switch configController().pickingRule {
        case .singlePhoto: fallthrough
        case .singleVideo:
            // TODO: just pick it
            print("will pick asset \(asset)")
            break
        case .multiplePhotos: fallthrough
        case .multipleVideos: fallthrough
        case .multiplePhotosVideos:
            // TODO: will push in preview
            print("will preview this asset \(asset)")
            break
        case .multiplePhotosSingleVideo:
            if (asset.asset.mediaType == .image) || (asset.asset.mediaType == .video) {
                print("will preview this asset \(asset)")
            }
            break
        }
        
    }
}

internal typealias PKPhotoState = (UIControl.State, PKPhotoError?)
extension PKPhotoCollectionController {
    
    func isMultipleSelectable(of asset: PKAsset) -> Bool {
        
        switch configController().pickingRule {
        
        case .singleVideo               : fallthrough
        case .singlePhoto               : return false
            
        case .multipleVideos            : fallthrough
        case .multiplePhotos            : fallthrough
        case .multiplePhotosVideos      : return true
            
        case .multiplePhotosSingleVideo : return asset.asset.mediaType == .image
        }
    }
    
    func state(of asset: PKAsset) -> PKPhotoState {
        var selectable: Bool = false
        switch configController().pickingRule {
            
        case .singleVideo               : fallthrough
        case .singlePhoto               : selectable = album.selectedCount <= 0
            
        case .multipleVideos            : fallthrough
        case .multiplePhotos            : fallthrough
        case .multiplePhotosVideos      : selectable = album.selectedCount < configController().maximumCount
            
        case .multiplePhotosSingleVideo :
            if case .video = asset.asset.mediaType {
                selectable = album.selectedCount <= 0
            } else if case .image = asset.asset.mediaType {
                selectable = album.selectedCount < configController().maximumCount
            }
        }
        return (selectable ? .normal : .disabled, selectable ? nil : PKPhotoError.overMaxCount)
    }
}
