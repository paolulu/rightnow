import Foundation
import Testing
@testable import RightNowCore

@Suite("Timestamp formatter")
struct TimestampFormatterTests {
    @Test("formats a fixed date with DateFormatter tokens")
    func formatsFixedDate() {
        let calendar = Calendar(identifier: .gregorian)
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(
            from: DateComponents(
                timeZone: timeZone,
                year: 2026,
                month: 6,
                day: 21,
                hour: 12,
                minute: 13,
                second: 14
            )
        )!

        let output = TimestampFormatter.string(
            from: date,
            format: "yyyy-MM-dd HH:mm:ss EEE a",
            timeZone: timeZone,
            locale: Locale(identifier: "en_US_POSIX")
        )

        #expect(output == "2026-06-21 12:13:14 Sun PM")
    }

    @Test("falls back to the default format when input is blank")
    func fallsBackForBlankFormat() {
        let date = Date(timeIntervalSince1970: 0)

        let output = TimestampFormatter.string(
            from: date,
            format: "   ",
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "en_US_POSIX")
        )

        #expect(output == "1970-01-01 00:00")
    }

    @Test("exposes the format tokens shown in the settings panel")
    func exposesPanelTokens() {
        #expect(TimestampFormatter.suggestedTokens == [
            "yyyy",
            "MM",
            "dd",
            "HH",
            "mm",
            "ss",
            "EEE",
            "a"
        ])
    }
}
