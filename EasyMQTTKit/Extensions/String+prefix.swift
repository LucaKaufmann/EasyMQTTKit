//
//  File.swift
//  EasyMQTT
//
//  Created by Luca Kaufmann on 5.1.2021.
//  Copyright © 2021 mqtthings. All rights reserved.
//

import Foundation

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
