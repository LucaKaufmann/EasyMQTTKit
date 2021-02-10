//
//  DiagramPath.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-03-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

public class DiagramPath: Hashable, Identifiable {
    public let path: String
    public var lastSegment: String {
		if let idx = path.lastIndex(of: ".") {
			let start = path.index(after: idx)
			return String(path[start...])
		}
		return path
	}
	
    public var parentPath: String {
		return path.pathUp(".")
	}
	
    public var hasSubpath: Bool {
		return path.contains(".")
	}
	
    public init(_ path: String) {
		self.path = path
	}
	
    public static func == (lhs: DiagramPath, rhs: DiagramPath) -> Bool {
		return lhs.path == rhs.path
	}
	
    public func hash(into hasher: inout Hasher) {
		hasher.combine(path)
	}
}
