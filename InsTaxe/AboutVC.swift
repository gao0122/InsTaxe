//
//  AboutVC.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit
import Photos

class AboutVC: UIViewController {
    
    @IBOutlet weak var autoSaveView: UIView!
    @IBOutlet weak var autoSaveSwitch: UISwitch!
    @IBOutlet weak var autoSaveLabel: UILabel!

    var shouldHaveShowInsTaxe: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let frame = self.navigationController?.navigationBar.frame {
            autoSaveView.frame.origin.y = frame.origin.y + frame.height
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if shouldHaveShowInsTaxe {
            if let vc = tabBarController?.viewControllers?.first?.childViewControllers.first as? MainVC {
                vc.shouldShowInsTaxe = true
                self.shouldHaveShowInsTaxe = false
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else { return }
        switch id {
        case "showInsTaxeVCFromAboutVC":
            if let copiedLink = UIPasteboard.general.string {
                guard let vc = segue.destination as? InsTaxeVC else { return }
                vc.axeLink = copiedLink
            } else {
                self.view.notifyc(text: "Opps, you should copy link first", nav: self.navigationController)
            }
        default:
            break
        }
    }

    @IBAction func autoSaveSwitched(_ sender: Any) {
        if autoSaveSwitch.isOn {
            if PHPhotoLibrary.authorizationStatus().rawValue != 3 {
                PHPhotoLibrary.requestAuthorization({
                    status in
                    if status.rawValue != 3 {
                        self.autoSaveSwitch.setOn(false, animated: false)
                    }
                })
            }
        }
        UserDefaults.standard.set(autoSaveSwitch.isOn, forKey: "autoSave")
    }
    
    @IBAction func moreBtnPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Thanks for using Taxe", message: nil, preferredStyle: .actionSheet)
        let share = UIAlertAction(title: "Share the app", style: .default, handler: {
            _ in
            let string = "Taxe - a smart free instagram photo/video reposter"
            let image = UIImage(named: "logo40r")
            let url = URL(string: "https://itunes.apple.com/app/superboard/id\(appID)")!
            // set up activity view controller
            let activityViewController = UIActivityViewController(activityItems: [string, url, image!], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
            // exclude some activity types from the list (optional)
            activityViewController.excludedActivityTypes = []
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
        })
        let good = UIAlertAction(title: "Leave comments", style: .default, handler: {
            _ in
            let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url!)
            }
        })
        let advice = UIAlertAction(title: "Contact me", style: .default, handler: {
            _ in
            let alertController = UIAlertController(title: nil, message: "If you have any suggestions or advice please mail me.", preferredStyle: .alert)
            let copy = UIAlertAction(title: "Copy address", style: .default, handler: {
                _ in
                UIPasteboard.general.string = "i@gaoyuchao.com"
                self.view.notifyc(text: "Email copied to pasteboard", nav: self.navigationController)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(copy)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        })
        let clear = UIAlertAction(title: "Clear all cache", style: .destructive, handler: {
            _ in
            let alertController = UIAlertController(title: nil, message: "This will clear all the photos and videos cache, are you sure?", preferredStyle: .alert)
            let okay = UIAlertAction(title: "Sure", style: .default, handler: {
                _ in
                let ud = UserDefaults.standard
                let domain = Bundle.main.bundleIdentifier!
                ud.removePersistentDomain(forName: domain)
                ud.synchronize()
                self.view.notifyc(text: "Cleared successfully", nav: self.navigationController)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(okay)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        })
//        let wbDL = UIAlertAction(title: "Try Weibo Downloader👍", style: .default, handler: {
//            _ in
//            let url = URL(string: "itms-apps://itunes.apple.com/app/id\(wbAppID)")
//            if #available(iOS 10.0, *) {
//                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
//            } else {
//                // Fallback on earlier versions
//                UIApplication.shared.openURL(url!)
//            }
//        })

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(share)
        alertController.addAction(good)
        alertController.addAction(advice)
        alertController.addAction(clear)
        //alertController.addAction(wbDL) rejected
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
