//
//  CentralManager.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/6/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation
import CoreBluetooth

typealias DiscoveryCompleteClosure = (Result<[CBPeripheral]>) -> ()
typealias ConnectCompleteClosure = (Result<CBPeripheral>) -> ()
typealias DisconnectCompleteClosure = (Result<CBUUID>) -> ()

enum CentralOperation {
    case discover([CBUUID], DiscoveryCompleteClosure)
    case connect(CBPeripheral, ConnectCompleteClosure)
    case disconnect(CBPeripheral, DisconnectCompleteClosure)
}

enum CentralError : Error {
    case powerOnTimeout(CBManagerState)
    case commandTimeout
    case unableToConnect
    case outOfOrderCommandCompletion
}

let centralManagerNotification = Notification.Name("bluetooth.central.notification")

enum CentralNotification {
    case peripherialDisconnect(CBPeripheral)
    case stateChange(CBManagerState)
}

class CentralManagerWrapper : NSObject, CBCentralManagerDelegate {

    static let shared = CentralManagerWrapper()
    
    var powerOnLimitInSeconds = 10.0
    var scanLimitInSeconds = 5.0
    
    //MARK: - Public API
    
    func scanForPeripherals(withServices services: [CBUUID], completion: @escaping DiscoveryCompleteClosure) {
        enqueueOperation(CentralOperation.discover(services, completion))
    }
    
    func connect(toPeripheral peripheral: CBPeripheral, completion: @escaping ConnectCompleteClosure) {
        enqueueOperation(CentralOperation.connect(peripheral, completion))
    }
    
    func disconnect(peripheral: CBPeripheral, completion: @escaping DisconnectCompleteClosure) -> Void {
        enqueueOperation(CentralOperation.disconnect(peripheral, completion))
    }
    
    func flushPendingCommands() {
        commandTimer?.invalidate()
        commandTimer = nil
        commandQueue.flush()
        currentCommand = nil
    }
    
    //MARK: - Private properties
    
    private lazy var centralManager : CBCentralManager = CBCentralManager(delegate: self , queue: nil)
    
    private var powerOnTimer: Timer? = nil
    private var scanTimer: Timer? = nil
    
    private var commandTimer: Timer? = nil
    private var commandQueue = Queue<CentralOperation>()
    private var currentCommand: CentralOperation?
    
    private var discoveredPeripherals = Set<CBPeripheral>()
    
    //MARK: - Command Queue
    
    private func enqueueOperation(_ operation:CentralOperation) {
        commandQueue.enqueue(operation)
        guard centralManager.state == .poweredOn else {
            startPowerOnTimer()
            return
        }
        startQueueIfStopped()
    }
    
    private func startQueueIfStopped() {
        if currentCommand == nil {
            processNextCommand()
        }
    }
    
    private func processNextCommand() {
        if let nextCommand = commandQueue.dequeue() {
            currentCommand = nextCommand
            
            guard centralManager.state == .poweredOn else {
                processCompletion(withError: CentralError.powerOnTimeout(centralManager.state))
                processNextCommand()
                return
            }
            
            let commandTimeout: Double
            switch nextCommand {
            case .discover(let serviceIdentifiers, _):
                print("\(Date()) - Scan Started")
                discoveredPeripherals.removeAll()
                scanTimer = Timer.scheduledTimer(timeInterval: scanLimitInSeconds, target: self, selector: #selector(CentralManagerWrapper.scanTimerExpired), userInfo: nil, repeats: false)
                centralManager.scanForPeripherals(withServices: serviceIdentifiers, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
            case .connect(let peripheral, _):
                print("\(Date()) - Connect Started")
                commandTimeout = 30.0
                commandTimer = Timer.scheduledTimer(timeInterval: commandTimeout, target: self, selector: #selector(CentralManagerWrapper.commandTimeoutOccurred), userInfo: nil, repeats: false)
                centralManager.connect(peripheral, options: nil)
            case .disconnect(let peripheral, _):
                print("\(Date()) - Disconnect Started")
                commandTimeout = 5.0
                commandTimer = Timer.scheduledTimer(timeInterval: commandTimeout, target: self, selector: #selector(CentralManagerWrapper.commandTimeoutOccurred), userInfo: nil, repeats: false)
                centralManager.cancelPeripheralConnection(peripheral)
            }
        } else {
            currentCommand = nil
        }
    }
    
    private func processCompletion(withError error: Error) {
        if let currentCommand = currentCommand {
            switch currentCommand {
            case .discover(_, let completion):
                completion(Result.failure(error))
            case .connect(_, let completion):
                completion(Result.failure(error))
            case .disconnect(_, let completion):
                completion(Result.failure(error))
            }
        }
        processNextCommand()
    }

    //MARK: - Timeout Handlers
    
    @objc private func commandTimeoutOccurred() {
        commandTimer?.invalidate()
        commandTimer = nil
        processCompletion(withError: CentralError.commandTimeout)
    }
    
    @objc private func scanTimerExpired() {
        scanTimer?.invalidate()
        scanTimer = nil
        centralManager.stopScan()
        print("\(Date()) - Scan Ended")
        if let currentCommand = currentCommand {
            switch currentCommand {
            case .discover(_, let completion):
                completion(Result.success(Array(discoveredPeripherals)))
            case .connect(_, let completion):
                completion(Result.failure(CentralError.outOfOrderCommandCompletion))
            case .disconnect(_, let completion):
                completion(Result.failure(CentralError.outOfOrderCommandCompletion))
            }
        }
        processNextCommand()
    }
    
    //MARK: - Power On Timer
    
    private func startPowerOnTimer() {
        powerOnTimer = Timer.scheduledTimer(timeInterval: powerOnLimitInSeconds, target: self, selector: #selector(CentralManagerWrapper.powerOnWaitExpired), userInfo: nil, repeats: false)
    }

    @objc private func powerOnWaitExpired() {
        powerOnTimer?.invalidate()
        powerOnTimer = nil
        guard centralManager.state != .poweredOn else { return }
        print("\(Date()) - No Power On within limit")
        startQueueIfStopped() // Start Queue anyhow and send errors for powered down state
    }

    // MARK: - CBCentralManager Delegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("\(Date()) - Power On")
            if powerOnTimer != nil {
                powerOnTimer = nil
                startQueueIfStopped()
            }
        case .resetting, .poweredOff, .unknown, .unauthorized, .unsupported:
            print("\(Date()) - Other Central State")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(Date()) - Peripheral Found:  \(peripheral)")
        discoveredPeripherals.insert(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(Date()) - Peripheral Connected:  \(peripheral)")
        if let currentCommand = currentCommand {
            switch currentCommand {
            case .discover(_, let completion):
                completion(Result.failure(CentralError.outOfOrderCommandCompletion))
            case .connect(_, let completion):
                completion(Result.success(peripheral))
            case .disconnect(_, let completion):
                completion(Result.failure(CentralError.outOfOrderCommandCompletion))
            }
        }
        processNextCommand()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(Date()) - Peripheral Failed to Connect:  \(peripheral)")
        if let currentCommand = currentCommand {
            switch currentCommand {
            case .discover(_, let completion):
                completion(Result.failure(CentralError.outOfOrderCommandCompletion))
            case .connect(_, let completion):
                completion(Result.success(peripheral))
            case .disconnect(_, let completion):
                completion(Result.failure(CentralError.outOfOrderCommandCompletion))
            }
        }
        processNextCommand()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(Date()) - Peripheral Disconnected:  \(peripheral) - Error: \(String(describing: error))")
        NotificationCenter.default.post(name: centralManagerNotification, object: nil, userInfo: ["type": CentralNotification.peripherialDisconnect(peripheral)])
    }
    
}


