//
//  MQTTMessageModel.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 29/10/2019.
//  Copyright © 2019 mqtthings. All rights reserved.
//

import Foundation


public enum MQTTQOS: UInt8, CustomStringConvertible {
    case qos0 = 0
    case qos1
    case qos2
    
    public var description: String {
        switch self {
            case .qos0: return "qos0"
            case .qos1: return "qos1"
            case .qos2: return "qos2"
        }
    }
}

public struct MQTTMessageModel: Identifiable {
    public var id = UUID()
    public var qos: MQTTQOS = .qos0
    public var dup: Bool = false
    public var topic: String
    public var payload: String
    public var retained: Bool = false
    public var timestamp: Date
    
    // utf8 bytes array to string
    public var string: String? {
        get {
            return NSString(bytes: payload, length: payload.count, encoding: String.Encoding.utf8.rawValue) as String?
        }
    }
    
    public init(topic: String, string: String, qos: MQTTQOS = .qos0, retained: Bool = false, dup: Bool = false) {
        self.topic = topic
        self.payload = string
        self.qos = qos
        self.retained = retained
        self.dup = dup
        self.timestamp = Date()
    }
    
    public init(message: PublishMqttMessageModel) {
        self.topic = message.topic
        self.payload = message.payload
        self.retained = message.retain
        self.dup = false
        self.timestamp = Date()
        
        switch message.qos {
        case "qos0":
            self.qos = .qos0
        case "qos1":
            self.qos = .qos1
        case "qos2":
            self.qos = .qos2
        default:
            self.qos = .qos0
        }
    }

//    public init(topic: String, payload: [UInt8], qos: CocoaMQTTQOS = .qos1, retained: Bool = false, dup: Bool = false) {
//        self.topic = topic
//        self.payload = payload
//        self.qos = qos
//        self.retained = retained
//        self.dup = dup
//    }
    
}
