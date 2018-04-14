//
//  UIWebView+Extenstions.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import WebKit

extension UIWebView {
    
    func retrieve404() -> Bool {
        guard let error = self.stringByEvaluatingJavaScript(from: "document.getElementsByClassName('dialog-404')[0].textContent;") else { return true }
        return error.contains("The link you followed may be broken, or the page may have been removed.")
    }
    
    func retrieveImageOrVideo() -> InsTaxe? {
        //display_url
        stringByEvaluatingJavaScript(from: "var script = document.createElement('script');script.type = 'text/javascript';script.text = function retrieveIorV() { var metas = document.getElementsByTagName('meta'); var image = ''; var video = ''; for (var i=0; i<metas.length; i++) { if (metas[i].getAttribute('property') == 'og:video') { video = 'video@#$#@||' + metas[i].getAttribute('content');} else if (metas[i].getAttribute('property') == 'og:image') {image = metas[i].getAttribute('content');} } if(video != ''){ return video + '@#$#@||' + image} else { return 'image@#$#@||' + image; }}; document.getElementsByTagName('head')[0].appendChild(script);")
        stringByEvaluatingJavaScript(from: "var script = document.createElement('script');script.type = 'text/javascript';script.text = function retrieveSharedData() { var scripts = document.getElementsByTagName('script'); var n = 0; for (var i=0; i<scripts.length; i++) {if(scripts[i].text.indexOf('window._sharedData') != -1) { if(n==1) {return scripts[i].text;} n++; }} return ''; }; document.getElementsByTagName('head')[0].appendChild(script);")
        guard let sharedData = self.stringByEvaluatingJavaScript(from: "retrieveSharedData();") else { return nil }
        var sharedDataPhoto = sharedData.components(separatedBy: "display_url")
        if sharedDataPhoto.count < 4 {
            // one element
            guard let typeUrl = self.stringByEvaluatingJavaScript(from: "retrieveIorV();") else { return nil }
            var urls = typeUrl.components(separatedBy: "@#$#@||")
            if urls.count > 1 {
                var type: InsResourceType = .image
                if urls[0] == "video" { type = .video }
                urls.remove(at: 0)
                let insTaxe = InsTaxe(type: type, urls: urls)
                return insTaxe
            } else {
                return nil
            }
        } else {
            // more than one element
            var urls = [String]()
            sharedDataPhoto.remove(at: 0)
            sharedDataPhoto.remove(at: 0)
            for str in sharedDataPhoto {
                var srcs = str.components(separatedBy: "display_resources")
                if srcs.count > 1 {
                    var url = srcs[0]
                    url = url.substring(to: String.Index(encodedOffset: url.count - 3))
                    url = url.substring(from: String.Index(encodedOffset: 3))
                    if srcs[1].contains("is_video\":true") {
                        var videoURL = ""
                        let sharedDataVideo = srcs[1].components(separatedBy: "video_url")
                        if sharedDataVideo.count > 1 {
                            let videoStr = sharedDataVideo[1]
                            videoURL = videoStr.substring(from: String.Index(encodedOffset: 3))
                            let urls = videoURL.components(separatedBy: "\",\"video_")
                            if urls.count > 1 {
                                videoURL = urls[0]
                            }
                        }
                        url += ("$i$s@#@v$i$d$e$o$" + videoURL)
                    }
                    urls.append(url)
                }
            }
            let type: InsResourceType = .image
            let insTaxe = InsTaxe(type: type, urls: urls)
            return insTaxe
        }

    }
    
    
    func retrieveFeedText() -> String? {
        //display_url
        stringByEvaluatingJavaScript(from: "var script = document.createElement('script'); script.type = 'text/javascript'; script.text = function retrieveFeedContent() { var metas = document.getElementsByTagName('meta');var id = '';for (var i=0; i<metas.length; i++) { if (metas[i].getAttribute('property') == 'og:description') {var str=metas[i].getAttribute('content');var start = str.indexOf('(@')+2; var end = str.indexOf(')'); if (start==1) {start=str.indexOf('@')+1; var end = str.indexOf(' on Instagram'); } id=str.substring(start, end);}} var uls = document.getElementsByTagName('ul'); var text = ''; if(uls.length==0){return '';} for (var i=0; i<uls.length; i++) { if (uls[i].getElementsByTagName('li')[0].getElementsByTagName('a')[0].textContent==id) { text=uls[i].getElementsByTagName('li')[0].getElementsByTagName('span')[0].textContent; break; } }  return id+'@#$#@||'+text; }; document.getElementsByTagName('head')[0].appendChild(script);")
        guard let feedText = self.stringByEvaluatingJavaScript(from: "retrieveFeedContent();") else { return nil }
        return feedText
    }
    
    func retrieveDatetime() -> String? {
        //display_url
        stringByEvaluatingJavaScript(from: "var script = document.createElement('script');script.type = 'text/javascript';script.text = function retrieveDatetime() { var time = document.getElementsByTagName('time'); for (var i=0; i<time.length; i++) { return time[i].getAttribute('datetime'); } return ''; }; document.getElementsByTagName('head')[0].appendChild(script);")
        guard let title = self.stringByEvaluatingJavaScript(from: "retrieveDatetime();") else { return nil }
        return title
    }
    
    
    func getReadyState() -> String {
        let state = self.stringByEvaluatingJavaScript(from: "document.readyState")
        return state ?? ""
    }

}

