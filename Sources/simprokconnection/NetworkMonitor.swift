//
//  NetworkConnectivityManager.swift
//  NetworkConnectivity
//
//  Created by Aryaman Sharda on 2/18/22.
//

import Foundation
import Network
import simprokmachine


extension NWInterface.InterfaceType: CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}

final class NetworkMonitor {
    
    static let shared = NetworkMonitor()

    private var subs: [ObjectIdentifier: Handler<ConnectionStatus>] = [:]
    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")
    private let monitor: NWPathMonitor

    
    private func send(_ event: ConnectionStatus) {
        subs.values.forEach { $0(event) }
    }

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status != .unsatisfied {
                self?.send(.disconnected)
            } else {
                
                if let status = NWInterface.InterfaceType.allCases.filter({ path.usesInterfaceType($0) }).first {
                    let isExpensive = path.isExpensive
                    switch status {
                    case .wifi:
                        self?.send(.connected(type: .wifi, isExpensive: isExpensive))
                    case .cellular:
                        self?.send(.connected(type: .cellular, isExpensive: isExpensive))
                    case .loopback:
                        self?.send(.connected(type: .loopback, isExpensive: isExpensive))
                    case .wiredEthernet:
                        self?.send(.connected(type: .wiredEthernet, isExpensive: isExpensive))
                    case .other:
                        self?.send(.connected(type: .other, isExpensive: isExpensive))
                    @unknown default:
                        self?.send(.unknown)
                    }
                } else {
                    self?.send(.unknown)
                }
            }
        }
    }
    
    deinit {
        subs.removeAll()
    }
    
    
    @discardableResult
    func startMonitoring(object: AnyObject, handler: @escaping Handler<ConnectionStatus>) -> Bool {
        let id = ObjectIdentifier(object)
        guard subs[id] != nil else {
            return false
        }
        
        subs[id] = handler
        
        if subs.count == 1 {
            monitor.start(queue: queue)
        }
        
        return true
    }

    @discardableResult
    func stopMonitoring(object: AnyObject) -> Bool {
        let id = ObjectIdentifier(object)
        guard subs[id] != nil else {
            return false
        }
        
        subs[id] = nil
        
        if subs.count == 0 {
            monitor.cancel()
        }
        
        return true
    }
}
