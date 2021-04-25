//
//  BRNDiscovery.swift
//  BRNLocalNetworking
//
//  Created by Brendan Innis on 2021-04-17.
//

import Foundation
import CocoaAsyncSocket

internal class BRNDiscovery: NSObject {
    
    private lazy var socketQueue: DispatchQueue = {
        DispatchQueue(label: "SocketQueue")
    }()
    
    private var socket: GCDAsyncSocket?
    
    private var browserRunning = false
    private lazy var netServiceBrowser: NetServiceBrowser = {
        return NetServiceBrowser()
    }()
    
    private lazy var netService: NetService? = {
        // Create the listen socket
        socket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)
        do {
            try socket?.accept(onPort: 0)
        } catch let error {
            print("ERROR: \(error)")
            return nil
        }

        let port = socket!.localPort
        let name = "BRNLocalNetworking-\(getRandomNameSuffix())"
        
        return NetService(domain: "local.", type: "_BRNLocalNetworking._tcp", name: name, port: Int32(port))
    }()
    private var discoveredServices: [NetService] = []
    
    public func start() {
        print("Start Discovery")
        startPeerBroadcast()
        startDiscovery()
    }
    
    private func startPeerBroadcast() {
        print("Starting peer broadcast")
        netService?.delegate = self
        netService?.publish()
    }
    
    private func startDiscovery() {
        guard !browserRunning else {
            return
        }
        print("Starting peer discovery")
        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: "_BRNLocalNetworking._tcp", inDomain: "local.")
        browserRunning = true
    }
    
    private func isPreferredServer() -> Bool {
        return true
    }
    
    private func getRandomNameSuffix() -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = 8

        let randomString : NSMutableString = NSMutableString(capacity: len)

        for _ in 1...len{
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString
    }
}

// MARK: -
// MARK: NetServiceBrowserDelegate

extension BRNDiscovery: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("NetServiceBrowser did not search: \(errorDict)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard service != netService else {
            return
        }
        guard !discoveredServices.contains(service) else {
            return
        }
        discoveredServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        browserRunning = false
        print("NetServiceBrowser did stop search")
    }
}

// MARK: -
// MARK: GCDAsyncSocketDelegate

extension BRNDiscovery: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Socket did connect to host \(host) on port \(port)")
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Socket did accept new socket \(newSocket)")

    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("Socket did read data with tag \(tag)")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("Socket did disconnect \(err?.localizedDescription ?? "")")
    }
}

// MARK: -
// MARK: NetServiceDelegate

extension BRNDiscovery: NetServiceDelegate {
    // Client
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("NetService did not resolve: \(errorDict)")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("NetService did resolve: \(sender)")
        
        // Subscribe to TXT record updates
        sender.startMonitoring()
    }
    
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        let dict = NetService.dictionary(fromTXTRecord: data)
        print(dict)
        if let data = dict["Hello"] {
            print(String(data: data, encoding: .utf8) ?? "Error deserializing Hello String")
        }
    }
    
    // Host
    func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour Service Published: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) port(\(sender.port))")
        
        if !sender.setTXTRecord(NetService.data(fromTXTRecord: [
            "Hello": "World!".data(using: .utf8)!
        ])) {
            print("Failed to set TXTRecord")
        }
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Failed to publish Bonjour Service domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name))\n\(errorDict)")
        // TODO: Catch NetServicesCollisionError -72001 and publish with a new name
    }
}
