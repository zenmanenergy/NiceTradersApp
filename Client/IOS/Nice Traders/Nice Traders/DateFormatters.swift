//
//  DateFormatters.swift
//  Nice Traders
//
//  Centralized date/time formatting utilities
//

import Foundation

struct DateFormatters {
    
    /// Format a date/time in compact format: "Nov 27 @ 3:30 PM"
    static func formatCompact(_ dateString: String) -> String {
        // Try ISO8601 first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date: Date?
        
        if let isoDate = isoFormatter.date(from: dateString) {
            date = isoDate
        } else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let isoDate = isoFormatter.date(from: dateString) {
                date = isoDate
            } else {
                // Try other common formats
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd"
                if let fallbackDate = fallbackFormatter.date(from: dateString) {
                    date = fallbackDate
                }
            }
        }
        
        guard let date = date else {
            return dateString
        }
        
        return formatCompact(date)
    }
    
    /// Format a Date object in compact format: "Nov 27 @ 3:30PM"
    static func formatCompact(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d '@' h:mma"
        return formatter.string(from: date)
    }
    
    /// Format a date/time with smart relative formatting
    /// - Returns: "Nov 27 @ 3:30PM"
    static func formatRelative(_ dateString: String) -> String {
        // ALL dates now use compact format: "Nov 27 @ 3:30PM"
        return formatCompact(dateString)
    }
    
    /// Format a Date object with smart relative formatting
    static func formatRelative(_ date: Date) -> String {
        // ALL dates now use compact format: "Nov 27 @ 3:30PM"
        return formatCompact(date)
    }
    
    /// Format with date and time for absolute display
    /// - Returns: "Nov 27 @ 3:30PM"
    static func formatAbsolute(_ dateString: String, includeTime: Bool = true) -> String {
        // ALL dates now use compact format: "Nov 27 @ 3:30PM"
        return formatCompact(dateString)
    }
    
    /// Format Date object with absolute display
    static func formatAbsolute(_ date: Date, includeTime: Bool = true) -> String {
        // ALL dates now use compact format: "Nov 27 @ 3:30PM"
        return formatCompact(date)
    }
    
    /// Format date only (no time)
    /// - Returns: "Nov 27 @ 3:30PM"
    static func formatDateOnly(_ dateString: String) -> String {
        // ALL dates now use compact format: "Nov 27 @ 3:30PM"
        return formatCompact(dateString)
    }
    
    /// Convert Date to ISO8601 string for API
    static func toISO8601(_ date: Date) -> String {
        return ISO8601DateFormatter().string(from: date)
    }
}
