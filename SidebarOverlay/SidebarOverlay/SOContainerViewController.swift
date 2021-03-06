//
//  SOContainerViewController.swift
//  SidebarOverlay
//
//  Created by Alexander Perechnev on 12/23/15.
//  Copyright © 2015 Alexander Perechnev. All rights reserved.
//

import UIKit



/// Protocol that responds to events, that are passing from SOContainerViewController, when user interacts with it.
public protocol SOContainerViewControllerDelegate {
    
    func leftViewControllerPulledOut(pulledOut: Bool)
    
    func willSetTopViewController(viewController: UIViewController?)
    func didSetTopViewController(viewController: UIViewController?)
    
    func willSetLeftViewController(viewController: UIViewController?)
    func didSetLeftViewController(viewController: UIViewController?)
    
}

public extension SOContainerViewControllerDelegate {
    
    func leftViewControllerPulledOut(pulledOut: Bool) {}
    
    func willSetTopViewController(viewController: UIViewController?) {}
    func didSetTopViewController(viewController: UIViewController?) {}
    
    func willSetLeftViewController(viewController: UIViewController?) {}
    func didSetLeftViewController(viewController: UIViewController?) {}
    
}


public extension UIViewController {
    
    var so_containerViewController: SOContainerViewController? {
        var parentVC: UIViewController? = self
        
        repeat {
            if parentVC is SOContainerViewController {
                return parentVC as? SOContainerViewController
            }
            parentVC = parentVC!.parentViewController
        }
        while (parentVC != nil)
        
        return nil
    }
    
    @available(*, deprecated=1.1.1, message="Use so_containerViewController instead.")
    func so_container() -> SOContainerViewController? {
        return self.so_containerViewController
    }
    
}


public class SOContainerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let LeftViewControllerRightIndent: CGFloat = 56.0
    let LeftViewControllerOpenedLeftOffset: CGFloat = 0.0
    let SideViewControllerOpenAnimationDuration: NSTimeInterval = 0.24
    
    
    public var delegate: SOContainerViewControllerDelegate?
    
    public var topViewController: UIViewController? {
        willSet {
            self.delegate?.willSetTopViewController(newValue)
        }
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            
            if let topVC = self.topViewController {
                topVC.willMoveToParentViewController(self)
                
                self.addChildViewController(topVC)
                self.view.addSubview(topVC.view)
                
                topVC.didMoveToParentViewController(self)
                
                topVC.view.addGestureRecognizer(self.createPanGestureRecognizer())
            }
            
            if let vc = self.leftViewController {
                self.view.bringSubviewToFront(vc.view)
            }
            
            self.delegate?.didSetTopViewController(topViewController)
        }
    }
    
    public var leftViewController: UIViewController? {
        willSet {
            self.delegate?.willSetLeftViewController(newValue)
        }
        didSet {
            self.view.addSubview((self.leftViewController?.view)!)
            self.addChildViewController(self.leftViewController!)
            self.leftViewController?.didMoveToParentViewController(self)
            
            self.view.bringSubviewToFront((self.leftViewController?.view)!)
            
            var menuFrame = self.leftViewController?.view.frame
            menuFrame?.size.width = self.view.frame.size.width - LeftViewControllerRightIndent
            menuFrame?.origin.x = -(menuFrame?.size.width)!
            self.leftViewController?.view.frame = menuFrame!
            
            self.leftViewController?.view.addGestureRecognizer(self.createPanGestureRecognizer())
            
            self.delegate?.didSetLeftViewController(leftViewController)
        }
    }
    
    
    public func setMenuOpened(opened: Bool) {
        var frameToApply = self.leftViewController?.view.frame
        frameToApply?.origin.x = opened ? LeftViewControllerOpenedLeftOffset : -(self.leftViewController?.view.frame.size.width)!
        
        let animations: () -> () = {
            self.leftViewController?.view.frame = frameToApply!
        }
        
        UIView.animateWithDuration(SideViewControllerOpenAnimationDuration, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: animations, completion: nil)
        
        self.delegate?.leftViewControllerPulledOut(opened)
    }
    
    public func moveMenu(panGesture: UIPanGestureRecognizer) {
        panGesture.view?.layer.removeAllAnimations()
        
        let translatedPoint = panGesture.translationInView(self.view)
        
        if panGesture.state == UIGestureRecognizerState.Changed {
            let menuView = self.leftViewController?.view
            var calculatedXPosition = (menuView?.center.x)! + translatedPoint.x
            
            calculatedXPosition = min((menuView?.frame.size.width)! / 2.0, calculatedXPosition)
            
            menuView?.center = CGPointMake(calculatedXPosition, (menuView?.center.y)!)
            panGesture.setTranslation(CGPointMake(0, 0), inView: self.view)
        }
        else if panGesture.state == UIGestureRecognizerState.Ended {
            let isMenuPulledEnoghToOpenIt = fabs((self.leftViewController?.view.frame.origin.x)!) < (self.leftViewController?.view.frame.size.width)! / 2
            
            self.setMenuOpened(isMenuPulledEnoghToOpenIt)
        }
    }
    
    private func createPanGestureRecognizer() -> UIPanGestureRecognizer! {
        let  panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: "moveMenu:")
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translation = panGestureRecognizer.translationInView(self.view)
        if fabs(translation.x) > fabs(translation.y) {
            return true
        }
        return false
    }
    
}
