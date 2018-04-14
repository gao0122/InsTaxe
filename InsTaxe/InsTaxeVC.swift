//
//  InsTaxeVC.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit
import Photos
import AVKit
import SDWebImage

class InsTaxeVC: UIViewController, UIWebViewDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    

    @IBOutlet weak var savingHelperLabel: UILabel!
    @IBOutlet weak var savingHelperView: UIView!
    @IBOutlet weak var savingHelperCancelBtn: UIButton!
    @IBOutlet weak var axeIV: UIImageView!
    @IBOutlet weak var imagesView: UIView!
    @IBOutlet weak var showVideoBtn: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var pageContainerView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var feedContentTextView: InsFeedTextView!
    @IBOutlet weak var feedDatetimeLabel: UILabel!
    @IBOutlet weak var backToInsBtn: UIButton!
    
    
    var pageVC: UIPageViewController!
    var currentPage: Int = 0
    
    var webView: UIWebView!
    var axeLink: String = ""
    var axeImg: UIImage?
    var axeVideoURL: URL?
    var insTaxe: InsTaxe?
    var insType: String?
    
    var URLs = [URL]()
    var vcs = [PhotoPageItemVC]()
    var imagesAllSaved = true
    
    var webViewLoaded = false
    var isSavingVideoOrImage = false
    var photosAmountToSave = 0
    var savedPhotosAmount = 0
    var savingHelperCancelBtnPressed = false
    
    var videoSavingQueue: URLSessionDownloadTask?
    
    var axeIVOriginFrame: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        checkPasteboardAndLoadResource()
        
        feedContentTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(copyAllFeedContent(_:))))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let vc = tabBarController?.viewControllers?.first?.childViewControllers.first as? MainVC {
            vc.shouldShowInsTaxe = false
        }
    }
    
    func setupViews() {
        let moreAction = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(InsTaxeVC.moreActionBtnPressed(_:)))
        moreAction.style = .done
        self.navigationItem.rightBarButtonItem = moreAction
        
        webView = UIWebView()
        webView.delegate = self
        
        axeIVOriginFrame = axeIV.frame
        
        savingHelperView.layer.cornerRadius = 5
        savingHelperView.layer.masksToBounds = true
        savingHelperView.clipsToBounds = true
        
        savingHelperCancelBtn.layer.cornerRadius = savingHelperCancelBtn.frame.width / 2
        savingHelperCancelBtn.layer.masksToBounds = true
        savingHelperCancelBtn.clipsToBounds = true
        
        backToInsBtn.isHidden = true
        if let instagramUrl = URL(string: "instagram://app") {
            if let navBar = self.navigationController?.navigationBar {
                backToInsBtn.isHidden = !UIApplication.shared.canOpenURL(instagramUrl)
                backToInsBtn.frame.origin.y = navBar.frame.origin.y + navBar.frame.height + 8
            }
        }
    }

    @objc func copyAllFeedContent(_ sender: Any) {
        if let range = feedContentTextView.selectedTextRange {
            if range.isEmpty {
                feedContentTextView.selectAll(sender)
            } else {
                feedContentTextView.selectedTextRange = nil
            }
        } else {
            feedContentTextView.selectAll(sender)
        }
    }
    
    func checkPasteboardAndLoadResource() {
        if isSavingVideoOrImage { return }
        self.title = ""
        self.axeVideoURL = nil
        videoSavingQueue = nil
        savingHelperCancelBtnPressed = false
        isSavingVideoOrImage = false
        imagesView.isHidden = true
        showVideoBtn.isHidden = true
        pageContainerView.isHidden = true
        loadingLabel.isHidden = true
        feedContentTextView.isHidden = true
        feedDatetimeLabel.isHidden = true
        setIndicatorViewHidden(false)
        let ud = UserDefaults.standard
        self.insType = ud.string(forKey: axeLink + "~type")
        
        // set feed text
        self.feedContentTextView.text = ud.string(forKey: axeLink + "~insFeed")
        
        // set title
        self.title = ud.string(forKey: axeLink + "~insID")
        
        // set datetime
        if let datetime = ud.object(forKey: axeLink + "~insDatetime") as? Date {
            self.feedDatetimeLabel.text = datetimeString(from: datetime)
        }
        
        if let urls = ud.array(forKey: axeLink) as? [String] {
            // image url
            if urls.count == 1 {
                pageContainerView.isHidden = true
                axeIV.sd_setImage(with: URL(string: urls[0]), completed: {
                    image, error, type, url in
                    if let error = error {
                        self.view.notifyc(text: error.localizedDescription, color: orangeColor, nav: self.navigationController)
                        printit(error.localizedDescription)
                    } else {
                        self.axeImg = image
                        self.setIndicatorViewHidden(true)
                        self.showImagesView(true)
                        self.resizeAxeIV(by: image)
                    }
                })
            } else if urls.count > 1 {
                pageContainerView.isHidden = false
                URLs.removeAll()
                vcs.removeAll()
                for url in urls {
                    if url.contains("$i$s@#@v$i$d$e$o$") {
                        // video
                        let imageANDvideo = url.components(separatedBy: "$i$s@#@v$i$d$e$o$")
                        let imageURL = URL(string: imageANDvideo[0])
                        let videoURL = URL(string: imageANDvideo[1])
                        if let imageURL = imageURL, let _ = videoURL {
                            self.URLs.append(imageURL)
                            self.vcs.append(PhotoPageItemVC.instantiateFromStoryboard(url: imageURL, videoURL: videoURL))
                        }
                    } else {
                        // image
                        URLs.append(URL(string: url)!)
                        vcs.append(PhotoPageItemVC.instantiateFromStoryboard(url: URL(string: url)!))
                    }
                }
                pageVC.setViewControllers([vcs.first!], direction: .forward, animated: true, completion: nil)
                setIndicatorViewHidden(true)
                setFeedTextViewAndDatetime(images: true)
            } else {
                if connectedToNetwork() {
                    if let url = URL(string: axeLink) {
                        let request = URLRequest(url: url)
                        webView.loadRequest(request)
                        webViewLoaded = false
                    } else {
                        // wrong link
                        
                    }
                } else {
                    self.view.notifyc(text: "Network unavailable", color: orangeColor, nav: self.navigationController)
                    showLoadingLabel(with: "Check your network and try again...")
                    setIndicatorViewHidden(true)
                }
            }
        } else if let url = ud.url(forKey: axeLink) {
            // video url
            axeVideoURL = url
            if let data = ud.data(forKey: axeLink + "~image") {
                if let image = UIImage(data: data) {
                    axeIV.image = image
                    axeImg = image
                    resizeAxeIV(by: image)
                }
            }
            setIndicatorViewHidden(true)
            showImagesView(false)
        } else {
            if connectedToNetwork() {
                if let url = URL(string: axeLink) {
                    let request = URLRequest(url: url)
                    webView.loadRequest(request)
                    webViewLoaded = false
                } else {
                    // wrong link
                    
                }
            } else {
                self.view.notifyc(text: "Network unavailable", color: orangeColor, nav: self.navigationController)
                showLoadingLabel(with: "Check your network and try again...")
                setIndicatorViewHidden(true)
            }
        }
    }
    
    // MARK: - PageViewController
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? PhotoPageItemVC else { return nil }
        var url = vc.url
        if url == nil { url = vc.axeIV.sd_imageURL() }
        guard let urL = url else { return nil }
        if let index = URLs.index(of: urL) {
            let previousIndex = index - 1
            guard previousIndex >= 0 else {
                return vcs.last
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
        var url = vc.url
        if url == nil { url = vc.axeIV.sd_imageURL() }
        guard let urL = url else { return nil }
        if let index = URLs.index(of: urL) {
            let nextIndex = index + 1
            guard nextIndex < vcs.count else {
                return vcs.first
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
        return URLs.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstVC = vcs.first, let firstVCIndex = vcs.index(of: firstVC) else { return 0 }
        return firstVCIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        guard let vc = pageViewController.viewControllers?.first as? PhotoPageItemVC else { return }
        guard let url = vc.url else { return }
        guard let index = URLs.index(of: url) else { return }
        currentPage = index
    }

    
    @IBAction func backToInsBtnPressed(_ sender: Any) {
        guard let instagramUrl = URL(string: "instagram://app") else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(instagramUrl)
        }
    }
    
    @objc func moreActionBtnPressed(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        var saveTitle = "Save to camera roll"
        var isPhotos = false
        if let type = self.insType {
            if type == "image" && URLs.count > 1 {
                isPhotos = true
                saveTitle = "Save all to camera roll"
            }
        }
        let save = UIAlertAction(title: saveTitle, style: .default, handler: {
            _ in
            self.saveAllToAlbum()
        })
        let saveOneOfPhotos = UIAlertAction(title: "Save this one to camera roll", style: .default, handler: {
            _ in
            self.saveOneToAlbum()
        })
        let share = UIAlertAction(title: "Share", style: .default, handler: {
            _ in
            self.shareAction()
        })
        let reload = UIAlertAction(title: "Reload", style: .default, handler: {
            _ in
            self.reloadAction()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(share)
        alertController.addAction(reload)
        alertController.addAction(save)
        if isPhotos {
            alertController.addAction(saveOneOfPhotos)
        }
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func saveAllToAlbum() {
        // TODO: - check photo library authorization status
        if let type = self.insType {
            switch type {
            case "image":
                if let img = self.axeImg {
                    UIImageWriteToSavedPhotosAlbum(img, self, #selector(InsTaxeVC.image(_:didFinishSavingWithError:contextInfo:)),
                                                   nil)
                } else {
                    // more images
                    self.savedPhotosAmount = 0
                    self.photosAmountToSave = self.vcs.count
                    self.savingVideoPhotoSetup(saving: true, with: "Saving \(self.savedPhotosAmount + 1) of \(self.photosAmountToSave)")
                    self.savingOneOfImage()
                }
            case "video":
                self.saveVideo(url: self.axeVideoURL)
            default:
                break
            }
        }
    }
    
    func saveOneToAlbum() {
        // TODO: - check photo library authorization status
        let vc = self.vcs[self.currentPage]
        if let videoURL = vc.axeVideoURL {
            self.saveVideo(url: videoURL)
        } else if let image = vc.axeIV.image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(InsTaxeVC.image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            self.view.notifyc(text: "The photo is loading, wait a second", nav: self.navigationController)
        }
    }
    
    func shareAction() {
        var items = [Any]()
        if let url = self.axeVideoURL {
            if let title = self.title {
                items.append("\(title) - Instagram")
            }
            items.append(url)
        }
        if let img = self.axeImg {
            items.append(img)
        } else if self.vcs.count > 0 {
            let vc = self.vcs[self.currentPage]
            if vc.axeIV == nil || vc.axeIV.image == nil {
                if let image = vc.image {
                    items.append(image)
                } else if vc.axeIV != nil {
                    if let image = vc.axeIV.image {
                        items.append(image)
                    }
                } else {
                    if let url = vc.url {
                        if let data = try? Data(contentsOf: url) {
                            if let image = UIImage(data: data) {
                                vc.image = image
                                items.append(image)
                            }
                        }
                    }
                }
            } else {
                items.append(vc.axeIV.image!)
            }
        } else {
            return
        }
        
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        activityViewController.completionWithItemsHandler = {
            type, completed, items, error in
            if completed {
                self.view.notifyc(text: "Done", color: greenColor, nav: self.navigationController)
            } else if let error = error {
                self.view.notifyc(text: "Failed: \(error.localizedDescription)", color: orangeColor, nav: self.navigationController)
            }
        }
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = []
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func reloadAction() {
        if connectedToNetwork() {
            if let url = URL(string: self.axeLink) {
                let request = URLRequest(url: url)
                self.setIndicatorViewHidden(false)
                self.imagesView.isHidden = true
                self.pageContainerView.isHidden = true
                self.feedContentTextView.isHidden = true
                self.feedDatetimeLabel.isHidden = true
                self.showVideoBtn.isHidden = true
                self.loadingLabel.isHidden = true
                self.webView.loadRequest(request)
                self.webViewLoaded = false
                self.title = ""
            } else {
                // wrong link
                
            }
        } else {
            self.view.notifyc(text: "Network unavailable", color: orangeColor, nav: self.navigationController)
            self.showLoadingLabel(with: "Check your network and try again...")
            self.setIndicatorViewHidden(true)
        }
    }
    
    func saveVideo(url: URL?, showToast: Bool = true) {
        guard let url = url else { return }
        if showToast {
            if self.isSavingVideoOrImage { return }
            self.savingVideoPhotoSetup(saving: true, with: "Be patient for large video file")
        }
        DispatchQueue.global(qos: .background).async {
            self.videoSavingQueue = (URLSession.shared.downloadTask(with: url) {
                (location: URL?, r: URLResponse?, e: Error?) -> Void in
                let mgr = FileManager.default
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                
                let destination = URL(string: NSString(format: "%@/%@", documentsPath, url.lastPathComponent) as String)

                if let atPath = location?.path, let toPath = destination?.path {
                    try? mgr.moveItem(atPath: atPath, toPath: toPath)
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destination!)
                }) {
                    saved, error in
                    guard showToast else {
                        DispatchQueue.main.async {
                            self.savingOneOfImage()
                        }
                        return
                    }
                    if saved {
                        let alert = UIAlertController(title: "Saved", message: "Video saved successfully", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cool", style: .default))
                        if #available(iOS 10.0, *) {
                            alert.addAction(UIAlertAction(title: "Go Instagram", style: .destructive, handler: {
                                _ in
                                let instagramUrl = URL(string: "instagram://app")!
                                UIApplication.shared.canOpenURL(instagramUrl)
                                UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
                            }))
                        }
                        self.tabBarController?.present(alert, animated: true, completion: {
                            self.savingVideoPhotoSetup(saving: false)
                        })
                    } else {
                        let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Well", style: .default))
                        self.tabBarController?.present(alert, animated: true, completion: {
                            self.savingVideoPhotoSetup(saving: false)
                        })
                    }
                }
            })
            self.videoSavingQueue?.resume()
        }
    }
    
    func savingVideoPhotoSetup(saving: Bool, with text: String = "") {
        self.isSavingVideoOrImage = saving
        self.savingHelperView.isHidden = !saving
        self.savingHelperLabel.text = text
        self.tabBarController?.tabBar.isUserInteractionEnabled = !saving
        self.navigationController?.navigationBar.isUserInteractionEnabled = !saving
        self.pageContainerView.isUserInteractionEnabled = !saving
        self.showVideoBtn.isUserInteractionEnabled = !saving
        if saving {
            self.indicatorView.startAnimating()
        } else {
            self.indicatorView.stopAnimating()
        }
    }
    
    @IBAction func savingHelperCancelBtnPressed(_ sender: Any) {
        savingVideoPhotoSetup(saving: false)
        savingHelperCancelBtnPressed = true
        videoSavingQueue?.cancel()
        
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Well", style: .default))
            if #available(iOS 10.0, *) {
                alert.addAction(UIAlertAction(title: "Go Instagram", style: .destructive, handler: {
                    _ in
                    let instagramUrl = URL(string: "instagram://app")!
                    UIApplication.shared.canOpenURL(instagramUrl)
                    UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
                }))
            }
            
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Saved", message: "Image saved successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cool", style: .default))
            if #available(iOS 10.0, *) {
                alert.addAction(UIAlertAction(title: "Go Instagram", style: .destructive, handler: {
                    _ in
                    let instagramUrl = URL(string: "instagram://app")!
                    UIApplication.shared.canOpenURL(instagramUrl)
                    UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
                }))
            }
            
            present(alert, animated: true)
        }
    }
    
    @objc func images(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            self.savingVideoPhotoSetup(saving: false)
            self.imagesAllSaved = false
            printit(error.localizedDescription)
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Well", style: .default, handler: {
                _ in
                self.imagesAllSaved = true
            }))
            if #available(iOS 10.0, *) {
                alert.addAction(UIAlertAction(title: "Go Instagram", style: .destructive, handler: {
                    _ in
                    self.imagesAllSaved = true
                    let instagramUrl = URL(string: "instagram://app")!
                    UIApplication.shared.canOpenURL(instagramUrl)
                    UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
                }))
            }
            
            present(alert, animated: true)
        } else {
            if self.savingHelperCancelBtnPressed {
                self.savingHelperCancelBtnPressed = false
                return
            }
            savingOneOfImage()
        }
    }

    func savingOneOfImage() {
        if savedPhotosAmount == photosAmountToSave && imagesAllSaved {
            self.savingVideoPhotoSetup(saving: false)
            let alert = UIAlertController(title: "Saved", message: "\(photosAmountToSave) images saved successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cool", style: .default))
            if #available(iOS 10.0, *) {
                alert.addAction(UIAlertAction(title: "Go Instagram", style: .destructive, handler: {
                    _ in
                    let instagramUrl = URL(string: "instagram://app")!
                    UIApplication.shared.canOpenURL(instagramUrl)
                    UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
                }))
            }
            
            present(alert, animated: true)
        } else {
            let helperLabelText = "Saving \(self.savedPhotosAmount + 1) of \(self.photosAmountToSave)"
            if self.savedPhotosAmount + 1 <= self.photosAmountToSave {
                self.savingHelperLabel.text = helperLabelText
            }
            let vc = self.vcs[self.savedPhotosAmount]
            if let url = vc.axeVideoURL {
                self.saveVideo(url: url, showToast: false)
                self.savedPhotosAmount += 1
            } else if vc.axeIV == nil {
                if let url = vc.url {
                    if let data = try? Data(contentsOf: url) {
                        if let image = UIImage(data: data) {
                            UIImageWriteToSavedPhotosAlbum(image, self, #selector(InsTaxeVC.images(_:didFinishSavingWithError:contextInfo:)), nil)
                            self.savedPhotosAmount += 1
                            return
                        }
                    }
                }
            } else if let image = vc.axeIV.image {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(InsTaxeVC.images(_:didFinishSavingWithError:contextInfo:)), nil)
                self.savedPhotosAmount += 1
                return
            }
        }
    }
    
    
    // MARK: - WebView
    func webViewDidStartLoad(_ webView: UIWebView) {
        
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if let title = self.title {
            if title != "" { return }
        }
        //printit("error: \(error.localizedDescription)")
        if webView.getReadyState() == "complete" {
            setIndicatorViewHidden(true)
            view.notifyc(text: error.localizedDescription, color: orangeColor, nav: navigationController)
            showLoadingLabel(with: "Check your network and try again...")
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let webState = webView.getReadyState()
        let shouldFinishLoading = webState == "complete" //|| webState == "interactive"
        if shouldFinishLoading && !webViewLoaded {
            self.webViewLoaded = true
            if webView.retrieve404() {
                setIndicatorViewHidden(true)
                navigationController?.view.notifyc(text: "Sorry, this page isn't available", color: orangeColor, nav: self.navigationController)
                performSegue(withIdentifier: "unwindFromInsTaxeToMain", sender: webView)
                return
            }
            UserDefaults.standard.set("", forKey: axeLink + "~insID")
            UserDefaults.standard.set("", forKey: axeLink + "~insFeed")
            UserDefaults.standard.set(nil, forKey: axeLink + "~insDatetime")
            self.feedDatetimeLabel.text = ""
            if let datetime = webView.retrieveDatetime() {
                if let datetime = dateFormatter(date: datetime) {
                    UserDefaults.standard.set(datetime, forKey: axeLink + "~insDatetime")
                    self.feedDatetimeLabel.text = datetimeString(from: datetime)
                }
            }
            self.title = nil
            self.feedContentTextView.text = nil
            if let feeds = webView.retrieveFeedText() {
                if feeds == "" {
                    // personal homepage
                    if let link = webView.request?.url?.absoluteString {
                        let strs = link.components(separatedBy: "instagram.com/")
                        let idANDurl = strs[strs.count - 1].components(separatedBy: "/")
                        let id = idANDurl[0]
                        self.title = id
                        self.feedContentTextView.isHidden = true
                        UserDefaults.standard.set(id, forKey: axeLink + "~insID")
                    }
                } else {
                    // feed webpage
                    let feeds = feeds.components(separatedBy: "@#$#@||")
                    if feeds.count == 2 {
                        let id = feeds[0]
                        let feed = feeds[1]
                        self.title = id
                        self.feedContentTextView.text = feed
                        self.feedContentTextView.isHidden = false
                        UserDefaults.standard.set(id, forKey: axeLink + "~insID")
                        UserDefaults.standard.set(feed, forKey: axeLink + "~insFeed")
                    }
                }
            }
            if let insTaxe = webView.retrieveImageOrVideo() {
                self.insTaxe = insTaxe
                self.axeImg = nil
                self.axeIV.image = nil
                self.URLs.removeAll()
                self.vcs.removeAll()
                let ud = UserDefaults.standard
                switch insTaxe.type {
                case .image:
                    self.insType = "image"
                    ud.set("image", forKey: axeLink + "~type")
                    let urls = insTaxe.urls
                    if urls.count == 1 {
                        // one image
                        showLoadingLabel(with: "Loading the photo...")
                        pageContainerView.isHidden = true
                        if let url = URL(string: urls[0]) {
                            showImagesView(true)
                            axeIV.sd_setImage(with: url, completed: {
                                image, error, type, url in
                                self.axeImg = image
                                let ud = UserDefaults.standard
                                ud.set([urls[0]], forKey: self.axeLink)
                                self.loadingLabel.isHidden = true
                                self.setIndicatorViewHidden(true)
                                self.view.notifyc(text: "Loaded one photo", nav: self.navigationController)
                                self.resizeAxeIV(by: image)
                            })
                        }
                    } else {
                        // more than one image
                        self.showLoadingLabel(with: "Loading the \(urls.count) photos...")
                        self.pageContainerView.isHidden = false
                        let group = DispatchGroup()
                        for urlStr in urls {
                            group.enter()
                            if urlStr.contains("$i$s@#@v$i$d$e$o$") {
                                let imageANDvideo = urlStr.components(separatedBy: "$i$s@#@v$i$d$e$o$")
                                let imageURL = URL(string: imageANDvideo[0])
                                let videoURL = URL(string: imageANDvideo[1])
                                if let imageURL = imageURL, let _ = videoURL {
                                    self.URLs.append(imageURL)
                                    self.vcs.append(PhotoPageItemVC.instantiateFromStoryboard(url: imageURL, videoURL: videoURL))
                                    group.leave()
                                }
                            } else if let url = URL(string: urlStr) {
                                self.URLs.append(url)
                                self.vcs.append(PhotoPageItemVC.instantiateFromStoryboard(url: url))
                                group.leave()
                            } else {
                                
                            }
                        }
                        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
                            let ud = UserDefaults.standard
                            ud.set(urls, forKey: self.axeLink)
                            self.pageVC.setViewControllers([self.vcs.first!], direction: .forward, animated: true, completion: nil)
                            self.loadingLabel.isHidden = true
                            self.setIndicatorViewHidden(true)
                            self.setFeedTextViewAndDatetime(images: true)
                            self.view.notifyc(text: "Loaded \(self.vcs.count) photos", nav: self.navigationController)
                        }))
                    }
                case .video:
                    showLoadingLabel(with: "Loading the video...")
                    self.insType = "video"
                    ud.set("video", forKey: axeLink + "~type")
                    if let url = URL(string: insTaxe.urls[0]) {
                        showImagesView(false)
                        axeVideoURL = url
                        ud.set(url, forKey: axeLink)
                    }
                    if let url = URL(string: insTaxe.urls[1]) {
                        showImagesView(false)
                        let data = try? Data(contentsOf: url)
                        if let data = data {
                            if let image = UIImage(data: data) {
                                axeIV.image = image
                                axeImg = image
                                ud.set(data, forKey: axeLink + "~image")
                                resizeAxeIV(by: image)
                            }
                        }
                    }
                    loadingLabel.isHidden = true
                    setIndicatorViewHidden(true)
                    self.view.notifyc(text: "Loaded one video", nav: self.navigationController)
                case .none:
                    break
                case .some(_):
                    break
                }
                if ud.bool(forKey: "autoSave") {
                    self.saveAllToAlbum()
                }
            }
        }
    }

    func datetimeString(from date: Date) -> String {
        let calendar = Calendar.current
        let cs = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day, .weekday], from: date)
        guard let year = cs.year else { return "" }
        guard let month = cs.month else { return "" }
        guard let day = cs.day else { return "" }
        guard let hour = cs.hour else { return "" }
        guard let minute = cs.minute else { return "" }
        guard let second = cs.second else { return "" }
        guard let weekday = cs.weekday else { return "" }
        return numParser(hour) + ":" + numParser(minute) + ":" + numParser(second) + "  \(monthParser(month)) \(day), \(year)  \(weekdayParser(weekday))"
    }
    
    func numParser(_ n: Int) -> String {
        if n < 10 {
            return "0\(n)"
        } else {
            return "\(n)"
        }
    }
    
    func weekdayParser(_ d: Int) -> String {
        switch d {
        case 1:
            return "Sun."
        case 2:
            return "Mon."
        case 3:
            return "Tue."
        case 4:
            return "Wed."
        case 5:
            return "Thu."
        case 6:
            return "Fri."
        case 7:
            return "Sat."
        default:
            return ""
        }
    }
    
    func monthParser(_ m: Int) -> String {
        switch m {
        case 1:
            return "JANUARY"
        case 2:
            return "FEBRUARY"
        case 3:
            return "MARCH"
        case 4:
            return "APRIL"
        case 5:
            return "MAY"
        case 6:
            return "JUNE"
        case 7:
            return "JULY"
        case 8:
            return "AUGUST"
        case 9:
            return "SEPTEMBER"
        case 10:
            return "OCTOBER"
        case 11:
            return "NOVEMBER"
        case 12:
            return "DECEMBER"
        default:
            return ""
        }
    }
    
    func showLoadingLabel(with text: String) {
        loadingLabel.isHidden = false
        loadingLabel.text = text
    }
    
    func resizeAxeIV(by image: UIImage?) {
        guard let image = image else { return }
        axeIV.frame = axeIVOriginFrame
        let height = image.size.height / image.size.width * view.frame.width
        if height < axeIV.frame.height {
            axeIV.frame.origin.y = (imagesView.frame.height - height) / 2
            axeIV.frame.size.height = height
        }
        setFeedTextViewAndDatetime(images: false)
    }
    
    func setFeedTextViewAndDatetime(images: Bool) {
        self.feedContentTextView.isHidden = false
        self.feedDatetimeLabel.isHidden = false
        self.view.bringSubview(toFront: feedContentTextView)
        self.view.bringSubview(toFront: feedDatetimeLabel)
        var y = axeIV.frame.origin.y + axeIV.frame.height + imagesView.frame.origin.y
        if images {
            y = pageContainerView.frame.origin.y + pageContainerView.frame.height - 8
            feedDatetimeLabel.frame.origin.y = pageContainerView.frame.origin.y
        } else {
            feedDatetimeLabel.frame.origin.y = axeIV.frame.origin.y + imagesView.frame.origin.y - 8 - feedDatetimeLabel.frame.height
        }
        feedContentTextView.frame.origin.y = y + 14
        feedContentTextView.frame.size.height = tabBarController!.tabBar.frame.origin.y - y - 36
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else { return }
        switch id {
        case "pageEmbededVC":
            guard let vc = segue.destination as? UIPageViewController else { return }
            self.pageVC = vc
            self.pageVC.delegate = self
            self.pageVC.dataSource = self
            let pageControl = UIPageControl.appearance()
            pageControl.pageIndicatorTintColor = UIColor.lightGray
            pageControl.currentPageIndicatorTintColor = UIColor.black
            pageControl.backgroundColor = UIColor.white
        default:
            break
        }
    }
        
    @IBAction func showVideoBtnPressed(_ sender: Any) {
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
    
    
    func setIndicatorViewHidden(_ shouldHidden: Bool) {
        if shouldHidden {
            indicatorView.stopAnimating()
        } else {
            imagesView.isHidden = true
            showVideoBtn.isHidden = true
            indicatorView.startAnimating()
        }
        indicatorView.isHidden = shouldHidden
    }
    
    func showImagesView(_ shouldShow: Bool) {
        imagesView.isHidden = false
        showVideoBtn.isHidden = shouldShow
    }
    
    func dateFormatter(date string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.date(from: string)
    }
    
}

