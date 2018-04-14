//
//  PhotoPageItemVC.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit
import SDWebImage
import AVKit

class PhotoPageItemVC: UIViewController {

    @IBOutlet weak var axeIV: UIImageView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var showVideoBtn: UIButton!
    
    var url: URL?
    var image: UIImage?
    var axeVideoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if axeIV.image == nil {
            if let image = self.image {
                axeIV.image = image
                if let navBar = navigationController?.navigationBar {
                    axeIV.frame.origin.y = navBar.frame.height + navBar.frame.origin.y
                }
            } else if let url = self.url {
                self.indicatorView.isHidden = false
                self.indicatorView.startAnimating()
                axeIV.sd_setImage(with: url, completed: {
                    _, _, _, _ in
                    self.indicatorView.stopAnimating()
                })
            }
            if let _ = axeVideoURL {
                showVideoBtn.isHidden = false
            } else {
                showVideoBtn.isHidden = true
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if axeIV.image == nil {
            if let image = self.image {
                axeIV.image = image
            } else if let url = self.url {
                self.indicatorView.isHidden = false
                self.indicatorView.startAnimating()
                axeIV.sd_setImage(with: url, completed: {
                    _, _, _, _ in
                    self.indicatorView.stopAnimating()
                })
            }
        }
    }
    
    class func instantiateFromStoryboard(url: URL? = nil, image: UIImage? = nil, videoURL: URL? = nil) -> PhotoPageItemVC {
        let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: String(describing: self)) as! PhotoPageItemVC
        vc.image = image
        vc.url = url
        vc.axeVideoURL = videoURL
        return vc
    }
    
    @IBAction func showVideoBtn(_ sender: Any) {
        if let url = axeVideoURL {
            let playerVC = AVPlayerViewController()
            playerVC.navigationController?.setNavigationBarHidden(true, animated: true)
            playerVC.tabBarController?.tabBar.isHidden = true
            let player = AVPlayer(url: url)
            playerVC.player = player
            player.play()
            self.showDetailViewController(playerVC, sender: sender)
        }
    }
    
    
    
}
