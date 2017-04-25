//
//  BluetoothDataObjects.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/14/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation

enum BluetoothDataError : Error {
    case badBytecount(Int,Int)
    case invalidRobotPosition
    case positionOutOfRange
    case speedOutOfRange
    case invalidDirection
}

struct Battery {
    static let vRef = 3.3
    static let vDivider = 0.5
    static let adcBitsResolution = 10.0
    
    let volts: Double
    
    init(rawData data: Data) throws {
        guard data.count == 2 else { throw BluetoothDataError.badBytecount(2, data.count) }
        let dataBytes = [UInt8](data)
        let rawValue = UInt16(dataBytes[0]) | UInt16(dataBytes[1]) << 8
        self.volts = Battery.vRef * Double(rawValue) / (pow(2, Battery.adcBitsResolution) - 1) * (1.0 / Battery.vDivider)
    }
}

enum RobotPosition {
    case stoppedUnknown
    case top
    case bottom
    case goingUp(speed: Int8, duration: UInt8)
    case goingDown(speed: Int8, duration: UInt8)
    
    init(rawData data: Data) throws {
        guard data.count == 3 else { throw BluetoothDataError.badBytecount(3, data.count) }
        let dataBytes = [UInt8](data)
        
        let typeCode = dataBytes[0]
        switch typeCode {
        case 0:
            self = RobotPosition.stoppedUnknown
        case 1:
            self = RobotPosition.top
        case 2:
            self = RobotPosition.bottom
        case 3:
            self = RobotPosition.goingUp(speed: Int8(bitPattern: dataBytes[1]), duration: dataBytes[2])
        case 4:
            self = RobotPosition.goingDown(speed: Int8(bitPattern: dataBytes[1]), duration: dataBytes[2])
        default:
            throw BluetoothDataError.invalidRobotPosition
        }
    }
}

struct ServoPosition {
    let position: UInt8
    let writeKey: UInt16
    
    init(position: UInt8, writeKey key: UInt16) throws {
        guard position & 0xFE <= 180 else { throw BluetoothDataError.positionOutOfRange }
        self.position = position
        self.writeKey = key
    }
    
    init(rawData data: Data) throws {
        guard data.count == 3 else { throw BluetoothDataError.badBytecount(3, data.count) }
        writeKey = 0x0000
        position = data[2]
    }
    
    var writeData: Data {
        var dataBytes = [UInt8]()
        let lowWriteByte = UInt8(truncatingBitPattern: writeKey)
        dataBytes.append(lowWriteByte)
        let highWriteByte = UInt8(truncatingBitPattern: writeKey >> 8)
        dataBytes.append(highWriteByte)
        dataBytes.append(position)
        return Data(bytes: dataBytes)
    }
}

struct MotorControl {
    
    enum MotorDirection : Int16 {
        case up = 1
        case down = -1
        case stopped = 0
    }
    
    let speed: UInt16
    let direction: MotorDirection
    let writeKey: UInt16
    
    init(speed: UInt16, direction: MotorDirection, writeKey key: UInt16) throws {
        guard speed <= 0x00FF else { throw BluetoothDataError.speedOutOfRange }
        if direction == .stopped && speed > 0 { throw BluetoothDataError.invalidDirection }
        if direction != .stopped && speed == 0 { throw BluetoothDataError.invalidDirection }
        self.speed = speed
        self.direction = direction
        self.writeKey = key
    }
    
    init(rawData data: Data) throws {
        guard data.count == 4 else { throw BluetoothDataError.badBytecount(4, data.count) }
        self.writeKey = 0x0000
        var dataBytes = [UInt8](data)
        
        let signedSpeed = Int16(bitPattern: (UInt16(dataBytes[3]) << 8) | UInt16(dataBytes[2]))
        if signedSpeed == 0 {
            speed = 0
            direction = .stopped
        } else {
            speed = UInt16(bitPattern: abs(signedSpeed))
            if signedSpeed > 0 {
                direction = .up
            } else {
                direction = .down
            }
        }
    }
    
    var writeData: Data {
        var dataBytes = [UInt8]()
        let lowWriteByte = UInt8(truncatingBitPattern: writeKey)
        let highWriteByte = UInt8(truncatingBitPattern: writeKey >> 8)
        dataBytes.append(lowWriteByte)
        dataBytes.append(highWriteByte)
        let speed = Int16(self.speed) * direction.rawValue
        let lowSpeedByte = UInt8(truncatingBitPattern: speed)
        let highSpeedByte = UInt8(truncatingBitPattern: speed >> 8)
        dataBytes.append(lowSpeedByte)
        dataBytes.append(highSpeedByte)
        
        return Data(bytes: dataBytes)
    }
}
