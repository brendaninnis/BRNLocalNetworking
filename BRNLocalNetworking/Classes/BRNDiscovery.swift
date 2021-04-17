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
        
        return NetService(domain: "local.", type: "_BRNLocalNetworking._tcp", name: "BRNLocalNetworking", port: Int32(port))
    }()
    
    public func start() {
        startPeerBroadcast()
        startDiscovery()
    }
    
    private func startPeerBroadcast() {
        netService?.delegate = self
        netService?.setTXTRecord(NetService.data(fromTXTRecord: [
            "Hello": "World!".data(using: .utf8)!
        ]))
        netService?.publish()
    }
    
    private func startDiscovery() {
        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: "_BRNLocalNetworking._tcp", inDomain: "local.")
    }
    
    private func isPreferredServer() -> Bool {
        return true
    }
}

// MARK: -
// MARK: NetServiceBrowserDelegate

extension BRNDiscovery: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("NetServiceBrowser did not search: \(errorDict)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("NetServiceBrowser did find: \(service)")
        guard let data = service.txtRecordData() else {
            print("Error: NetService textRecordData == nil")
            return
        }
        let dict = NetService.dictionary(fromTXTRecord: data)
        print(dict)
        if let data = dict["Hello"] {
            print(String(data: data, encoding: .utf8) ?? "Error deserializing Hello String")
        }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
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
    }
    
    // Host
    func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour Service Published: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) port(\(sender.port))")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Failed to publish Bonjour Service domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name))\n\(errorDict)")
    }
}
