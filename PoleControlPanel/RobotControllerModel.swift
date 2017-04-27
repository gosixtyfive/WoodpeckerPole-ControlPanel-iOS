//
//  RobotControllerModel.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/12/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation
import CoreBluetooth

let robotDisconnectedNotification = Notification.Name("robot.bluetooth.disconnected")
let robotConnectedNotification = Notification.Name("robot.bluetooth.connected")

enum RobotControllerError : Error {
    case nonConnected
}

typealias FindDevicesClosure = (Result<[CBPeripheral]>) -> ()
typealias ConnectDeviceClosure = (Result<CBPeripheral>) -> ()
typealias DisconnectDeviceClosure = (Result<UUID>) -> ()

class RobotControllerModel {
    
    let robotServiceIdentifer = RobotDevice.ControlService.identifier
    
    static let shared = RobotControllerModel()
    
    let centralManager = CentralManagerWrapper.shared
    var connectedPeripheral: CBPeripheral? = nil
    var connectedPeripheralManager: RobotPeripheralManager? = nil

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(RobotControllerModel.centralManagerNotificationReceived), name: centralManagerNotification, object: nil)
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func centralManagerNotificationReceived(notification: Notification) {
        if let userInfo = notification.userInfo,
            let centralNotification = userInfo["type"] as? CentralNotification {
            switch centralNotification {
            case .peripherialDisconnect(let peripheral):
                if peripheral == self.connectedPeripheral {
                    self.connectedPeripheral = nil
                    NotificationCenter.default.post(name: robotDisconnectedNotification, object: nil)
                }
            case .stateChange(_):
                break
            }
        }
    }
    
    //MARK: - Selection/Connection
    
    func scanForRobots(completion: @escaping FindDevicesClosure) {
        centralManager.scanForPeripherals(withServices: [robotServiceIdentifer]) { result in
            completion(result)
        }
    }
    
    func connect(toPeripheral peripheral: CBPeripheral, completion: @escaping ConnectDeviceClosure) {
        centralManager.connect(toPeripheral: peripheral) { result in
            switch result {
            case .success(let peripheral):
                self.connectedPeripheral = peripheral
                self.connectedPeripheralManager = RobotPeripheralManager(peripheral: peripheral)
                NotificationCenter.default.post(name: robotConnectedNotification, object: nil)
            case .failure:
                break
            }
            completion(result)
        }
    }

    func disconnect(fromPeripheral peripheral: CBPeripheral, completion: @escaping DisconnectDeviceClosure) {
        centralManager.disconnect(peripheral: peripheral) { result in
            switch result {
            case .success(_):
                self.connectedPeripheral = nil
                completion(Result.success(peripheral.identifier))
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }
    
    //MARK: - Get (read) commands
    
    func getBatteryVoltage(completion: @escaping ((Result<Battery>) -> ())) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return  }
        connectedPeripheralManager.readCharacteristicValue(forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.batteryVoltage, completion: { result in
            completion(result.flatMap({ (rawData:Data) -> Result<Battery> in
                return Result { try Battery(rawData: rawData) }
            })
        )}
    )}
    
    func getRobotPosition(completion: @escaping ((Result<RobotPosition>) -> ())) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.readCharacteristicValue(forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.robotPosition, completion: { result in
            completion(result.flatMap({ (rawData:Data) -> Result<RobotPosition> in
                return Result { try RobotPosition(rawData: rawData) }
            })
        )}
    )}
    
    func getLatchPosition(completion: @escaping ((Result<ServoPosition>) -> ())) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.readCharacteristicValue(forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.latchPosition, completion: { result in
            completion(result.flatMap({ (rawData:Data) -> Result<ServoPosition> in
                return Result { try ServoPosition(rawData: rawData) }
            })
        )}
    )}

    func getLauncherPosition(completion: @escaping ((Result<ServoPosition>) -> ())) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.readCharacteristicValue(forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.launcherPosition, completion: { result in
            completion(result.flatMap({ (rawData:Data) -> Result<ServoPosition> in
                return Result { try ServoPosition(rawData: rawData) }
            })
        )}
    )}
    
    
    func getMotorControlSetting(completion: @escaping ((Result<MotorControl>) -> ())) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.readCharacteristicValue(forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.motorControl, completion: { result in
            completion(result.flatMap({ (rawData:Data) -> Result<MotorControl> in
                return Result { try MotorControl(rawData: rawData) }
            })
        )}
    )}


    //MARK: - Set (Write) commands
    
    func setMotorControlSetting(data: Data, confirmWrite: Bool, completion: @escaping WriteOperationClosure) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.writeCharacteristicValue(data: data, confirmWrite: confirmWrite, forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.motorControl, completion: { result in
            completion(result)
        })
    }
    
    func setLatchPosition(data: Data, confirmWrite: Bool, completion: @escaping WriteOperationClosure) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.writeCharacteristicValue(data: data, confirmWrite: confirmWrite, forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.latchPosition, completion: { result in
            completion(result)
        })
    }

    
    func setLauncherPosition(data: Data, confirmWrite: Bool, completion: @escaping WriteOperationClosure) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.writeCharacteristicValue(data: data, confirmWrite: confirmWrite, forIdentifier: RobotDevice.ControlService.CharacteristicIdentifiers.launcherPosition, completion: { result in
            completion(result)
        })
    }
    
    func readRSSIValue(completion: @escaping (Result<Data>) -> ()) {
        guard let connectedPeripheralManager = connectedPeripheralManager else { completion(Result.failure(RobotControllerError.nonConnected)); return }
        connectedPeripheralManager.readRSSIValue(completion: { result in
            completion(result)
        })
    }
}
