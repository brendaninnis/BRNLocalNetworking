//
//  BRNLocalNetworking.swift
//  BRNLocalNetworking
//
//  Created by Brendan Innis on 2021-04-17.
//

import Foundation

public class BRNLocalNetworking {
    public static let sharedInstance = BRNLocalNetworking()
    
    private var networkingQueue = DispatchQueue(label: "BRNLocalNetworkingQueue", qos: .userInitiated)
    private let discovery = BRNDiscovery()
    
    private var hostAfterTask: DispatchWorkItem?
    
    private init() { }
    
    public func setNetworkingQueue(_ queue: DispatchQueue) {
        networkingQueue = queue
    }
    
    public func startAutoJoinOrHost() {
        print("BRNLocalNetworking - Starting automatic host or join")
//        networkingQueue.async {
            self.discovery.start()
//        }
    }
    
    public func startJoining() {
        print("BRNLocalNetworking - Starting joining")
//
//        // After 3 seconds, if no service has been found, start one
//        hostAfterTask = DispatchWorkItem {
//            if self.discovery.isPreferredServer() {
//                self.startHosting()
//            } else {
//                self.networkingQueue.asyncAfter(deadline: .now() + 3, execute: self.hostAfterTask!)
//            }
//        }
//
//        networkingQueue.asyncAfter(deadline: .now() + 3, execute: hostAfterTask!)
    }
    
    public func startHosting() {
        print("BRNLocalNetworking - Starting hosting")
        
    }
}
