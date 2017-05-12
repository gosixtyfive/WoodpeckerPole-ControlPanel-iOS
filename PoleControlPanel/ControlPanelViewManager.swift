//
//  ControlPanelViewManager.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/15/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation


class ControlPanelViewManager {
    
    private let robotControllerModel = RobotControllerModel.shared
    
    private weak var managedView: ControlPanelViewController?

    private var isUpButtonPressed = false
    private var isDownButtonPressed = false
    
    init(managedView view: ControlPanelViewController) {
        self.managedView = view
        NotificationCenter.default.addObserver(self, selector: #selector(ControlPanelViewManager.robotDisconnectedNotificationRecieved), name: robotDisconnectedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ControlPanelViewManager.robotConnectedNotificationRecieved), name: robotConnectedNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func robotDisconnectedNotificationRecieved() {
        self.managedView?.showDisconnectedView(show: true)
    }
    
    @objc func robotConnectedNotificationRecieved() {
        self.managedView?.showDisconnectedView(show: false)
    }
    
    func refresh() {
        
    }
    
    //MARK: - Combined Latch and Launch
    
    func launchBird() {
        startMotorUp()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(250)) {
            self.setLatchPosition(position: 175, userOperationDescription: "Full Speed Flip up Launch")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(400)) {
                self.stopMotor()
            }
        }
    }
    
    func retrieveBirdPosition() {
        setLatchPosition(position: 75, userOperationDescription: "Position for lifting")
    }

  
    //MARK: - Lifting Mechanism
    
    // Turn on up motor and wait for limit switch to deactivate
    func autoRaiseToTop() {
        setMotorControl(speed: 0x90, autostop: false, direction: .up, userOperationDescription: "Motor Up to Top")
    }
    
    func upButtonChangedState() {
        isUpButtonPressed = !isUpButtonPressed
        if isUpButtonPressed {
            startMotorUp()
        } else {
            stopMotor()
        }
    }
    
    func downButtonChangedState() {
        isDownButtonPressed = !isDownButtonPressed
        if isDownButtonPressed {
            startMotorDown()
        } else {
            stopMotor()
        }
    }
    
    func startMotorUp() {
        setMotorControl(speed: 0x90, autostop: true, direction: .up, userOperationDescription: "Motor Up")
    }
    
    func startMotorDown() {
        setMotorControl(speed: 0x80, autostop: true, direction: .down, userOperationDescription: "Motor Down")
    }
    
    func stopMotor() {
        setMotorControl(speed: 0, autostop: false, direction: .stopped, userOperationDescription: "Stopping Motor")
    }
    
    // Turn on down motor and wait for limit switch to deactivate
    func autoLowerToBottom() {
        setMotorControl(speed: 0x80, autostop: false, direction: .down, userOperationDescription: "Motor Down to Bottom")
    }
    
    //MARK: - Emergency stop
    
    func emergencyStopAll() {
        stopMotor()
    }
    
    //MARK: - Robot control operations
    
    private func setMotorControl(speed: UInt16, autostop: Bool, direction: MotorControl.MotorDirection, userOperationDescription: String) {
        do {
            let motorControlSetting = try MotorControl(speed: speed, autostop: autostop, direction: direction, writeKey: RobotDevice.Security.writeKey)
            robotControllerModel.setMotorControlSetting(data: motorControlSetting.writeData, confirmWrite: true, completion: { result in
                switch result {
                case .success(_):
                    print("Success")
                case .failure(let error):
                    print("Error Motor Control")
                    self.managedView?.showError(message: error.localizedDescription)
                }
            })
        } catch (let error) {
            print("Error Init Motor Control")
            self.managedView?.showError(message: error.localizedDescription)
        }
    }

    
    private func setLatchPosition(position: UInt8, userOperationDescription: String) {
        do {
            let servoPosition = try ServoPosition(position: position, writeKey: RobotDevice.Security.writeKey)
            robotControllerModel.setLatchPosition(data: servoPosition.writeData, confirmWrite: true, completion: { result in
                switch result {
                case .success(_):
                    print("Success")
                case .failure(let error):
                    print("Error Latch Position")
                    self.managedView?.showError(message: error.localizedDescription)
                }
            })
        } catch (let error) {
            print("Error Init Latch Position")
            self.managedView?.showError(message: error.localizedDescription)
        }
    }

    private func setLauncherPosition(position: UInt8, userOperationDescription: String) {
        do {
            let servoPosition = try ServoPosition(position: position, writeKey: RobotDevice.Security.writeKey)
            robotControllerModel.setLauncherPosition(data: servoPosition.writeData, confirmWrite: true, completion: { result in
                switch result {
                case .success(_):
                    print("Success")
                case .failure(let error):
                    print("Error Launcher Position")
                    self.managedView?.showError(message: error.localizedDescription)
                }
            })
        } catch (let error) {
            print("Error Init Launcher Position")
            self.managedView?.showError(message: error.localizedDescription)
        }
    }
    
}
