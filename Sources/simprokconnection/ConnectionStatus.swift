//
//  File.swift
//  
//
//  Created by Andriy Prokhorenko on 10.04.2023.
//


public enum ConnectionStatus {
    case connected(type: ConnectionType, isExpensive: Bool)
    case disconnected
    case unknown
    
    
    public var isConnected: Bool? {
        switch self {
        case .connected:
            return true
        case .disconnected:
            return false
        case .unknown:
            return nil
        }
    }
    
    public var isExpensive: Bool? {
        switch self {
        case .unknown, .disconnected:
            return false
        case .connected(_, let isExpensive):
            return isExpensive
        }
    }
    
    public enum ConnectionType {
        case cellular
        case wifi
        case wiredEthernet
        case loopback
        case other
    }
}
