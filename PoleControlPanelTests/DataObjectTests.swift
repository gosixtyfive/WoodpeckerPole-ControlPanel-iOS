//
//  DataObjectTests.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/14/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import XCTest
@testable import PoleControlPanel


class DataObjectTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBattery() {
        
        do {
            let _ = try Battery(rawData: Data(bytes: [0x00]))
            XCTFail("Failed - insufficient bytes not detected")
        } catch {
            
        }
        
        do {
            let testBattery = try Battery(rawData: Data(bytes: [0x00,0x00]))
            XCTAssertEqualWithAccuracy(testBattery.volts, 0.0, accuracy: 0.001, "Volts not equal to zero")
        } catch {
            XCTFail("Failed init - Battery")
        }
        
        do {
            let testBattery = try Battery(rawData: Data(bytes: [0x07,0x03]))
            XCTAssertEqualWithAccuracy(testBattery.volts, 5.0, accuracy: 0.005, "Volts not equal to vRef * divider")
        } catch {
            XCTFail("Failed init - Battery")
        }
        
        do {
            let testBattery = try Battery(rawData: Data(bytes: [0xE9,0x00]))
            XCTAssertEqualWithAccuracy(testBattery.volts, 1.5, accuracy: 0.005, "Volts not equal to 1.5 for 0x3333")
        } catch {
            XCTFail("Failed init - Battery")
        }
        
    }
    
    func testRobotPosition() {
        
        do {
            let _ = try RobotPosition(rawData: Data(bytes: [0x00]))
            XCTFail("Failed - insufficient bytes not detected")
        } catch {
            
        }
        do {
            let testRobotPosition = try RobotPosition(rawData: Data(bytes: [0x00, 0xFF, 0xFF]))
            switch testRobotPosition {
            case .stoppedUnknown:
                break
            default:
                XCTFail("case not .stoppedUnknown")
            }
        } catch {
            XCTFail("Failed init - Battery")
        }
        
        do {
            let testRobotPosition = try RobotPosition(rawData: Data(bytes: [0x01, 0xFF, 0xFF]))
            switch testRobotPosition {
            case .top:
                break
            default:
                XCTFail("case not .top")
            }
        } catch {
            XCTFail("Failed init - Battery")
        }
        do {
            let testRobotPosition = try RobotPosition(rawData: Data(bytes: [0x02, 0xFF, 0xFF]))
            switch testRobotPosition {
            case .bottom:
                break
            default:
                XCTFail("case not .bottom")
            }
        } catch {
            XCTFail("Failed init - Battery")
        }
        do {
            let testRobotPosition = try RobotPosition(rawData: Data(bytes: [0x03, 0xFF, 0x45]))
            switch testRobotPosition {
            case .goingUp(let speed, let duration):
                XCTAssertEqual(duration, 0x45)
                XCTAssertEqual(speed, -1)
            default:
                XCTFail("case not .goingUp")
            }
        } catch {
            XCTFail("Failed init - Battery")
        }
        do {
            let testRobotPosition = try RobotPosition(rawData: Data(bytes: [0x04, 0x20, 0x45]))
            switch testRobotPosition {
            case .goingDown(let speed, let duration):
                XCTAssertEqual(duration, 0x45)
                XCTAssertEqual(speed, 0x20)
            default:
                XCTFail("case not .goingDown")
            }
        } catch {
            XCTFail("Failed init - Battery")
        }
    }
    
    
    func testServoControl() {
        
        do {
            let _ = try ServoPosition(rawData: Data(bytes: []))
            XCTFail("Failed - insufficient bytes not detected")
        } catch {
            
        }
        
        do {
            let testServo = try ServoPosition(rawData: Data(bytes: [0x00, 0x00, 0x00]))
            XCTAssertEqual(testServo.position, 0x00)
        } catch {
            XCTFail("Failed init - ServoControl")
        }
        
        do {
            let testServo = try ServoPosition(rawData: Data(bytes: [0x00, 0x00, 0xAA]))
            XCTAssertEqual(testServo.position, 0xAA)
        } catch {
            XCTFail("Failed init - ServoControl")
        }
        
        do {
            let servoPosition = try ServoPosition(position: 0x00, writeKey: 0xF001)
            let servoPositionZeroWriteData = servoPosition.writeData
            let bytes = [UInt8](servoPositionZeroWriteData)
            
            XCTAssertEqual(bytes[0], 0x01, "Low byte key incorrect")
            XCTAssertEqual(bytes[1], 0xF0, "High byte key incorrect")
            XCTAssertEqual(bytes[2], 0x00, "Position Incorrect")
        } catch {
            XCTFail("Failed init - Servo Position")
        }
    }
    
    func testMotorControl() {
        do {
            let _ = try MotorControl(rawData: Data(bytes: []))
            XCTFail("Failed - insufficient bytes not detected")
        } catch {
            
        }
        
        do {
            let testMotor = try MotorControl(rawData: Data(bytes: [0x00, 0x00, 0xFF, 0xFF, 0x01]))
            XCTAssertEqual(testMotor.direction, .down)
            XCTAssertEqual(testMotor.speed, 1)
            XCTAssert(testMotor.autostop == true, "Autostop not set")
        } catch {
            XCTFail("Failed init - Motor")
            
        }
        
        do {
            let testMotor = try MotorControl(rawData: Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00]))
            XCTAssertEqual(testMotor.direction, .stopped)
            XCTAssertEqual(testMotor.speed, 0)
            XCTAssert(testMotor.autostop == false, "Autostop incorrectly set")
        } catch {
            XCTFail("Failed init - Motor")
            
        }
        
        do {
            let testMotor = try MotorControl(rawData: Data(bytes: [0x00, 0x00, 0x2F, 0x00, 0x00]))
            XCTAssertEqual(testMotor.direction, .up)
            XCTAssertEqual(testMotor.speed, 0x2F)
            XCTAssert(testMotor.autostop == false, "Autostop incorrectly set")
        } catch {
            XCTFail("Failed init - Motor")
            
        }
        
        do {
            let testMotor = try MotorControl(speed: 0x00A5, autostop: true, direction: .down, writeKey: 0xF001)
            let motorControlWriteData = testMotor.writeData
            let bytes = [UInt8](motorControlWriteData)
            
            XCTAssertEqual(bytes[0], 0x01, "Low byte key incorrect")
            XCTAssertEqual(bytes[1], 0xF0, "High byte key incorrect")
            XCTAssertEqual(bytes[2], 0x5B, "Motor Speed and Position Incorrect")
            XCTAssertEqual(bytes[3], 0xFF, "Motor Speed and Position Incorrect")
            XCTAssertEqual(bytes[4], 0x01, "Autostop should be selected")
  
        } catch {
            XCTFail("Failed init - Motor")
        }
        
        do {
            let testMotor = try MotorControl(speed: 0x0028, autostop: false, direction: .up, writeKey: 0xF001)
            let motorControlWriteData = testMotor.writeData
            let bytes = [UInt8](motorControlWriteData)
            
            XCTAssertEqual(bytes[0], 0x01, "Low byte key incorrect")
            XCTAssertEqual(bytes[1], 0xF0, "High byte key incorrect")
            XCTAssertEqual(bytes[2], 0x28, "Motor Speed and Position Incorrect")
            XCTAssertEqual(bytes[3], 0x00, "Motor Speed and Position Incorrect")
            XCTAssertEqual(bytes[4], 0x00, "Autostop should not be selected")

        } catch {
            XCTFail("Failed init - Motor")
        }
        
        
        do {
            let testMotor = try MotorControl(speed: 0x00, autostop: false, direction: .stopped, writeKey: 0xF001)
            let motorControlWriteData = testMotor.writeData
            let bytes = [UInt8](motorControlWriteData)
            
            XCTAssertEqual(bytes[0], 0x01, "Low byte key incorrect")
            XCTAssertEqual(bytes[1], 0xF0, "High byte key incorrect")
            XCTAssertEqual(bytes[2], 0x00, "Motor Speed and Position Incorrect")
            XCTAssertEqual(bytes[3], 0x00, "Motor Speed and Position Incorrect")
            XCTAssertEqual(bytes[4], 0x00, "Autostop should not be selected")

        } catch {
            XCTFail("Failed init - Motor")
        }
        
        
    }
    
}
