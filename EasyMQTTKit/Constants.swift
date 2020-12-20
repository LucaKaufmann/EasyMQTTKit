//
//  Constants.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 28/10/2019.
//  Copyright © 2019 mqtthings. All rights reserved.
//

import Foundation

struct Constants {
    static let mqttIp = "easymqtt.broker.ip"
    static let mqttPort = "easymqtt.broker.port"
    static let mqttUser = "easymqtt.broker.username"
    static let mqttPassword = "easymqtt.broker.password"
    static let enableTls = "easymqtt.broker.enabletls"
    static let subscriptionFavorites = "easymqtt.user.favorites"
    static let publishFavorites = "easymqtt.user.favorites"
    static let brokerFavorites = "easymqtt.user.brokers.favorites"
    static let purchasedPlusKey = "easymqtt.iap.plus"
    static let migrationNeededKey = "easymqtt.migrationNeeded"
    static let migrationVersion = "easymqtt.migrationVersion"
    static let currentVersion = 1
    static let openedAppCount = "easymqtt.user.openedApp"
}
