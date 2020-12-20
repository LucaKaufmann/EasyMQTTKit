//
//  OSLog+logs.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 2.9.2020.
//  Copyright © 2020 mqtthings. All rights reserved.
//
import Foundation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let mqttLogs = OSLog(subsystem: subsystem, category: "EasyMQTT.mqtt")
}
