//
//  DateFormatters.swift
//  Nice Traders
//
//  Centralized date/time formatting utilities
//

import Foundation

struct DateFormatters {
    
    /// Format a date/time in compact format: "Nov 27 @ 3:30PM"
    static func formatCompact(_ dateString: String) -> String {
        var date: Date?
        
        // Try ISO8601 with timezone and fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let isoDate = isoFormatter.date(from: dateString) {
            date = isoDate
            print("[DateFormatters] Parsed ISO8601 (with fractional): \(dateString) -> \(isoDate)")
        }
        
        // Try ISO8601 with timezone, no fractional seconds
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let isoDate = isoFormatter.date(from: dateString) {
                date = isoDate
                print("[DateFormatters] Parsed ISO8601 (without fractional): \(dateString) -> \(isoDate)")
            }
        }
        
        // Try common formats without timezone
        if date == nil {
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss",      // 2025-11-28T20:13:25
                "yyyy-MM-dd'T'HH:mm:ss.SSS",  // with milliseconds
                "yyyy-MM-dd HH:mm:ss",         // space instead of T
                "yyyy-MM-dd"                   // date only
            ]
            
            for format in formats {
                fallbackFormatter.dateFormat = format
                if let fallbackDate = fallbackFormatter.date(from: dateString) {
                    date = fallbackDate
                    print("[DateFormatters] Parsed fallback format \(format): \(dateString) -> \(fallbackDate)")
                    break
                }
            }
        }
        
        guard let date = date else {
            print("[DateFormatters] Failed to parse: \(dateString)")
            return dateString
        }
        
        return formatCompact(date)
    }
    
    /// Format a Date object in compact format: "Nov 27 @ 3:30PM"
    static func formatCompact(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d '@' h:mma"
        formatter.timeZone = TimeZone.current  // Use user's local timezone
        
        let result = formatter.string(from: date)
        let tz = TimeZone.current.abbreviation() ?? "Unknown"
        print("[DateFormatters] Formatting date: \(date) in timezone \(tz) -> \(result)")
        
        return result
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
