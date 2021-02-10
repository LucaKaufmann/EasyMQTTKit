//
//  StringUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-05.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import CoreGraphics

extension String {
	/*
	 Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
	 - Parameter length: Desired maximum lengths of a string
	 - Parameter trailing: A 'String' that will be appended after the truncation.

	 - Returns: 'String' object.
	*/
	func truncate(length: Int, trailing: String = "…") -> String {
		return (self.count > length) ? self.prefix(length) + trailing : self
	}
	
	func pathUp(_ separator: String = "/") -> String {
		if let range = self.range(of: separator, options: .backwards ) {
			if range.lowerBound.utf16Offset(in: self) == 0 {
				return self
			}
			
			let index = self.index(range.lowerBound, offsetBy: -1)
			
			return String(self[...index])
		}
		return ""
	}
	
	var isBlank: Bool {
		return allSatisfy({ $0.isWhitespace })
	}
	
	// http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
	static func random(length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map { _ in letters.randomElement()! })
	}
}

extension String {
    
    func sanitized() -> String {
        // see for ressoning on charachrer sets https://superuser.com/a/358861
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        
        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
    }
    
    mutating func sanitize() -> Void {
        self = self.sanitized()
    }
    
    func whitespaceCondenced() -> String {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    mutating func condenceWhitespace() -> Void {
        self = self.whitespaceCondenced()
    }
}
