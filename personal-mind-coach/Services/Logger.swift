//
//  Logger.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.personalmindcoach"
    
    static let api = Logger(subsystem: subsystem, category: "API")
    static let database = Logger(subsystem: subsystem, category: "Database")
    static let background = Logger(subsystem: subsystem, category: "Background")
    static let branch = Logger(subsystem: subsystem, category: "Branch")
    static let general = Logger(subsystem: subsystem, category: "General")
    
    #if DEBUG
    static func debug(_ message: String, category: Logger = general) {
        category.debug("\(message)")
    }
    
    static func info(_ message: String, category: Logger = general) {
        category.info("\(message)")
    }
    
    static func error(_ message: String, category: Logger = general) {
        category.error("\(message)")
    }
    #else
    static func debug(_ message: String, category: Logger = general) {}
    static func info(_ message: String, category: Logger = general) {
        category.info("\(message)")
    }
    static func error(_ message: String, category: Logger = general) {
        category.error("\(message)")
    }
    #endif
}
