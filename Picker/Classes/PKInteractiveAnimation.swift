//  PKInteractiveAnimation.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/23
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      PKInteractiveAnimation
//  @version    <#class version#>
//  @abstract   <#class description#>

import Foundation

fileprivate let PKAnimationDuration: TimeInterval = 0.3
fileprivate let PKAnimationOffsetX: CGFloat = -100.0

class PKInteractivePushAnimation : NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return PKAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let fromView    = transitionContext.view(forKey: .from) else { return }
        guard let toView    = transitionContext.view(forKey: .to) else { return }
        transitionContext.containerView.addSubview(toView)
        toView.frame = CGRect(x: SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        UIView.animate(withDuration: PKAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
            fromView.frame = CGRect(x: PKAnimationOffsetX, y: 0.0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
            toView.frame = CGRect(origin: .zero, size: CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        }) { _ in
            transitionContext.completeTransition(true)
        }
    }
}

class PKInteractivePopAnimation : NSObject, UIViewControllerAnimatedTransitioning {
    
    fileprivate var isVertical: Bool
    
    init(isVertical: Bool = false) {
        self.isVertical = isVertical
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return PKAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // do push animation
        guard let toView      = transitionContext.view(forKey: .to)     else { return }
        guard let fromView    = transitionContext.view(forKey: .from)   else { return }
        
        if isVertical { verticalPopAnimation(from: fromView, to: toView, transitionContext: transitionContext) }
        else { normalPopAnimation(from: fromView, to: toView, transitionContext: transitionContext) }
    }
    
    func verticalPopAnimation(from fromView: UIView, to toView: UIView, transitionContext context: UIViewControllerContextTransitioning) {
        
        toView.frame   = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        fromView.frame = CGRect(origin: .zero, size: CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        
        let blackView = UIView(frame: toView.bounds)
        blackView.backgroundColor = UIColor.black
//        context.containerView.insertSubview(blackView, at: 0)
        toView.addSubview(blackView)
        context.containerView.insertSubview(toView, at: 0)

        UIView.animate(withDuration: PKAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
            toView.frame   = CGRect(x: 0.0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
            blackView.backgroundColor = UIColor.black.withAlphaComponent(0)
        }) { _ in
            blackView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    /// normal pop animation, trigger by back item
    func normalPopAnimation(from fromView: UIView, to toView: UIView, transitionContext context: UIViewControllerContextTransitioning) {

        toView.frame   = CGRect(x: PKAnimationOffsetX, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        fromView.frame = CGRect(origin: .zero, size: CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        
        context.containerView.insertSubview(toView, belowSubview: fromView)

        UIView.animate(withDuration: PKAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
            toView.frame   = CGRect(x: 0.0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
            fromView.frame = CGRect(x: SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        }) { _ in
            context.completeTransition(!context.transitionWasCancelled)
        }
    }
}
