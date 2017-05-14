//
//  SystemMonitorViewManager.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/11/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation
import CoreBluetooth


class SystemMonitorViewManager {
    
    private let robotControllerModel = RobotControllerModel.shared
    
    private weak var managedView: SystemMonitorViewController?
    
    private var discoveredPeripherals = [CBPeripheral]()
    
    private var statusUpdateTimer: Timer? = nil
    
    init(managedView view: SystemMonitorViewController) {
        self.managedView = view
        NotificationCenter.default.addObserver(self, selector: #selector(SystemMonitorViewManager.robotDisconnectedNotificationReceived), name: robotDisconnectedNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func robotDisconnectedNotificationReceived() {
        self.managedView?.deviceDisconnected()
        self.statusUpdateTimer?.invalidate()
        self.statusUpdateTimer = nil
    }
    
    func scanForDevices() {
        robotControllerModel.scanForRobots() { result in
            switch result {
            case .success(let peripherals):
                self.discoveredPeripherals = peripherals
                self.managedView?.discoveredPeripherals = self.tableCellData(forDiscoveredPeripherals: peripherals)
            case .failure(let error):
                self.managedView?.discoveredPeripherals = []
                print(error)
            }
        }
    }
    
    func selectDeviceForConnection(atIndex index: Int) {
        robotControllerModel.connect(toPeripheral: discoveredPeripherals[index]) { result in
            switch result {
            case .success(let peripheral):
                self.managedView?.connectSucceeded(deviceName: peripheral.name, deviceIdentifier: peripheral.identifier.uuidString)
                print("Connected")
                self.statusUpdateTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(SystemMonitorViewManager.requestStatusInfo), userInfo: nil, repeats: true)
            case .failure(let error):
                self.managedView?.connectFailed()
                print("Connect peripheral error: \(error) for \(String(describing: self.discoveredPeripherals[index]))")
            }
            self.discoveredPeripherals = []
        }
    }
    
    private func tableCellData(forDiscoveredPeripherals peripherals: [CBPeripheral]) -> [PeripheralCellData] {
        return peripherals.map { (peripheral: CBPeripheral) -> PeripheralCellData in
            let identifier = peripheral.identifier.uuidString
            let name = peripheral.name ?? "<Device Name Not Available>"
            let rssi: String? = nil
            return PeripheralCellData(identifer: identifier, name: name, rssi: rssi)
        }
    }
    
    @objc func requestStatusInfo() {
        robotControllerModel.readRSSIValue { result in
            switch result {
            case .success(let data):
                if let rssi = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSNumber {
                    self.managedView?.updateRssiLabel(value: rssi.stringValue)
                    self.managedView?.showRSSI(true)
                } else {
                    self.managedView?.showRSSI(false)
                }
            case .failure(let error):
                self.managedView?.showRSSI(false)
                print(error)
            }
        }
        robotControllerModel.getBatteryVoltage{ result in
            switch result {
            case .success(let battery):
                let processorVoltage = battery.volts
                let motorVoltage = battery.motorVolts
                self.managedView?.showProcessorVoltage(true)
                self.managedView?.updateBatteryVoltage(processor: String(format: "%3.2f V", processorVoltage), motors: String(format: "%3.2f V", motorVoltage))
            case .failure(let error):
                self.managedView?.showProcessorVoltage(true)
                self.managedView?.updateBatteryVoltage(processor: "ERR", motors: "ERR")
                print(error)
            }
        
        }
    }
}





