//  PKInteractiveTransition.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/23
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKInteractiveTransition

import Foundation

enum PKInteractiveOperation: Int {
    case pop
    case dismiss
    case tabs
}

private struct AssociatedKeys {
    static var Gesture = "xmfraker.photos.Gesture"
}

protocol PKInteractiveController {
    
    var  snapshot               :   UIImage?                        { get }
    var  snapshotRect           :   CGRect?                         { get }
    var  containerView          :   UIView                          { get }
    var  originalRect           :   CGRect?                         { get }
    var  sourceController       :   PKInteractiveSourceController?  { get }
    var  navigationController   :   UINavigationController?         { get }
    
    func startInteraction()
    func cancelInteraction()
    func finishInteraction()
}

extension PKInteractiveController {
    
    var  snapshot               :   UIImage?                        { return nil }
    var  snapshotRect           :   CGRect?                         { return nil }
    var  originalRect           :   CGRect?                         { return nil }
    var  sourceController       :   PKInteractiveSourceController?  { return nil }
    var  navigationController   :   UINavigationController?         { return nil }

    func startInteraction()  {}
    func cancelInteraction() {}
    func finishInteraction() {}
}

protocol PKInteractiveSourceController {
    func originalView(at indexPath: IndexPath?) -> UIView?
    func originalFrame(at indexPath: IndexPath?) -> CGRect?
}

extension PKInteractiveSourceController {
    func originalView(at indexPath: IndexPath?) -> UIView?  { return nil }
    func originalFrame(at indexPath: IndexPath?) -> CGRect? { return nil }
}

public class PKInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    var operation: PKInteractiveOperation = .pop
    var interactiveController       : PKInteractiveController?
    var interactiveInProgress       : Bool = false
    var shouldCompleteTransition    : Bool = false
    
    func wire(to interactiveController: PKInteractiveController, operation: PKInteractiveOperation) {
        
        self.operation = operation
        self.interactiveController = interactiveController
        if let view = self.interactiveController?.containerView { prepareGestureRecognizer(in: view) }
    }
    
    func prepareGestureRecognizer(in view: UIView) { }
    
    public override var completionSpeed: CGFloat {
        set { self.completionSpeed = newValue }
        get { return 1.0 - self.percentComplete }
    }
}

public class PKVerticalInteractiveTransition: PKInteractiveTransition {
    
    lazy var snapshotView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode    = .scaleAspectFill
        view.clipsToBounds  = true
        return view
    }()
    
    private var snapshotViewRect: CGRect {
        
        if let rect = interactiveController?.snapshotRect { return rect }
        
        if let image = snapshotView.image {
            let scale = image.scale / UIScreen.main.scale
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: SCREEN_WIDTH / 2.0 - size.width / 2.0, y: SCREEN_HEIGHT / 2.0 - size.height / 2.0)
            return CGRect(origin: origin, size: size)
        }
        return CGRect(x: 0.0, y: 0.0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
    }
    
    fileprivate var pan: UIPanGestureRecognizer? {
        set { objc_setAssociatedObject(self, &AssociatedKeys.Gesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &AssociatedKeys.Gesture) as? UIPanGestureRecognizer  }
    }
    
    override func wire(to interactiveController: PKInteractiveController, operation: PKInteractiveOperation) {
        if case .tabs = operation {
            fatalError("cannot use a vertical swipe interactive transition within tabBarController")
        }
        super.wire(to: interactiveController, operation: operation)
    }
    
    override func prepareGestureRecognizer(in view: UIView) {
        if let _ = self.pan { self.pan = nil }
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        gesture.delegate = self
        gesture.maximumNumberOfTouches = 1
        gesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(gesture)
        self.pan = gesture
    }
    
    private func resetSnapshotView() {
        // update anchorPoint first then reset its frame
        snapshotView.image = nil
        snapshotView.alpha = 1.0
        snapshotView.transform = .identity
        snapshotView.contentMode = .scaleAspectFill
        snapshotView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        snapshotView.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        if let _ = snapshotView.superview { snapshotView.removeFromSuperview() }
    }
    
    @objc public func pan(_ gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began:
            resetSnapshotView()
            fallthrough
        case .changed:
            if interactiveInProgress {

                let progress = max(0, (translation.y / SCREEN_HEIGHT))
                shouldCompleteTransition = (gesture.velocity(in: gesture.view).y >= 1.0) && progress >= 0.01
                
                var transform = CGAffineTransform.identity.translatedBy(point: translation)
                if snapshotView.bounds.height <= SCREEN_HEIGHT, snapshotView.bounds.width <= SCREEN_WIDTH {
                    let scale = max((1 - progress), 0.3)
                    transform = transform.scaledBy(x: scale, y: scale)
                }
                snapshotView.transform = transform
//                    .scaledBy(x: scale, y: scale)
                update(progress * 2.0)
            } else {

                if (translation.y > 5.0) {
                    
                    // calculate correct anchor point from snapshotView scale
                    let frame = snapshotViewRect
                    let point = gesture.location(in: gesture.view)
                    let x = CGFloat(Int(floor((point.x - frame.minX) * 3.0) / frame.width)) * 0.5
                    
                    // update anchorPoint then reset frame again
                    snapshotView.layer.anchorPoint = CGPoint(x: x, y: 1.0)
                    snapshotView.image = interactiveController?.snapshot
                    snapshotView.frame = frame

                    interactiveInProgress = true
                    interactiveController?.navigationController?.popViewController(animated: true)

                    if let belowView = interactiveController?.containerView, let superView = belowView.superview {
                        superView.insertSubview(snapshotView, belowSubview: belowView)
                    } else {
                        UIApplication.shared.keyWindow?.addSubview(snapshotView)
                    }
                    
                    interactiveController?.startInteraction()
                }
            }
            break
        case .ended:    fallthrough
        case .cancelled:
            if interactiveInProgress {
                interactiveInProgress = false
                if shouldCompleteTransition == false || gesture.state == .cancelled {
                    let originalFrame = snapshotView.frame
                    snapshotView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    snapshotView.frame = originalFrame
                    UIView.animate(withDuration: 0.25, animations: {
                        self.snapshotView.transform = .identity
                        self.snapshotView.frame     = self.snapshotViewRect
                    }) { _ in
                        self.cancel()
                        self.interactiveController?.cancelInteraction()
                        self.resetSnapshotView()
                    }
                } else {
                    self.finish()
                    let originalFrame = snapshotView.frame
                    snapshotView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    snapshotView.frame = originalFrame
                    UIView.animate(withDuration: 0.25, animations: {
                        if let rect = self.interactiveController?.originalRect {
                            self.snapshotView.transform = .identity
                            self.snapshotView.frame = rect
                        } else {
                            self.snapshotView.alpha = 0.0
                        }
                    }) { _ in
                        self.interactiveController?.finishInteraction()
                        self.resetSnapshotView()
                    }
                }
            }
        default: break
        }
    }
}

extension PKVerticalInteractiveTransition: UIGestureRecognizerDelegate {
    
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
////        print("shouldBeRequiredToFailBy \(gestureRecognizer)  other \(otherGestureRecognizer)")
//        return false
//        if gestureRecognizer == pan {
//            if otherGestureRecognizer.state == .possible { return false }
//            else { return true }
////            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
////                return scrollView.contentOffset.y <= 0
////            }
//        }
//        return false
//    }
    
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        print("gestureRecognizerShouldBegin \(gestureRecognizer)")
//        return true
//    }
    
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        if gestureRecognizer == pan, let view = otherGestureRecognizer.view as? UIScrollView, view.isMember(of: UIScrollView.self) {
//            print("shouldRequireFailureOf \(gestureRecognizer) \(otherGestureRecognizer)")
//            return view.contentOffset.y <= 0
//        }
//        return false
//    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == pan, let view = otherGestureRecognizer.view as? UIScrollView, view.isMember(of: UIScrollView.self) {
            return view.contentOffset.y <= 0
        }
        return false
    }
}
