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
    let regex = try! Regex("([0-1]?[0-9]|2[0-3]):([0-5][0-9])")
    
    init(_ string: String) {
        self.string = string
    }
    
    func parseDate() -> Date? {
        guard let match = string.wholeMatch(of: regex) else { return nil }
        
        guard let hour = Int(string[match[1].range!]) else { return nil }
        guard let minute = Int(string[match[2].range!]) else { return nil }
        
        return Calendar.current.date(from: .init(hour: hour, minute: minute))
    }
}
