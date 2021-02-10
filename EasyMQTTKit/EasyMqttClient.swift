//
//  MQTTClient.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 22/10/2019.
//  Copyright © 2019 mqtthings. All rights reserved.
//

import Foundation
import CocoaMQTT
import os.log
import Combine

public let sharedMqttClient = EasyMqttClient()

public enum PublishState {
    case ready
    case publishing
    case error
    case published
}

public enum ConnectState {
    case connected
    case connecting
    case error
    case disconnected
}

public class EasyMqttClient: ObservableObject {
    var mqtt: CocoaMQTT?
    @Published public var messageBufferSize = 10
    @Published public private(set) var subscribedTopics = [String]()
    @Published public var messageBuffer = [MQTTMessage]()
    @Published public var isSubscribed = false
    @Published public var isConnected = false
    @Published public var connectState: ConnectState = .disconnected
    @Published public var publishState: PublishState = .ready
    public var connectedBroker: MqttBroker?
    
    var errorTask: DispatchWorkItem?
    
    public let connectedPublisher = PassthroughSubject<(Bool), Never>()
    
    let SUBSCRIBED_TOPICS = "EasyMqtt.subscribedTopics"
    let MESSAGEBUFFER_SIZE = "EasyMqtt.messageBufferSize"
    
    let clientID = "EasyMQTT-\(UIDevice.current.name)"
    
    public func createMqttClient(brokerAddress: String, brokerPort: String, enableTls: Bool) {
        print("Creating new mqtt client with saved credentials")
        subscribedTopics = readSubscribedTopics()
        messageBufferSize = readMessageBufferSize()
        mqtt = CocoaMQTT(clientID: clientID, host: brokerAddress, port: UInt16(brokerPort) ?? 1883)
        mqtt?.delegate = self
        mqtt?.enableSSL = enableTls
        mqtt?.allowUntrustCACertificate = true
    }
    
    fileprivate func setBroker(ip: String, username: String, port: String, enableTls: Bool) {
        if Storage.fileExists(Constants.brokerFavorites, in: .shared) {
            
            do {
                let brokerFavorites = try Storage.retrieve(Constants.brokerFavorites, from: .shared, as: [MqttBroker].self)
                if let foundBroker = brokerFavorites.first(where: { $0.ip.lowercased() == ip.lowercased() && $0.username.lowercased() == username.lowercased()  }) {
                    self.connectedBroker = foundBroker
                    return
                }
                print("Loading existing broker favorites")
            } catch {
                print("No favorites found")
            }
        }
        
        let tempBroker = MqttBroker(name: "", ip: ip, port: port, username: username, password: "", enableTls: enableTls)
        self.connectedBroker = tempBroker
        
    }
    
    public func connect(username: String, password: String, ipAddress: String, port: String, enableTls: Bool = false) {
        if mqtt == nil {
            createMqttClient(brokerAddress: ipAddress, brokerPort: port, enableTls: enableTls)
        } else if mqtt!.connState == .connected {
            return
        }

        self.messageBuffer = [MQTTMessage]()
//        if (username != "") {
//            mqtt?.username = username
//            mqtt?.password = password
//
//            let keychain = KeychainSwift(appGroup: "group.com.mqtthings.EasyMQTT")
//            keychain.set(username, forKey: Constants.mqttUser)
//            keychain.set(password, forKey: Constants.mqttPassword)
//        }
        
        mqtt?.username = username
        mqtt?.password = password
        
        mqtt?.connect(timeout: 5)
        setBroker(ip: ipAddress, username: username, port: port, enableTls: enableTls)
    }
    
    public func backgroundConnect(username: String, password: String, ipAddress: String, port: String, enableTls: Bool = false, clientId: String = "EasyMQTT-\(UIDevice.current.name)-shortcut") -> CocoaMQTT {
        
        print("Creating new mqtt client with saved credentials")
        let mqtt = CocoaMQTT(clientID: clientId, host: ipAddress, port: UInt16(port) ?? 1883)
        mqtt.delegate = self
        mqtt.enableSSL = enableTls
        mqtt.allowUntrustCACertificate = true
        
        mqtt.username = username
        mqtt.password = password
        
        mqtt.connect(timeout: 5)
        
        return mqtt
    }
    
    public func disconnect() {
        mqtt?.disconnect()
        self.subscribedTopics = []
        self.messageBuffer = []
        self.writeSubscribedTopics(self.subscribedTopics)
        self.changeMessageBufferSize(to: 10)
        self.mqtt = nil
        self.connectedBroker = nil
        self.connectState = .disconnected
    }
    
    public func backgroundDisconnect() {
        mqtt?.disconnect()
        self.subscribedTopics = []
        self.mqtt = nil
    }
    
    public func publish(messageObject: PublishMqttMessageModel) {
        guard let client = mqtt else {
            print("Error initializing client")
            return
        }

        let message = CocoaMQTTMessage(message: messageObject)
        print("Sending message \(message)")
        self.publishState = .publishing
        errorTask = DispatchWorkItem {
            self.publishState = .error
            self.setDelayedPublishState()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: errorTask!)
        client.publish(message)
    }
    
    public func publishFromBackground(topic: String, payload: String, username: String, password: String, ipAddress: String, port: String, enableTls: Bool, completion: @escaping (Bool) -> Void) {
        
//        guard let client = mqtt else {
//            print("Error initializing client")
//            completion(false)
//            return
//        }
        
        let client = self.backgroundConnect(username: username, password: password, ipAddress: ipAddress, port: port, enableTls: enableTls)
        
        var delayWorkItem: DispatchWorkItem?
        let message = CocoaMQTTMessage(topic: topic, string: payload, qos: .qos1, retained: false, dup: false)
        if client.connState == .connected {
            print("Sending message \(message)")
            client.publish(message)
            completion(true)
            delayWorkItem?.cancel()
            return
        }
        
        client.didChangeState = { mqtt, state in
            if state == .connected {
                print("Sending message \(message)")
                client.publish(message)
                delayWorkItem?.cancel()
                completion(true)
                return
            }
        }
        
        delayWorkItem = DispatchWorkItem {
            if client.connState != .connected {
                client.disconnect()
                completion(false)
            }
        }
        //we just created the work item, it is safe to force unwrap in this situation
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: delayWorkItem!)
    }
    
    public func subscribeFromBackground(topic: String, username: String, password: String, ipAddress: String, port: String, enableTls: Bool, widget: Bool = false, completion: @escaping (MQTTMessage?) -> Void) {

        
        let client = self.backgroundConnect(username: username, password: password, ipAddress: ipAddress, port: port, enableTls: enableTls, clientId: (widget ? "\(clientID)-\(topic.sanitized())" : "\(clientID)-shortcut"))
        
        var messageReceived = false
        
        var delayWorkItem: DispatchWorkItem?
        client.didReceiveMessage = { mqttClient, message, qos in
            if !messageReceived {
                print("Receive message")
                messageReceived = true
                client.disconnect()
                delayWorkItem?.cancel()
                
                completion(self.createMessage(message))
            }
            return
        }
        
        if client.connState == .connected {
            print("Subscribing to topic")
            client.subscribe(topic)
        }
        client.didChangeState = { mqtt, state in
            if state == .connected {
                print("Subscribing to topic")
                client.subscribe(topic)
            }
        }
        
//        delayWorkItem = DispatchWorkItem {
//            client.disconnect()
//            completion(nil)
//        }
//        //we just created the work item, it is safe to force unwrap in this situation
//        var timeout = DispatchTime.now() + 5
//        if widget {
//            timeout = timeout + 5
//        }
//        DispatchQueue.main.asyncAfter(deadline: timeout, execute: delayWorkItem!)
    }
    
    public func subscribe(topic: String) {
        guard let client = mqtt else {
            os_log("Error initializing client", log: OSLog.mqttLogs, type: .error)
            return
        }
        
        
//        if (isSubscribed && topic != self.subscribedTopic) {
//            client.unsubscribe(subscribedTopic, requestCompletion: { result, messageId in
//                print("Successfully unsubscribed!")
//                self.clientSubscribe(to: topic)
//            })
//        } else {
        
        if !self.subscribedTopics.contains(topic) {
            clientSubscribe(to: topic)
            self.subscribedTopics.append(topic)
            writeSubscribedTopics(subscribedTopics)
        } else {
            os_log("Already subscribed to that topic", log: OSLog.mqttLogs, type: .info)
        }

//        }
        
    }
    
    private func clientSubscribe(to topic: String) {
        guard let client = mqtt else {
            print("Error initializing client")
            return
        }
        
        client.subscribe(topic, qos: .qos0)
    }
    
    public func unsubscribeTo(topic: String) {
        guard let client = mqtt else {
            print("Error initializing client")
            return
        }

        TRACE("Unsubscribing to \(topic)")
        
        client.unsubscribe(topic)
        if let index = self.subscribedTopics.lastIndex(of: topic) {
            self.subscribedTopics.remove(at: index)
        }
        writeSubscribedTopics(subscribedTopics)
    }
    
    

}

extension EasyMqttClient {
    fileprivate func setDelayedPublishState(_ state: PublishState = .ready) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.publishState = state
        }
    }
}
//extension EasyMqttClient {
//    func didConnect(returnCode: ReturnCode) {
//        TRACE("Connected: \(returnCode)")
//        DispatchQueue.main.async {
//            self.isConnected = true
//        }
//        self.connectedPublisher.send(true)
//    }
//
//    func didDisconnect(reasonCode: ReasonCode) {
//        TRACE("Disconnected: \(reasonCode)")
//        DispatchQueue.main.async {
//            self.isConnected = false
//        }
//        self.connectedPublisher.send(false)
//    }
//
//    func didReceive(message: MQTTMessage) {
//        guard let msgString = message.payloadString else {
//            return
//        }
//        TRACE("message: \(msgString.description), id: \(message.messageId)")
//        self.appendMessage(message: message)
//        let name = NSNotification.Name(rawValue: "MQTTMessageNotification")
//        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": msgString, "topic": message.topic])
//    }
//
//    func didSubscribe(messageId: Int) {
//        TRACE("Subscribed: \(messageId)")
//        DispatchQueue.main.async {
//            self.isSubscribed = true
//        }
//    }
//
//    func didUnsubscribe(messageId: Int) {
//        TRACE("unsubscribing, message ID \(messageId)")
//    }
//
//    func didPublish(messageId: Int) {
//        TRACE("id: \(messageId)")
//    }
//}

extension EasyMqttClient: CocoaMQTTDelegate {
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        TRACE("unsubscribe \(topic)")
        self.isSubscribed = false
    }

    // Optional ssl CocoaMQTTDelegate
    public func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")

        completionHandler(true)
    }

    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")
    }

    public func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
        switch state {
        case .connected:
            DispatchQueue.main.async {
                self.isConnected = true
                self.connectState = .connected
            }
            
            self.connectedPublisher.send(true)
            for topic in subscribedTopics {
                mqtt.subscribe(topic, qos: .qos0)
            }
        case .connecting:
            DispatchQueue.main.async {
                self.connectState = .connecting
            }
        case .disconnected:
            DispatchQueue.main.async {
                self.isConnected = false
                if self.connectState != .error {
                    self.connectState = .disconnected
                }
            }
            self.connectedPublisher.send(false)
        default:
            return
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(message.string!.description), id: \(id)")
        errorTask?.cancel()
        errorTask = nil
        self.publishState = .published
        setDelayedPublishState()
    }

    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("PublishAck id: \(id)")
    }

    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        guard let msgString = message.string else {
            return
        }
        TRACE("message: \(msgString.description), topic: \(message.topic)")
        self.appendMessage(message: message)
        let name = NSNotification.Name(rawValue: "MQTTMessageNotification")
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": msgString, "topic": message.topic])
    }

    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        TRACE("topics: \(topics)")
        self.isSubscribed = true

    }

    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        if err != nil {
            self.connectState = .error
        } else {
            self.connectState = .disconnected
        }
        isConnected = false
        self.mqtt = nil
        self.connectedBroker = nil
    }
}

extension EasyMqttClient {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

extension EasyMqttClient {
    func appendMessage(message: CocoaMQTTMessage) {
        let newMessage = createMessage(message)

        DispatchQueue.main.async {
            self.messageBuffer.insert(newMessage, at: 0)
            
            if self.messageBuffer.count > self.messageBufferSize {
                self.messageBuffer.removeLast()
            }
        }
    }
}

extension EasyMqttClient {
    
    private func readSubscribedTopics() -> [String] {
        var topics = [String]()
        let userDefaults = UserDefaults.standard
        
        if let array = userDefaults.array(forKey: SUBSCRIBED_TOPICS) as? [String] {
            topics = array
        }
        
        return topics
    }
    
    private func writeSubscribedTopics(_ topics: [String]) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(topics, forKey: SUBSCRIBED_TOPICS)
    }
    
    public func changeMessageBufferSize(to size: Int) {
        self.messageBufferSize = size
        UserDefaults.standard.setValue(size, forKey: MESSAGEBUFFER_SIZE)
    }
    
    private func readMessageBufferSize() -> Int {
        var size = 10
        
        let userDefaults = UserDefaults.standard
        
        if let number = userDefaults.value(forKey: MESSAGEBUFFER_SIZE) as? Int {
            size = number
        }
        
        return size
    }
}

extension CocoaMQTTMessage {
    public convenience init(message: PublishMqttMessageModel) {
        var qos: CocoaMQTTQOS = CocoaMQTTQOS.qos0
        switch message.qos {
        case "qos0":
            qos = CocoaMQTTQOS.qos0
        case "qos1":
            qos = CocoaMQTTQOS.qos1
        case "qos2":
            qos = CocoaMQTTQOS.qos2
        default:
            qos = CocoaMQTTQOS.qos0
        }
        
        self.init(topic: message.topic, string: message.payload, qos: qos, retained: message.retain, dup: false)
    }
}

extension EasyMqttClient {
    fileprivate func createMessage(_ message: CocoaMQTTMessage) -> MQTTMessage {
        var qos: MQTTQOS = MQTTQOS.qos0
        switch message.qos {
        case .qos0:
            qos = MQTTQOS.qos0
        case .qos1:
            qos = MQTTQOS.qos1
        case .qos2:
            qos = MQTTQOS.qos2
        }
        let newMessage = MQTTMessage(topic: message.topic,
                                          string: message.string ?? "",
                                          qos: qos,
                                          retained: message.retained,
                                          dup: message.dup)
        
        return newMessage
    }
}
