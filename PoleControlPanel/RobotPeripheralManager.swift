//
//  PeripheralManager.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/7/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation
import CoreBluetooth

enum PeripheralError : Error {
    case notConnected
    case badCharacteristicIdentifier
    case readTimeout
    case readNoData
    case writeTimeout
}

typealias ReadOperationClosure = (Result<Data>) -> ()
typealias WriteOperationClosure = (Result<Bool>) -> () 


struct ReadOperation {
    let identifier: CBUUID
    let completion: ReadOperationClosure
}

struct WriteOperation {
    let identifier: CBUUID
    let data: Data
    let confirmWrite: Bool
    let completion: WriteOperationClosure
}

let readCommandTimeoutSeconds = 5.0
let writeCommandTimeoutSeconds = 5.0

class RobotPeripheralManager : NSObject {
    
    let serviceIdentifier = RobotDevice.ControlService.identifier
    let serviceCharacteristicIdentifiers = [RobotDevice.ControlService.CharacteristicIdentifiers.robotPosition,
                                            RobotDevice.ControlService.CharacteristicIdentifiers.motorControl,
                                            RobotDevice.ControlService.CharacteristicIdentifiers.latchPosition,
                                            RobotDevice.ControlService.CharacteristicIdentifiers.launcherPosition,
                                            RobotDevice.ControlService.CharacteristicIdentifiers.batteryVoltage]
    
    let characteristicsToNotify = [RobotDevice.ControlService.CharacteristicIdentifiers.robotPosition,
                                   RobotDevice.ControlService.CharacteristicIdentifiers.batteryVoltage]
    
    let peripheral: CBPeripheral
    
    var services = [CBUUID : CBService]()
    var characteristics = [CBUUID : CBCharacteristic]()
    var lastRSSI = (-Double.infinity, Date.distantPast)
    
    var readCommandTimer: Timer? = nil
    var readCommandQueue = Queue<ReadOperation>()
    var readCurrentCommand: ReadOperation?

    var writeCommandTimer: Timer? = nil
    var writeCommandQueue = Queue<WriteOperation>()
    var writeCurrentCommand: WriteOperation?
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension RobotPeripheralManager : CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let discoveredServices = peripheral.services else { return }
        for service in discoveredServices {
            print("\(service)")
            
            services[service.uuid] = service
            peripheral.discoverCharacteristics(serviceCharacteristicIdentifiers, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let discoveredCharacteristics = service.characteristics else { return }
        for characteristic in discoveredCharacteristics {
            print("\(characteristic)")
            
            characteristics[characteristic.uuid] = characteristic
            if characteristicsToNotify.contains(characteristic.uuid) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        writeCommandTimer?.invalidate()
        writeCommandTimer = nil
        if let writeCurrentCommand = writeCurrentCommand {
            if let error = error {
                writeCurrentCommand.completion(Result.failure(error))
            } else {
                writeCurrentCommand.completion(Result.success(true))
            }
        }
        processNextWriteCommand() // Just keep processing
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let readCurrentCommand = readCurrentCommand {
            readCommandTimer?.invalidate()
            readCommandTimer = nil
            if let error = error {
                readCurrentCommand.completion(Result.failure(error))
            } else {
                if let value = characteristic.value {
                    readCurrentCommand.completion(Result.success(value))
                } else {
                    readCurrentCommand.completion(Result.failure(PeripheralError.readNoData))
                }
            }
            processNextReadCommand()
        } else {
            //TODO:  Notify data coming in --> Translate into notification
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let readCurrentCommand = readCurrentCommand {
            readCommandTimer?.invalidate()
            readCommandTimer = nil
            if let error = error {
                readCurrentCommand.completion(Result.failure(error))
            } else {
                readCurrentCommand.completion(Result.success(NSKeyedArchiver.archivedData(withRootObject: RSSI)))
            }
            processNextReadCommand()
        } else {
            //TODO:  Notify data coming in --> Translate into notification
        }

        print("RSSI read:  \(RSSI.doubleValue)")
        lastRSSI = (RSSI.doubleValue, Date())
    }
    
    //MARK: - Read Command Queue
    
    func enqueueReadOperation(_ operation: ReadOperation) {
        readCommandQueue.enqueue(operation)
        if readCurrentCommand == nil {
            processNextReadCommand()
        }
    }
    
    func processNextReadCommand() {
        if let nextCommand = readCommandQueue.dequeue() {
            readCurrentCommand = nextCommand
            
            guard peripheral.state == .connected else {
                nextCommand.completion(Result.failure(PeripheralError.notConnected))
                processNextReadCommand()
                return
            }
            
            guard nextCommand.identifier != RobotDevice.ControlService.rssiIdentifier else {
                readCommandTimer = Timer.scheduledTimer(timeInterval: readCommandTimeoutSeconds, target: self, selector: #selector(RobotPeripheralManager.readTimeoutOccurred), userInfo: nil, repeats: false)
                peripheral.readRSSI()
                return
            }
            
            guard let characteristic = characteristics[nextCommand.identifier] else {
                nextCommand.completion(Result.failure(PeripheralError.badCharacteristicIdentifier))
                processNextReadCommand()
                return
            }
            readCommandTimer = Timer.scheduledTimer(timeInterval: readCommandTimeoutSeconds, target: self, selector: #selector(RobotPeripheralManager.readTimeoutOccurred), userInfo: nil, repeats: false)
            peripheral.readValue(for: characteristic)
        } else {
            readCurrentCommand = nil
        }
    }
    
    func readTimeoutOccurred() {
        readCommandTimer?.invalidate()
        readCommandTimer = nil
        if let readCurrentCommand = readCurrentCommand {
            readCurrentCommand.completion(Result.failure(PeripheralError.readTimeout))
        }
        processNextReadCommand()
    }

    //MARK: - Write Command Queue
    
    func enqueueWriteOperation(_ operation: WriteOperation) {
        writeCommandQueue.enqueue(operation)
        if writeCurrentCommand == nil {
            processNextWriteCommand()
        }
    }
    
    func processNextWriteCommand() {
        if let nextCommand = writeCommandQueue.dequeue() {
            writeCurrentCommand = nextCommand
            
            guard peripheral.state == .connected else {
                nextCommand.completion(Result.failure(PeripheralError.notConnected))
                processNextWriteCommand()
                return
            }
            guard let characteristic = characteristics[nextCommand.identifier] else {
                nextCommand.completion(Result.failure(PeripheralError.badCharacteristicIdentifier))
                processNextWriteCommand()
                return
            }
            writeCommandTimer = Timer.scheduledTimer(timeInterval: writeCommandTimeoutSeconds, target: self, selector: #selector(RobotPeripheralManager.writeTimeoutOccurred), userInfo: nil, repeats: false)
            peripheral.writeValue(nextCommand.data, for: characteristic, type: nextCommand.confirmWrite ? .withResponse : .withoutResponse)
            if !nextCommand.confirmWrite {
                processNextWriteCommand()
            }
        } else {
            writeCurrentCommand = nil
        }
    }
    
    func writeTimeoutOccurred() {
        writeCommandTimer?.invalidate()
        writeCommandTimer = nil
        if let writeCurrentCommand = writeCurrentCommand {
            writeCurrentCommand.completion(Result.failure(PeripheralError.writeTimeout))
        }
        processNextWriteCommand()
    }

}

extension RobotPeripheralManager {
    
    func readCharacteristicValue(forIdentifier identifier: CBUUID, completion: @escaping (Result<Data>) -> ()) {
        guard peripheral.state == .connected else { completion(Result.failure(PeripheralError.notConnected)); return }
        guard let _ = characteristics[identifier] else { completion(Result.failure(PeripheralError.badCharacteristicIdentifier)); return }
        enqueueReadOperation(ReadOperation(identifier: identifier, completion: completion))
    }
    
    func writeCharacteristicValue(data: Data, confirmWrite: Bool, forIdentifier identifier: CBUUID, completion: @escaping (Result<Bool>) -> () ) {
        guard peripheral.state == .connected else { completion(Result.failure(PeripheralError.notConnected)); return }
        guard let _ = characteristics[identifier] else { completion(Result.failure(PeripheralError.badCharacteristicIdentifier)); return }
        enqueueWriteOperation(WriteOperation(identifier: identifier, data: data, confirmWrite: confirmWrite, completion: completion))
    }
    
    func readRSSIValue(completion: @escaping (Result<Data>) -> ()) {
        guard peripheral.state == .connected else { completion(Result.failure(PeripheralError.notConnected)); return }
        enqueueReadOperation(ReadOperation(identifier: RobotDevice.ControlService.rssiIdentifier, completion: completion))
    }
}
