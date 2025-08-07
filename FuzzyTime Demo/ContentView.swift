import SwiftUI
import UtilViews

struct ContentView: View {
    @State var editingText: String = ""
    @State var date: Date? = nil
    @State var isValid: Bool = true
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .full
        
        return self.date == nil ? "" : formatter.string(from: self.date!)
    }
    
    var body: some View {
        VStack {
            Text("Fuzzy Time!")
                .font(.headline)
            DebouncedTextField("Enter a time", text: $editingText, wait: .seconds(0.2))
                .onChange(of: editingText) {
                    guard editingText != "" else { isValid = true; return }
                    let result = matchDate(from: editingText)
                    
                    self.isValid = result != nil
                    self.date = result
                }
            ZStack {
                Text("This date is invalid")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .opacity(isValid ? 0 : 1)
                
                Text(formattedDate)
                    .font(.caption)
            }
        }
        .padding()
    }
}

func matchDate(from string: String) -> Date? {
    DateMatcher(string).parseDate()
}

class DateMatcher {
    let string: String
    
    init(_ string: String) {
        self.string = string
    }
    
    func parseDate() -> Date? {
        for grammar in DateGrammar.allCases {
            if let date = grammar.match(string: string){
                return date
            }
        }
        
        return nil
    }
}

enum DateGrammar: String, CaseIterable {
    case hour = "(0?[0-9]|1[0-2])(am|pm)"
    case twentyFourHour = "([0-1]?[0-9]|2[0-3]):([0-5][0-9])"
    case twelveHour = "(0?[0-9]|1[0-2]):([0-5][0-9])(am|pm)"
    
    var regex: Regex<AnyRegexOutput> { try! Regex(rawValue) }
    
    func match(string: String) -> Date? {
        guard let match = string.wholeMatch(of: regex) else { return nil }
        
        let matchedHour = fetchHour(string: string, match: match)
        let matchedMinute = fetchMinute(string: string, match: match)
        let matchedAmpm = fetchAmPm(string: string, match: match)
        
        guard let matchedHour else { return nil }
        
        let hour = matchedHour + (matchedAmpm == "pm" ? 12 : 0)
        let minute = matchedMinute ?? 0
        
        return Calendar.current.date(from: .init(hour: hour, minute: minute))
    }
    
    private func fetchHour(string: String, match: Regex<Regex<AnyRegexOutput>.RegexOutput>.Match) -> Int? {
        Int(string[match[1].range!])
    }
    
    private func fetchMinute(string: String, match: Regex<Regex<AnyRegexOutput>.RegexOutput>.Match) -> Int? {
        guard [.twentyFourHour, .twelveHour].contains(self) else { return nil }
        return Int(string[match[2].range!])
    }
    
    private func fetchAmPm(string: String, match: Regex<Regex<AnyRegexOutput>.RegexOutput>.Match) -> String? {
        guard [.hour, .twelveHour].contains(self) else { return nil }
        let position = self == .hour ? 2 : 3
        return String(string[match[position].range!])
    }
}
