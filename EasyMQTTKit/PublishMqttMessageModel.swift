//
//  PublishMqttMessageModel.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 2.12.2019.
//  Copyright © 2019 mqtthings. All rights reserved.
//

import Foundation

public struct PublishMqttMessageModel: Codable, Hashable {
    public var topic: String
    public var payload: String
    public var qos: String
    public var retain: Bool
    
    public init(topic: String, payload: String, qos: String, retain: Bool) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
    }
}
