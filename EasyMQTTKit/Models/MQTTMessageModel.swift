//
//  MQTTMessageModel.swift
//  MQTTKit
//
//  Created by Luca Kaufmann on 22.12.2020.
//  Copyright © 2020 mqtthings. All rights reserved.
//

import SwiftUI
import SwiftyJSON

public class MQTTMessageModel: ObservableObject {
    
    var timeSeries = Multimap<DiagramPath, TimeSeriesValue>()
    var timeSeriesModels = [DiagramPath: MTimeSeriesModel]()
    @Published public var message: MQTTMessage
    
    public init(message: MQTTMessage) {
        self.message = message
        
        if let json = message.jsonData {
            collectValues(date: message.timestamp, json: json, path: [], dateFormatted: message.localDate)
        }
    }
    
    func collectValues(date: Date, json: JSON, path: [String], dateFormatted: String) {
        json.dictionaryValue
        .forEach {
            let child = $0.value
            var nextPath = path
            nextPath += [$0.key.lowercased()]
            
            collectValues(date: date, json: child, path: nextPath, dateFormatted: dateFormatted)
        }
        
        let path = DiagramPath(path.joined(separator: "."))
        if let value = json.rawValue as? AnyHashable {
            self.timeSeries.put(key: path, value: TimeSeriesValue(value: value, at: date, dateFormatted: dateFormatted))
            
            let val = MTimeSeriesValue(value: value, timestamp: date)
            if let existingValues = self.timeSeriesModels[path] {
                existingValues.values += [val]
                self.timeSeriesModels[path] = existingValues
            } else {
                let model = MTimeSeriesModel()
                model.values += [val]
                self.timeSeriesModels[path] = model
            }
        }
    }
    
    public func getDiagrams() -> [DiagramPath] {
        return Array(timeSeries.dict.keys).sorted { $0.path < $1.path }
    }
    
    public func hasDiagrams() -> Bool {
        return !timeSeries.dict.isEmpty
    }
    
    public func getTimeSeriesLastValue(_ path: DiagramPath) -> TimeSeriesValue? {
        let values = timeSeries.dict[path] ?? [TimeSeriesValue]()
        return values.last
    }
    
    public func getTimeSeries(_ path: DiagramPath) -> [TimeSeriesValue] {
        return timeSeries.dict[path] ?? [TimeSeriesValue]()
    }
    
    public func getTimeSeriesId(_ path: DiagramPath) -> [TimeSeriesValue] {
        return getTimeSeries(path)
    }
}

extension MQTTMessageModel {
    public func extractPayload(for path: String?) -> String {
        var propertyPath = path ?? ""
        propertyPath = propertyPath.replacingOccurrences(of: "payload", with: "")
        propertyPath = propertyPath.deletingPrefix(".")
        propertyPath = propertyPath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var result = "None"
        if propertyPath == "" {
            result = self.message.payload
        } else if let valueObject = self.getTimeSeriesLastValue(DiagramPath(propertyPath.lowercased())) {
            result = valueObject.valueString
        }
        
        return result
    }
}


