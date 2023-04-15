import simprokmachine
import simproktools
import simprokstate

public extension Machine {
    
    private class Holder {}
    
    private static func cancelGet() -> Outline<ConnectionOutput, ConnectionInput, ConnectionInput, ConnectionOutput> {
        OutlineBuilder()
            .when { trigger in
                switch trigger {
                case .ext(.willCancelGetting):
                    return [.int(.willCancelGetting)]
                default:
                    return nil
                }
            }
            .when { trigger in
                switch trigger {
                case .int(.didCancelGetting):
                    return [.ext(.didCancelGetting)]
                default:
                    return nil
                }
            }
            .build(.finale())
    }
    
    private static func launchGet() -> Outline<ConnectionOutput, ConnectionInput, ConnectionInput, ConnectionOutput> {
        OutlineBuilder()
            .when { trigger in
                switch trigger {
                case .ext(.willLaunchGetting):
                    return [ .int(.willLaunchGetting)]
                default:
                    return nil
                }
            }
            .handle { state in
                state.switchOnTransition(to: cancelGet())
            }
            .when { trigger in
                switch trigger {
                case .int(.didLaunchGetting):
                    return [.ext(.didLaunchGetting)]
                default:
                    return nil
                }
            }
            .when { trigger in
                switch trigger {
                case .int(.didGetStatus(let status)):
                    return [.ext(.didGetStatus(status))]
                default:
                    return nil
                }
            }
            .build(.finale())
    }
    
    private static func cancelListening() -> Outline<ConnectionOutput, ConnectionInput, ConnectionInput, ConnectionOutput> {
        OutlineBuilder()
            .when { trigger in
                switch trigger {
                case .ext(.willStopListening):
                    return [.int(.willStopListening)]
                default:
                    return nil
                }
            }
            .when { trigger in
                switch trigger {
                case .int(.didStopListening):
                    return [.ext(.didStopListening)]
                default:
                    return nil
                }
            }
            .build(.finale())
    }
    
    private static func launchListening() -> Outline<ConnectionOutput, ConnectionInput, ConnectionInput, ConnectionOutput> {
        OutlineBuilder()
            .when { trigger in
                switch trigger {
                case .ext(.willStartListening):
                    return [.int(.willStartListening)]
                default:
                    return nil
                }
            }
            .handle { state in
                state.switchOnTransition(to: cancelListening())
            }
            .when { trigger in
                switch trigger {
                case .int(.didStartListening):
                    return [.ext(.didStartListening)]
                default:
                    return nil
                }
            }
            .loop { event in
                switch event {
                case .int(.didReceiveStatus(let status)):
                    return (true, [.ext(.didReceiveStatus(status))])
                default:
                    return (true, [])
                }
            }
            .build(.finale())
    }
    
    static func connection() -> Machine<Input, Output> where Input == IdData<String, ConnectionInput>, Output == IdData<String, ConnectionOutput> {
        Machine.source(
            typeIntTrigger: ConnectionOutput.self,
            typeIntEffect: ConnectionInput.self,
            typeExtTrigger: ConnectionInput.self,
            typeExtEffect: ConnectionOutput.self,
            typeRequest: ExecutableRequest.self,
            typeResponse: ConnectionStatus.self,
            typeLaunchReason: Void.self,
            typeCancelReason: Void.self,
            outlines: [
                { _ in launchGet() },
                { _ in launchListening() }
            ]
        ) {
            ()
        } mapReq: { _, event in
            switch event {
            case .willLaunchGetting:
                return ((), .int(.willLaunch(id: "get", reason: (), isLaunchOnMain: false, request: .get)))
            case .willCancelGetting:
                return ((), .int(.willCancel(id: "get", reason: ())))
            case .willStartListening:
                return ((), .int(.willLaunch(id: "listen", reason: (), isLaunchOnMain: false, request: .listen)))
            case .willStopListening:
                return ((), .int(.willCancel(id: "listen", reason: ())))
            }
        } mapRes: { _, event in
            switch event {
            case .didLaunch(let id, _):
                switch id {
                case "get":
                    return ((), .ext(.didLaunchGetting))
                case "listen":
                    return ((), .ext(.didStartListening))
                default:
                    return ((), nil)
                }
            case .didCancel(let id, _):
                switch id {
                case "get":
                    return ((), .ext(.didCancelGetting))
                case "listen":
                    return ((), .ext(.didStopListening))
                default:
                    return ((), nil)
                }
            case .didEmit(let id, let status):
                switch id {
                case "get":
                    return ((), .ext(.didGetStatus(status)))
                case "listen":
                    return ((), .ext(.didReceiveStatus(status)))
                default:
                    return ((), nil)
                }
            }
        } holder: {
            Holder()
        } onLaunch: { holder, req, callback in
            switch req {
            case .listen:
                NetworkMonitor.shared.startMonitoring(object: holder) { callback(($0, false)) }
            case .get:
                NetworkMonitor.shared.startMonitoring(object: holder) { callback(($0, true)) }
            }
        } onCancel: { holder in
            NetworkMonitor.shared.stopMonitoring(object: holder)
        }
    }
}
