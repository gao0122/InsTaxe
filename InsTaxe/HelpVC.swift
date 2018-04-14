//
//  HelpVC.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/16/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit

class HelpVC: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    var images = [UIImage]()
    var vcs = [PhotoPageItemVC]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let img = UIImage(named: "howToUse") else { return }
        guard let img2 = UIImage(named: "howToUse2") else { return }
        
        self.dataSource = self
        self.delegate = self
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.black
        pageControl.backgroundColor = UIColor.white
        
        images.append(img)
        images.append(img2)
        
        let vc = PhotoPageItemVC.instantiateFromStoryboard(image: img)
        let vc2 = PhotoPageItemVC.instantiateFromStoryboard(image: img2)
        vcs.append(vc)
        vcs.append(vc2)

        self.setViewControllers([vc], direction: .forward, animated: true, completion: nil)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.frame.origin.y = self.view.frame.height
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let vc = tabBarController?.viewControllers?.first?.childViewControllers.first as? MainVC {
            vc.shouldShowInsTaxe = false
        }
    }

    
    // MARK: - PageViewController
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? PhotoPageItemVC else { return nil }
        guard let img = vc.axeIV.image else { return nil }
        if let index = images.index(of: img) {
            let previousIndex = index - 1
            guard previousIndex >= 0 else {
                return nil
            }
            guard vcs.count > previousIndex else {
                return nil
            }
            return vcs[previousIndex]
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? PhotoPageItemVC else { return nil }
        guard let img = vc.axeIV.image else { return nil }
        if let index = images.index(of: img) {
            let nextIndex = index + 1
            guard nextIndex < vcs.count else {
                return nil
            }
            guard vcs.count > nextIndex else {
                return nil
            }
            return vcs[nextIndex]
        } else {
            return nil
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 2
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstVC = vcs.first, let firstVCIndex = vcs.index(of: firstVC) else { return 0 }
        return firstVCIndex
    }
    
    

}
