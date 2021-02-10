//
//  TimeSeriesValue.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-03-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

public class TimeSeriesValue: Hashable, Identifiable {
    public let value: AnyHashable
    public let valueString: String
	
    public let date: Date
    public let dateString: String
	
    public init(value: AnyHashable, at date: Date, dateFormatted: String) {
		self.value = value
		self.valueString = TimeSeriesValueUtil.createStringValue(value: value)
		self.date = date
		self.dateString = dateFormatted
	}
	
    public static func == (lhs: TimeSeriesValue, rhs: TimeSeriesValue) -> Bool {
		return lhs.value == rhs.value
	}
	
    public func hash(into hasher: inout Hasher) {
		hasher.combine(valueString)
	}
}
