//
//  InsTaxe.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import Foundation
import SystemConfiguration

enum InsResourceType {
    case image, video
}

class InsTaxe {
    
    let type: InsResourceType!
    var urls = [String]()
    
    init(type: InsResourceType, urls: [String]) {
        self.type = type
        self.urls = urls
    }
    
}

func isFromIns(_ copiedLink: String) -> Bool {
    let insStr = "https://www.instagram.com/p/"
    let insStr1 = "http://www.instagram.com/p/"
    let insStr0 = "www.instagram.com/p/"
    let insStr2 = "https://instagram.com/p/"
    let insStr3 = "http://instagram.com/p/"
    let insStr4 = "instagram.com/p/"
    let isTweet = (copiedLink.starts(with: insStr) && copiedLink != insStr) ||
        (copiedLink.starts(with: insStr0) && copiedLink != insStr0) ||
        (copiedLink.starts(with: insStr2) && copiedLink != insStr2) ||
        (copiedLink.starts(with: insStr4) && copiedLink != insStr4) ||
        (copiedLink.starts(with: insStr3) && copiedLink != insStr3) ||
        (copiedLink.starts(with: insStr1) && copiedLink != insStr1)
    
    let insStr5 = "instagram.com/"
    let insStr9 = "http://instagram.com/"
    let insStr10 = "https://instagram.com/"
    let insStr6 = "www.instagram.com/"
    let insStr7 = "http://www.instagram.com/"
    let insStr8 = "https://www.instagram.com/"
    let isProfile = (copiedLink.starts(with: insStr5) && copiedLink != insStr5) ||
        (copiedLink.starts(with: insStr6) && copiedLink != insStr6) ||
        (copiedLink.starts(with: insStr7) && copiedLink != insStr7) ||
        (copiedLink.starts(with: insStr8) && copiedLink != insStr8) ||
        (copiedLink.starts(with: insStr9) && copiedLink != insStr9) ||
        (copiedLink.starts(with: insStr10) && copiedLink != insStr10)
    
    return isTweet || isProfile
}

let appID = "1294551111"
let wbAppID = "1294551111"

// check if is connected to the network
func connectedToNetwork() -> Bool {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            SCNetworkReachabilityCreateWithAddress(nil, $0)
        }
    }) else {
        return false
    }
    
    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
        return false
    }
    
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    
    return (isReachable && !needsConnection)
}

