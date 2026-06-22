import Foundation

public enum TimestampFormatter {
    public static let defaultFormat = "yyyy-MMdd-HHmm"

    public static let suggestedTokens = [
        "yyyy",
        "-",
        "MM",
        "dd",
        " ",
        "HH",
        ":",
        "mm",
        "ss",
        "EEE",
        "a"
    ]

    public static func string(
        from date: Date = Date(),
        format: String,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = normalized(format)
        return formatter.string(from: date)
    }

    public static func normalized(_ format: String) -> String {
        let trimmed = format.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultFormat : format
    }
}
