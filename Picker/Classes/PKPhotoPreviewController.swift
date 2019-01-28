//  PKPhotoPreviewController.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/19
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKPhotoPreviewController

import UIKit
import Photos
import AVFoundation

class PKPhotoPreviewTopView : UIView {
    
    override open class var layerClass: AnyClass { return CAGradientLayer.self }
    private var gradientLayer : CAGradientLayer { return (self.layer as! CAGradientLayer) }
    
    lazy var stateButton: PKPhotoThumbStateButton = {
        let y      = CGFloat(iPhoneXStyle ? 34.0 : 0.0)
        let height = CGFloat(iPhoneXStyle ? 54.0 : 64.0)
        let frame = CGRect(x: SCREEN_WIDTH - height, y: y, width: 55.0, height: height)
        let button = PKPhotoThumbStateButton(frame: frame, isLargeStyle: true)
        button.addTarget(self, action: #selector(reverseState(of:)), for: .touchUpInside)
        return button
    }()
    
    lazy var backButton: UIButton = {
        let y      = CGFloat(iPhoneXStyle ? 34.0 : 0.0)
        let height = CGFloat(iPhoneXStyle ? 54.0 : 64.0)
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: y, width: 55.0, height: height)
        button.setImage(PKPhotoConfig.localizedImage(with: "photo_nav_back_white"), for: .normal)
        return button
    }()
    
    func setup(serialNumber number: Int, state: UIControl.State = .normal, multiple: Bool? = nil) {
        
        if let multiple = multiple { stateButton.isHidden = !multiple }
        stateButton.isSelected = state == .selected
        if number <= 0 { stateButton.titleLabel.text = "" }
        else { stateButton.titleLabel.text = "\(number)" }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // setup gradient layer
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        let colors = [UIColor(hex6: 0x292e33), UIColor(hex6: 0x282c35), UIColor(hex6: 0x272b33)]
        gradientLayer.colors = colors.map { $0.withAlphaComponent(0.8) }.map { $0.cgColor }
        
        addSubview(stateButton)
        addSubview(backButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var closure: ((_ view: PKPhotoPreviewTopView) -> Void)?
    @objc func reverseState(of button: PKPhotoThumbStateButton) {
        if let closure = closure { closure(self) }
    }
}

protocol PKPhotoPreviewThumbViewDelegate {
    func numberOfItems(in thumbView: PKPhotoPreviewThumbView) -> Int
    func thumbView(_ thumbView: PKPhotoPreviewThumbView, cellForItemAt at: Int) -> UICollectionViewCell
    func thumbView(_ thumbView: PKPhotoPreviewThumbView, didSelectItemAt at: Int)
}

class PKPhotoPreviewThumbView : UIView {
    
    override open class var layerClass: AnyClass { return CAGradientLayer.self }
    private var gradientLayer : CAGradientLayer { return (self.layer as! CAGradientLayer) }
    private var delegate: PKPhotoPreviewThumbViewDelegate
    
    lazy var collectionView: UICollectionView = {
        
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.isMultipleTouchEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PKThumbPreviewCell.self, forCellWithReuseIdentifier: "PKThumbPreviewCell")
        return collectionView
    }()
    
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        let width = floor(bounds.height - 30.0)
        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumLineSpacing = 15.0
        layout.minimumInteritemSpacing = 15.0
        return layout
    }()
    
    fileprivate var selectedIndex: Int? = nil {
        didSet {
            DispatchQueue.main.async {
                
                if let index = self.selectedIndex, index < self.delegate.numberOfItems(in: self) {
                    let indexPath = IndexPath(item: index, section: 0)
                    self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                } else if let selected = self.collectionView.indexPathsForSelectedItems {
                    selected.forEach { [unowned self] in self.collectionView.deselectItem(at: $0, animated: false) }
                }
            }
        }
    }
    
    func deleteItems(at indexPaths: [IndexPath]) {
        collectionView.deleteItems(at: indexPaths)
    }
    
    func insertItems(at indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
    }
    
    func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        collectionView.performBatchUpdates(updates, completion: completion)
    }
    
    required init(frame: CGRect, delegate: PKPhotoPreviewThumbViewDelegate) {
        self.delegate = delegate
        super.init(frame: frame)
        // setup gradient layer
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        let colors = [UIColor(hex6: 0x292e33), UIColor(hex6: 0x282c35), UIColor(hex6: 0x272b33)]
        gradientLayer.colors = colors.map { $0.withAlphaComponent(0.8) }.map { $0.cgColor }
        
        addSubview(collectionView)
        collectionView.reloadData()
        alpha = 0.0
        
        let line = CALayer()
        line.backgroundColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        line.frame = CGRect(x: 0, y: bounds.height - 0.5, width: SCREEN_WIDTH, height: 0.5)
        layer.addSublayer(line)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PKPhotoPreviewThumbView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return delegate.numberOfItems(in: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = delegate.thumbView(self, cellForItemAt: indexPath.item) as! PKThumbPreviewCell
//        if let index = selectedIndex, indexPath.item == index  { cell.selectedLayer.isHidden = false }
//        else { cell.selectedLayer.isHidden = true }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.thumbView(self, didSelectItemAt: indexPath.item)
    }
}

fileprivate protocol PKAssetAnimatable {
    
    func play()     -> Void
    func pause()    -> Void
    func stop()     -> Void
    func animate()  -> Void
}

extension PKAssetAnimatable {
    func play() { }
    func pause() { }
    func stop() { }
    func animate() { }
}

class PKAssetPreviewCell : UICollectionViewCell, PKAssetAnimatable {
    
    fileprivate var asset: PKAsset?
    fileprivate var closure: ((Bool?) -> Void)?
    fileprivate var requestID: PHImageRequestID? = nil
    
    fileprivate lazy var tap: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(tapAction))
    }()
    
    fileprivate lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: SCREEN_WIDTH, height: 300))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    @objc func tapAction() {
        guard let closure = closure else { return }
        closure(nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let requestID = self.requestID { PKPhotoManager.cancelRequest(with: requestID) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black
        contentView.backgroundColor = UIColor.black
        
        contentView.addGestureRecognizer(tap)
    }
    
    override var canBecomeFirstResponder: Bool { return false }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func config(with asset: PKAsset, spacing: CGFloat = 0.0) {
        fatalError("config(with:spacing:) has not been implemented")
    }
}

class PKThumbPreviewCell : PKAssetPreviewCell {
    
    
    lazy var infoLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 10.0, y: bounds.height - 20.0, width: bounds.width - 20.0, height: 20.0))
        label.font = UIFont.boldSystemFont(ofSize: 10.0)
        label.textColor = UIColor.white
        label.text = "GIF"
        return label
    }()
    
    lazy var selectedLayer: CALayer = {
        let layer = CALayer()
        layer.isHidden = true
        layer.borderWidth = 2.0
        layer.frame = contentView.bounds
        layer.borderColor = UIColor.grassGreen.cgColor
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        tap.isEnabled = false
        
        imageView.frame = bounds
        contentView.addSubview(imageView)
        contentView.addSubview(infoLabel)
        contentView.layer.addSublayer(selectedLayer)
        infoLabel.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func config(with asset: PKAsset, spacing: CGFloat = PKPhotoConfig.default.previewItemSpacing) -> Void {
        imageView.setThumb(with: asset)
        if asset.isGIF {
            infoLabel.text = "GIF"
            infoLabel.attributedText = nil
            infoLabel.isHidden = false
        } else if case .video = asset.asset.mediaType {
            infoLabel.text = ""
            let attachment = NSTextAttachment()
            attachment.image = PKPhotoConfig.localizedImage(with: "photo_list_video")
            attachment.bounds = CGRect(origin: CGPoint(x: 0.0, y: -1.5), size: attachment.image?.size ?? .zero)
            infoLabel.attributedText = NSAttributedString.init(attachment: attachment)
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected  { self.selectedLayer.isHidden = false }
            else { self.selectedLayer.isHidden = true }
        }
    }
}

class PKVideoPreviewCell : PKAssetPreviewCell {
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: SCREEN_WIDTH / 2.0 - 50.0, y: SCREEN_HEIGHT / 2.0 - 50.0, width: 100.0, height: 100.0)
        button.setImage(PKPhotoConfig.localizedImage(with: "photo_video_play"), for: .normal)
        button.setImage(PKPhotoConfig.localizedImage(with: "photo_asset_download_failed"), for: .disabled)
        button.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
        return button
    }()
    
    fileprivate var player: AVPlayer?
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var videoRequestID: PHImageRequestID?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        contentView.addSubview(playButton)
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(pause), name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(stop), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func config(with asset: PKAsset, spacing: CGFloat) {
        
        self.asset = asset
        
        // reset player
        self.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
        self.player = nil
        self.playerLayer = nil
        
        // reset play action enabled
        tap.isEnabled = true
        playButton.isEnabled = true
        
        let size = asset.sizeThatFits()
        let origin = CGPoint(x: SCREEN_WIDTH / 2.0 - size.width / 2.0, y: SCREEN_HEIGHT / 2.0 - size.height / 2.0)
        imageView.frame = CGRect(origin: origin, size: size)
        self.requestID = imageView.setImage(with: asset)
    }
    
    private func setupPlayer(with item: AVPlayerItem?) {
        guard let item = item else {
            tap.isEnabled = true
            playButton.isEnabled = false
            return
        }
        
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        guard let layer = playerLayer else {
            // create playerLayer faield, we should give up next steps and reset
            player = nil
            playerLayer = nil
            return
        }
        
        // insert playerLayer above imageView layer
        layer.contentsGravity = .resizeAspectFill
        layer.frame = CGRect(origin: .zero, size: CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        contentView.layer.insertSublayer(layer, above: imageView.layer)
    }
    
    override func tapAction() {
        
        // playbutton is disabled, this assets need to download from network
        guard playButton.isEnabled else { return }
        
        if let player = player {
            let isPaused = player.rate <= 0
            isPaused ? play() : pause()
            if let closure = closure { closure(isPaused) }
        } else {
            guard let asset = asset else { return }
            self.videoRequestID = PKPhotoManager.requestVideo(for: asset, progressClosure: { (progress, _, _, _) in
                print("here is progress \(progress)")
            }, closure: { [weak self] (item, info) in
                // closure may be not in main thread
                DispatchQueue.main.async {
                    self?.setupPlayer(with: item)
                    self?.play()
                    if let closure = self?.closure { closure(true) }
                }
            })
        }
    }
    
    @objc internal func play() {
        guard let player = player else { return }
        player.play()
        playButton.isHidden = true
    }
    
    @objc internal func pause() {
        guard let player = player else { return }
        player.pause()
        playButton.isHidden = false
    }
    
    @objc internal func stop() {
        guard let player = player else { return }
        player.pause()
        playButton.isHidden = false
        player.seek(to: CMTime(value: 0, timescale: 1))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let requestID = self.videoRequestID { PKPhotoManager.cancelVideoRequest(with: requestID) }
    }
}

class PKPhotoPreviewCell : PKAssetPreviewCell {
    
    lazy var containerView: UIView = {
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: SCREEN_WIDTH, height: 300))
        view.center = CGPoint(x: SCREEN_WIDTH / 2.0, y: SCREEN_HEIGHT / 2.0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    lazy var scrollView: UIScrollView = {
        
        let view = UIScrollView(frame: contentView.bounds)
        view.bouncesZoom = true
        view.maximumZoomScale = 3.0
        view.minimumZoomScale = 1.0
        view.isMultipleTouchEnabled = true
        view.scrollsToTop = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.delegate = self
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        containerView.addSubview(imageView)
        scrollView.addSubview(containerView)
        contentView.addSubview(scrollView)
        
        // add double tap ges to zoom in or zoom out
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(tap:)))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(doubleTap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if GIF
    
    func pause() {
        if imageView.isAnimatingGIF { imageView.stopAnimatingGIF() }
    }
    
    func animate() {
        if let asset = asset, asset.isGIF { imageView.startAnimatingGIF() }
    }
    
    #endif
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.prepareForReuse()
    }
    
    override func config(with asset: PKAsset, spacing: CGFloat = PKPhotoConfig.default.previewItemSpacing) -> Void {
        
        self.asset = asset
        
        scrollView.zoomScale = 1.0
        scrollView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width - spacing, height: contentView.bounds.height)
        
        let size = asset.sizeThatFits()
        containerView.frame = CGRect(origin: .zero, size: size)
        imageView.frame = containerView.bounds
        
        let maxWidth  =  max(scrollView.bounds.width, containerView.bounds.width)
        let maxHeight =  max(scrollView.bounds.height, containerView.bounds.height)
        scrollView.contentSize = CGSize(width: maxWidth, height: maxHeight)
        scrollView.scrollRectToVisible(bounds, animated: false)
        scrollView.alwaysBounceVertical = !(containerView.bounds.height <= scrollView.bounds.height)
        
        // fix maximum zoom scale while asset.widht or asset.height is too long
        scrollView.maximumZoomScale = max(max(CGFloat(asset.asset.pixelWidth) / bounds.size.width, CGFloat(asset.asset.pixelHeight) / bounds.size.height), 3.0)
        
        scrollViewDidZoom(scrollView)
        
        requestID = imageView.setImage(with: asset)
    }
}

extension PKPhotoPreviewCell {
    
    @objc func doubleTapAction(tap: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.contentInset = .zero
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = tap.location(in: self.imageView)
            let xsize = self.bounds.width / scrollView.maximumZoomScale
            let ysize = self.bounds.height / scrollView.maximumZoomScale
            let frame = CGRect(x: point.x - xsize / 2.0, y: point.y - ysize / 2.0, width: xsize, height: ysize)
            scrollView.zoom(to: frame, animated: true)
        }
    }
}

extension PKPhotoPreviewCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.contentInset = .zero
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        refreshImageContainerViewCenter()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
    }
    
    func refreshImageContainerViewCenter() {
        let offsetX = scrollView.bounds.width > scrollView.contentSize.width ? (scrollView.bounds.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offsetY = scrollView.bounds.height > scrollView.contentSize.height ? (scrollView.bounds.height - scrollView.contentSize.height) * 0.5 : 0.0
        let center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        containerView.center = center
    }
}

/// display photo.preview of album
class PKPhotoPreviewController : UIViewController {
    
    fileprivate let album: PKAlbum
    fileprivate let initialAsset: PKAsset?
    fileprivate let preferredSelectedAssets: Bool
    fileprivate let selectedAssets: [PKAsset]
    required init(album: PKAlbum, preferredSelectedAssets: Bool = false, initialAsset: PKAsset? = nil) {
        self.album = album
        self.preferredSelectedAssets = preferredSelectedAssets
        if preferredSelectedAssets {
            self.selectedAssets = album.selectedAssets
            self.initialAsset = initialAsset ?? album.selectedAssets.first
        } else {
            self.selectedAssets = []
            self.initialAsset = initialAsset ?? album.assets.first
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    lazy var thumbView: PKPhotoPreviewThumbView = {
        
        let height = CGFloat(PKPhotoBottomViewHeight * 2.0)
        let y = SCREEN_HEIGHT - height - bottomView.bounds.height
        let frame = CGRect(x: 0, y: y, width: SCREEN_WIDTH, height: height)
        return PKPhotoPreviewThumbView(frame: frame, delegate: self)
    }()
    
    lazy var bottomView: PKPhotoBottomView = {
        let view =  PKPhotoBottomView(configController().allowsPickingOrigin, isPreviewing: true)
        view.setup(numberOfPhotos: album.selectedCount)
        return view
    }()
    
    lazy var topView: PKPhotoPreviewTopView = {
        let height = CGFloat(iPhoneXStyle ? 88.0 : 64.0)
        let view = PKPhotoPreviewTopView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: height))
        view.backButton.addTarget(self, action: #selector(popController), for: .touchUpInside)
        
        view.closure = { [unowned self] in
            
            let offset = self.collectionView.contentOffset
            let item = Int(floor(offset.x / (SCREEN_WIDTH + CGFloat(self.configController().previewItemSpacing))))
            let indexPath = IndexPath(item: item, section: 0)
            guard let asset = self.asset(at: indexPath) else { return }
            
            var inserted: [IndexPath] = []
            var deleted:  [IndexPath] = []
            if self.album.selectedAssets.contains(asset) {
                // just remove all exists assets and reload UI
                if let index = self.album.selectedAssets.firstIndex(of: asset) {
                    self.album.selectedAssets.removeAll(where: { $0 == asset })
                    $0.setup(serialNumber: 0, state: .normal)
                    deleted.append(IndexPath(item: index, section: 0))
                }
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
                inserted.append(IndexPath(item: index, section: 0))
                $0.setup(serialNumber: (index + 1), state: .selected)
                $0.stateButton.stateView.showOscillatoryAnimation()
            }
            
            // refresh bottomView UI
            self.bottomView.setup(numberOfPhotos: self.album.selectedCount)
            // refresh thumbView
            self.refreshThumbView(withIndexPaths: inserted, deleted: deleted)
            self.refreshThumbViewHidden()
        }
        return view
    }()
    
    lazy var collectionView: UICollectionView = {
        
        let width = floor(SCREEN_WIDTH + configController().previewItemSpacing)
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: SCREEN_HEIGHT), collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 10, *) { collectionView.prefetchDataSource = self }
        collectionView.backgroundColor = UIColor.black
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.register(PKAssetPreviewCell.self, forCellWithReuseIdentifier: "PKAssetPreviewCell")
        collectionView.register(PKVideoPreviewCell.self, forCellWithReuseIdentifier: "PKVideoPreviewCell")
        collectionView.register(PKPhotoPreviewCell.self, forCellWithReuseIdentifier: "PKPhotoPreviewCell")
        return collectionView
    }()
    
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        // we should add this insets otherwise the cell will move down by 10
        if #available(iOS 11.0, *) { layout.sectionInset = UIEdgeInsets(top: -10.0, left: 0.0, bottom: 0.0, right: 0.0) }
        layout.itemSize = CGSize(width: floor(SCREEN_WIDTH + configController().previewItemSpacing), height: SCREEN_HEIGHT)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        return layout
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        view.addSubview(topView)
        
        refreshInitialAssetUI()
        scrollToInitialAssetIfNeeded()
        
        if configController().allowsPreviewThumb {
            refreshThumbViewHidden()
            // no need to call refreshThumbViewSelectedIndex again if currentIndexPath exists
            if let _ = currentIndexPath { }
            else { refreshThumbViewSelectedIndex() }
            view.addSubview(thumbView)
        }
        
        configController().verticalTransition.wire(to: self, operation: .pop)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        navigationController?.setNavigationBarHidden(true, animated: animated)
        if configController().allowsPickingOrigin { bottomView.pickingOrigin = album.pickingOrigin }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if configController().allowsPickingOrigin { album.pickingOrigin = bottomView.pickingOrigin }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    /// current displaying indexPath
    internal var currentIndexPath: IndexPath? {
        
        didSet {
            if currentIndexPath != oldValue {
                refreshCurrentAssetStateUI()
                refreshThumbViewSelectedIndex()
            }
        }
    }
    
    internal var sourceController: PKInteractiveSourceController?
}

extension PKPhotoPreviewController: PKInteractiveController {
    
    var snapshot: UIImage? {
        
        if let indexPath = currentIndexPath, let cell = collectionView.cellForItem(at: indexPath) as? PKAssetPreviewCell {
            return cell.imageView.image
        } else {
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, UIScreen.main.scale)
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    }
    
    var snapshotRect: CGRect? {
        
        guard let indexPath = currentIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) as? PKAssetPreviewCell else { return nil }
        if let cell = cell as? PKPhotoPreviewCell {
            var origin = cell.containerView.frame.origin
            let contentOffset = cell.scrollView.contentOffset
            origin = CGPoint(x: origin.x - contentOffset.x, y: origin.y - contentOffset.y)
            return CGRect(origin: origin, size: cell.containerView.frame.size)
        } else {
            return cell.imageView.frame
        }
        
        // cannot using next lines to get current indexPath, its will give two or more cells
        //        guard let indexPath = collectionView.indexPathsForVisibleItems.first else { return nil }
        //        guard indexPath.item < preferredAssets.count                         else { return nil }
        //        let asset = preferredAssets[indexPath.item]
        //        let size = asset.sizeThatFits()
        //        let origin = CGPoint(x: SCREEN_WIDTH - size.width, y: SCREEN_HEIGHT - size.height).applying(.init(scaleX: 0.5, y: 0.5))
        //        return CGRect(origin: origin, size: size)
    }
    
    internal var originalRect: CGRect? {
        return sourceController?.originalFrame(at: currentIndexPath)
    }
    
    var containerView: UIView { return view }
    
    func cancelInteraction() {
        collectionView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.topView.alpha    = 1.0
            self.bottomView.alpha = 1.0
            if self.configController().allowsPreviewThumb, self.album.selectedCount > 0 { self.thumbView.alpha = 1.0 }
        }
    }
    
    func startInteraction() {
        
        collectionView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.topView.alpha    = 0.0
            self.bottomView.alpha = 0.0
            if (self.configController().allowsPreviewThumb) { self.thumbView.alpha = 0.0 }
        }
    }
    
    func finishInteraction() { }
}

extension PKPhotoPreviewController {
    
    func asset(at indexPath: IndexPath) -> PKAsset? {
        guard indexPath.item < preferredAssets.count else { return nil }
        return preferredAssets[indexPath.item]
    }
    
    fileprivate var preferredAssets: [PKAsset] {
        if preferredSelectedAssets { return selectedAssets }
        else { return album.assets }
    }
    
    /// refresh initial item UI
    fileprivate func refreshInitialAssetUI() {
        
        guard let asset = initialAsset                               else { return }
        if let index = album.selectedAssets.firstIndex(of: asset) {
            topView.setup(serialNumber: (index + 1), state: .selected)
        } else {
            let state = album.state(of: asset, maximumCount: maximumCount(), rule: pickingRule())
            topView.setup(serialNumber: 0, state: state.0)
        }
    }
    
    /// scroll to initial item position
    fileprivate func scrollToInitialAssetIfNeeded() {
        //        DispatchQueue.main.async { [weak self] in
        // give up delay scroll initialAsset, do it right now in case of display cell twice
        guard let asset = self.initialAsset                          else { return }
        guard let item  = self.preferredAssets.firstIndex(of: asset) else { return }
        currentIndexPath = IndexPath(item: item, section: 0)
        self.collectionView.scrollToItem(at: currentIndexPath!, at: .centeredHorizontally, animated: false)
    }
}

@available(iOS 10.0, *)
extension PKPhotoPreviewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let sorted = indexPaths.map { $0.item }.sorted()
        guard let first = sorted.first else { return }
        guard let last  = sorted.last  else { return }
        let assets = preferredAssets[first...last]
        assets.forEach { PKPhotoManager.startCachingImage(for: $0) }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let sorted = indexPaths.map { $0.item }.sorted()
        guard let first = sorted.first else { return }
        guard let last  = sorted.last  else { return }
        let assets = preferredAssets[first...last]
        assets.forEach { PKPhotoManager.stopCachingImage(for: $0) }
    }
}

extension PKPhotoPreviewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return preferredAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let asset = asset(at: indexPath) else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PKAssetPreviewCell", for: indexPath)
        }
        
        var cell: UICollectionViewCell
        switch asset.asset.mediaType {
        case .video:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PKVideoPreviewCell", for: indexPath) as! PKAssetPreviewCell
        case .image:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PKPhotoPreviewCell", for: indexPath) as! PKAssetPreviewCell
        default:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PKAssetPreviewCell", for: indexPath) as! PKAssetPreviewCell
        }
        guard let previewCell = cell as? PKAssetPreviewCell else { return cell }
        
        previewCell.closure = { [weak self] in
            if let isHidden = $0 {
                // set isHidden value from closure
                self?.topView.isHidden = isHidden
                self?.bottomView.isHidden = isHidden
                if self?.configController().allowsPreviewThumb ?? false { self?.thumbView.isHidden = isHidden  }
                
            } else {
                // just reverse current isHidden
                self?.topView.isHidden = !(self?.topView.isHidden ?? false)
                self?.bottomView.isHidden = !(self?.bottomView.isHidden ?? false)
                if (self?.configController().allowsPreviewThumb ?? false) { self?.thumbView.isHidden = !(self?.thumbView.isHidden ?? false)  }
            }
        }
        previewCell.config(with: asset, spacing: configController().previewItemSpacing)
        return previewCell
    }
}

extension PKPhotoPreviewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        refreshThumbView()
        
        // plus extra width / 2.0 to calculate correct index
        let width = (SCREEN_WIDTH + configController().previewItemSpacing)
        let item = Int(floor((collectionView.contentOffset.x + width / 2.0) / width))
        if item < preferredAssets.count { currentIndexPath = IndexPath(item: item, section: 0) }
        else { currentIndexPath = nil }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        guard let indexPath = currentIndexPath else { return }
        // resume gif animation
        if let cell = collectionView.cellForItem(at: indexPath) as? PKAssetAnimatable { cell.animate() }
    }

    private func refreshCurrentAssetStateUI() {
        
        guard let indexPath = currentIndexPath else { return }
        guard let asset = asset(at: indexPath) else { return }
        
        // update current asset state UI
        let selectable = asset.canMultipleSelectable(with: pickingRule())
        if album.selectedAssets.contains(asset), let index = album.selectedAssets.firstIndex(of: asset) {
            topView.setup(serialNumber: (index + 1), state: .selected, multiple: selectable)
        } else {
            topView.setup(serialNumber: 0, state: .normal, multiple: selectable)
        }
        
        // pause cell play. such as video and gif
        if let cell = collectionView.cellForItem(at: indexPath) as? PKAssetAnimatable { cell.pause() }
    }
}

extension PKPhotoPreviewController: PKPhotoPreviewThumbViewDelegate {
    
    /// called when currentIndexPath did changed
    func refreshThumbViewSelectedIndex() {
        guard configController().allowsPreviewThumb                                 else { return }
        guard let indexPath = currentIndexPath                                      else { return }
        guard indexPath.item < preferredAssets.count                                else { return }
        let asset = preferredAssets[indexPath.item]
        thumbView.selectedIndex = album.selectedAssets.firstIndex(where: { $0 == asset })
    }
    
    /// called after album.selectedAssets insert or remove asset
    func refreshThumbView(withIndexPaths inserted: [IndexPath] = [], deleted: [IndexPath] = []) {
        
        guard configController().allowsPreviewThumb                                 else { return }
        
        thumbView.performBatchUpdates({ [unowned self] in
            if inserted.count > 0 { self.thumbView.insertItems(at: inserted) }
            if deleted.count  > 0 { self.thumbView.deleteItems(at: deleted) }
        }) { [unowned self] in
            guard $0 else { return }
            self.refreshThumbViewSelectedIndex()
            print("update thumbView finished, next should scroll to the index")
        }
    }
    
    /// called after album.selectedAssets changed, update thumbView.alpha with animation
    func refreshThumbViewHidden() {

        guard configController().allowsPreviewThumb else { return }

        if album.selectedCount <= 0, thumbView.alpha > 0 {
            UIView.animate(withDuration: 0.25, animations: { self.thumbView.alpha = 0.0 })
        } else if album.selectedCount > 0, thumbView.alpha <= 0 {
            UIView.animate(withDuration: 0.25, animations: { self.thumbView.alpha = 1.0 })
        }
    }
    
    func numberOfItems(in thumbView: PKPhotoPreviewThumbView) -> Int {
        return album.selectedCount
    }
    
    func thumbView(_ thumbView: PKPhotoPreviewThumbView, cellForItemAt index: Int) -> UICollectionViewCell {
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = thumbView.collectionView.dequeueReusableCell(withReuseIdentifier: "PKThumbPreviewCell", for: indexPath) as? PKThumbPreviewCell else {
            return UICollectionViewCell()
        }
        guard index < album.selectedAssets.count else { return cell }
        cell.config(with: album.selectedAssets[indexPath.item])
        return cell
    }
    
    func thumbView(_ thumbView: PKPhotoPreviewThumbView, didSelectItemAt index: Int) {
        
        guard index < album.selectedAssets.count                                     else { return }
        let asset = album.selectedAssets[index]
        guard let selectedIndex = preferredAssets.firstIndex(where: { $0 == asset }) else { return }
        let indexPath = IndexPath(item: selectedIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}
