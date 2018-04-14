//
//  MainVC.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit

class MainVC: UIViewController {

    @IBOutlet weak var openInsBtn: UIButton!
    @IBOutlet weak var insTaxeBtn: UIButton!
    @IBOutlet weak var wbdownloaderView: UIView!
    @IBOutlet weak var wbdownloaderDownloadBtn: UIButton!
    @IBOutlet weak var dismissBtn: UIButton!
    
    var shouldShowInsTaxe: Bool = false
    
    let copyLinkText = "Opps, you should copy link first"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show kyxu's app recommendation
        //setWBDL()
        
        if #available(iOS 10.0, *) { } else {
            openInsBtn.isEnabled = false
            openInsBtn.setTitleColor(.black, for: .normal)
        }
        
        // TODO: - Check histories
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShowInsTaxe {
            if let copiedLink = UIPasteboard.general.string {
                if isFromIns(copiedLink) {
                    performSegue(withIdentifier: "showInsTaxeVCFromMainVC", sender: self)
                }
            }
        }
        guard let tabBar = self.tabBarController?.tabBar else { return }
        if tabBar.isHidden {
            tabBar.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                tabBar.frame.origin.y = self.view.frame.height - tabBar.frame.height
            })
        }
    }

    
    func checkHistories() {
        // TODO
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else { return }
        switch id {
        case "showInsTaxeVCFromMainVC":
            if let copiedLink = UIPasteboard.general.string {
                guard let vc = segue.destination as? InsTaxeVC else { return }
                vc.axeLink = copiedLink
            } else {
                self.view.notifyc(text: copyLinkText, nav: self.navigationController)
            }
        default:
            break
        }
    }
    
    @IBAction func unwindToMainVC(segue: UIStoryboardSegue) {
        
    }

    @IBAction func wbdownloaderBtnPressed(_ sender: Any) {
        let url = URL(string: "itms-apps://itunes.apple.com/app/id\(wbAppID)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(url!)
        }
    }
    
    @IBAction func dismissBtnPressed(_ sender: Any) {
        if UserDefaults.standard.integer(forKey: "wbdl") < 6 {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "wbdl") + 1, forKey: "wbdl")
        }
        UIView.animate(withDuration: 0.2) {
            self.wbdownloaderView.frame.origin.y -= self.wbdownloaderView.frame.height
        }
    }
    
    @IBAction func openInsBtnPressed(_ sender: Any) {
        let instagramUrl = URL(string: "instagram://app")!
        let canOpen = UIApplication.shared.canOpenURL(instagramUrl)
        if canOpen {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(instagramUrl)
            }
        } else {
            let insUrl = URL(string: "https://www.instagram.com")!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(insUrl, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(insUrl)
            }
        }
    }
    
    @IBAction func insTaxeBtnPressed(_ sender: Any) {
        if let copiedLink = UIPasteboard.general.string {
            if isFromIns(copiedLink) {
                performSegue(withIdentifier: "showInsTaxeVCFromMainVC", sender: sender)
            } else {
                self.view.notifyc(text: copyLinkText, duration: 2, nav: self.navigationController)
            }
        } else {
            self.view.notifyc(text: copyLinkText, nav: self.navigationController)
        }
    }
    
    
    func setWBDL() {
        if UserDefaults.standard.integer(forKey: "wbdl") > 4 {
            wbdownloaderView.isHidden = arc4random_uniform(158) > 7
        } else {
            if let navBar = self.navigationController?.navigationBar {
                wbdownloaderDownloadBtn.layer.masksToBounds = true
                wbdownloaderDownloadBtn.layer.cornerRadius = 7
                wbdownloaderDownloadBtn.layer.borderWidth = 1
                wbdownloaderDownloadBtn.layer.borderColor = wbdownloaderDownloadBtn.currentTitleColor.cgColor
                wbdownloaderView.frame.origin.y = navBar.frame.height + navBar.frame.origin.y
                wbdownloaderView.isHidden = false
                dismissBtn.layer.masksToBounds = true
                dismissBtn.layer.cornerRadius = dismissBtn.frame.width / 2
            } else {
                wbdownloaderView.isHidden = true
            }
        }
    }
}


func printit(_ any: Any) {
    print()
    print("------------------------------")
    print(any)
    print("------------------------------")
}



