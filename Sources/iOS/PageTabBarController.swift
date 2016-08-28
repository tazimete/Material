/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

/// A memory reference to the PageTabBarItem instance for UIViewController extensions.
private var PageTabBarItemKey: UInt8 = 0

open class PageTabBarItem: FlatButton {
    open override func prepareView() {
        super.prepareView()
        pulseAnimation = .none
    }
}

open class PageTabBar: TabBar {
    open override func prepareView() {
        super.prepareView()
        isLineAnimated = false
        lineAlignment = .top
    }
}

@objc(PageTabBarAlignment)
public enum PageTabBarAlignment: Int {
    case top
    case bottom
}

/// Grid extension for UIView.
extension UIViewController {
    /// Grid reference.
    public private(set) var pageTabBarItem: PageTabBarItem {
        get {
            return AssociatedObject(base: self, key: &PageTabBarItemKey) {
                return PageTabBarItem()
            }
        }
        set(value) {
            AssociateObject(base: self, key: &PageTabBarItemKey, value: value)
        }
    }
}

extension UIViewController {
    /**
     A convenience property that provides access to the PageTabBarController.
     This is the recommended method of accessing the PageTabBarController
     through child UIViewControllers.
     */
    public var pageTabBarController: PageTabBarController? {
        var viewController: UIViewController? = self
        while nil != viewController {
            if viewController is PageTabBarController {
                return viewController as? PageTabBarController
            }
            viewController = viewController?.parent
        }
        return nil
    }
}

@objc(PageTabBarControllerDelegate)
public protocol PageTabBarControllerDelegate {
    /**
     A delegation method that is executed when a UIViewController did transition to.
     - Parameter pageTabBarController: A PageTabBarController.
     - Parameter willTransitionTo viewController: A UIViewController.
     */
    @objc
    optional func pageTabBarController(pageTabBarController: PageTabBarController, didTransitionTo viewController: UIViewController)
}

@objc(PageTabBarController)
open class PageTabBarController: RootController {
    /// Indicates that the tab has been pressed and animating.
    open internal(set) var isTabSelectedAnimation = false
    
    /// The currently selected UIViewController.
    open internal(set) var selectedIndex: Int = 0
    
    /// PageTabBar alignment setting.
    open var pageTabBarAlignment = PageTabBarAlignment.bottom
    
    /// Reference to the PageTabBar.
    open internal(set) var pageTabBar: PageTabBar!
    
    /// Delegation handler.
    public weak var delegate: PageTabBarControllerDelegate?
    
    /// A reference to the instance when it is a UIPageViewController.
    open var pageViewController: UIPageViewController? {
        return rootViewController as? UIPageViewController
    }
    
    /// A reference to the UIViewControllers.
    open var viewControllers = [UIViewController]()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil))
        viewControllers.append(rootViewController)
        setViewControllers(viewControllers, direction: .forward, animated: true)
    }
    
    public init(viewControllers: [UIViewController], selectedIndex: Int, direction: UIPageViewControllerNavigationDirection, animated: Bool) {
        super.init(rootViewController: UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil))
        self.selectedIndex = selectedIndex
        self.viewControllers.append(contentsOf: viewControllers)
        setViewControllers([self.viewControllers[selectedIndex]], direction: direction, animated: animated)
    }
    
    /**
     To execute in the order of the layout chain, override this
     method. LayoutSubviews should be called immediately, unless you
     have a certain need.
     */
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let v = pageTabBar else {
            return
        }
        
        let h = view.height
        let w = view.width
        let p = v.intrinsicContentSize.height + v.grid.layoutEdgeInsets.top + v.grid.layoutEdgeInsets.bottom
        let y = h - p
        
        v.height = p
        v.width = w + v.grid.layoutEdgeInsets.left + v.grid.layoutEdgeInsets.right
        
        rootViewController.view.height = y
        
        switch pageTabBarAlignment {
        case .top:
            v.y = 0
            rootViewController.view.y = p
        case .bottom:
            v.y = y
            rootViewController.view.y = 0
        }
        
        v.divider.reload()
    }
    
    /**
     Prepares the view instance when intialized. When subclassing,
     it is recommended to override the prepareView method
     to initialize property values and other setup operations.
     The super.prepareView method should always be called immediately
     when subclassing.
     */
    open override func prepareView() {
        super.prepareView()
        preparePageTabBar()
    }
    
    override func prepareRootViewController() {
        super.prepareRootViewController()
        
        guard let v = pageViewController else {
            return
        }
        
        v.delegate = self
        v.dataSource = self
        v.isDoubleSided = false
        
        for view in v.view.subviews {
            if let v = view as? UIScrollView {
                v.delegate = self
            }
        }
    }
    
    /// Prepares the pageTabBarItems.
    open func preparePageTabBarItems() {
        pageTabBar.buttons.removeAll()
        
        for x in viewControllers {
            let button = x.pageTabBarItem as UIButton
            pageTabBar.buttons.append(button)
            button.removeTarget(self, action: #selector(pageTabBar.handleButton(button:)), for: .touchUpInside)
            button.removeTarget(self, action: #selector(handlePageTabBarButton(button:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(handlePageTabBarButton(button:)), for: .touchUpInside)
        }
    }
    
    /**
     Handles the pageTabBarButton.
     - Parameter button: A UIButton.
     */
    @objc
    internal func handlePageTabBarButton(button: UIButton) {
        guard let index = pageTabBar.buttons.index(of: button) else {
            return
        }
        
        guard index != selectedIndex else {
            return
        }
        
        let direction: UIPageViewControllerNavigationDirection = index < selectedIndex ? .reverse : .forward
        
        isTabSelectedAnimation = true
        selectedIndex = index
        
        pageTabBar.select(at: selectedIndex)
        
        setViewControllers([viewControllers[index]], direction: direction, animated: true) { [weak self] _ in
            guard let s = self else {
                return
            }
            s.isTabSelectedAnimation = false
            s.delegate?.pageTabBarController?(pageTabBarController: s, didTransitionTo: s.viewControllers[s.selectedIndex])
        }
    }
    
    /// Prepares the pageTabBar.
    private func preparePageTabBar() {
        if nil == pageTabBar {
            pageTabBar = PageTabBar()
            pageTabBar.zPosition = 1000
            view.addSubview(pageTabBar)
            pageTabBar.select(at: selectedIndex)
        }
    }
}

extension PageTabBarController {
    open func setViewControllers(_ viewControllers: [UIViewController]?, direction: UIPageViewControllerNavigationDirection, animated: Bool, completion: (@escaping (Bool) -> Void)? = nil) {
        pageViewController?.setViewControllers(viewControllers, direction: direction, animated: animated, completion: completion)
        preparePageTabBarItems()
    }
}

extension PageTabBarController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let v = pageViewController.viewControllers?.first else {
            return
        }
        
        guard let index = viewControllers.index(of: v) else {
            return
        }
        
        selectedIndex = index
        pageTabBar.select(at: selectedIndex)
        
        if finished && completed {
            delegate?.pageTabBarController?(pageTabBarController: self, didTransitionTo: v)
        }
    }
}

extension PageTabBarController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let current = viewControllers.index(of: viewController) else {
            return nil
        }
        
        let previous = current - 1
        
        guard previous >= 0 else {
            return nil
        }
        
        return viewControllers[previous]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let current = viewControllers.index(of: viewController) else {
            return nil
        }
        
        let next = current + 1
        
        guard viewControllers.count > next else {
            return nil
        }
        
        return viewControllers[next]
    }
}

extension PageTabBarController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !pageTabBar.isAnimating else {
            return
        }
        
        guard !isTabSelectedAnimation else {
            return
        }
        
        guard let selected = pageTabBar.selected else {
            return
        }
        
        guard 0 < view.width else {
            return
        }
        
        let x = (scrollView.contentOffset.x - view.width) / scrollView.contentSize.width * view.width
        
        pageTabBar.line.center.x = selected.center.x + x
    }
}