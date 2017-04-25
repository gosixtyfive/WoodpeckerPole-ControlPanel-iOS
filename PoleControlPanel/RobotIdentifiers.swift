//
//  RobotIdentifiers.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/24/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import Foundation
import CoreBluetooth

enum RobotDevice {
    enum ControlService {
        static let identifier = CBUUID(string: "C700604B-2757-49A0-B02A-6A8C061BBC1E")
        static let rssiIdentifier = CBUUID(string: "F3148B6A-982B-4116-8B99-BDFB457DD3C8")
        enum CharacteristicIdentifiers {
            static let batteryVoltage = CBUUID(string: "33DFD573-ABF9-4707-9E34-29E2011C231E")
            static let motorControl = CBUUID(string: "C82B4753-2D94-47DF-B2FF-09099F2B0E39")
            static let robotPosition = CBUUID(string: "AD123765-A421-4F80-BE1B-62DEEB854141")
            static let latchPosition = CBUUID(string: "675CF627-6CC0-4810-AFDB-B6AA3F7183C5")
            static let launcherPosition = CBUUID(string: "434D078D-7903-44D0-A3B5-7E87884B80ED")
        }
    }
    enum Security {
        static let writeKey : UInt16 = 0xF032
    }
}
