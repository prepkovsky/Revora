import SwiftUI

/// Answers to common questions, grouped by topic. Each question opens to show its answer,
/// so the whole list can be scanned first.
struct HelpView: View {
    var body: some View {
        List {
            Text("Answers to common questions about Revora. Tap a question to see its answer.")
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

            ForEach(HelpTopic.all) { topic in
                Section {
                    ForEach(topic.questions) { item in
                        DisclosureGroup {
                            Text(item.answer)
                                .foregroundStyle(.secondary)
                        } label: {
                            Text(item.question)
                        }
                    }
                } header: {
                    Text(topic.title)
                }
                .listRowBackground(Color.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.appBackground)
        .navigationTitle("Help")
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
