//
//  MqttBroker.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 12.10.2020.
//  Copyright © 2020 mqtthings. All rights reserved.
//

import Foundation

public struct MqttBroker: Codable, Hashable {
    public var name: String
    public var ip: String
    public var port: String
    public var username: String
    public var password: String
    public var enableTls: Bool
    
    public init(name: String, ip: String, port: String, username: String, password: String, enableTls: Bool = false) {
        self.name = name
        self.ip = ip
        self.port = port
        self.username = username
        self.password = password
        self.enableTls = enableTls
    }
}
