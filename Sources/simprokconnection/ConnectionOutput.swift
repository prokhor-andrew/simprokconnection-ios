//
//  File.swift
//  
//
//  Created by Andriy Prokhorenko on 10.04.2023.
//

public enum ConnectionOutput {
    case didLaunchGetting
    case didCancelGetting
    case didGetStatus(ConnectionStatus)
    
    case didStartListening
    case didStopListening
    case didReceiveStatus(ConnectionStatus)
}
