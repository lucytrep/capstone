import SwiftUI

struct SettingsView: View {
    private let rows = [
        "Saved",
        "Output",
        "Privacy",
        "Notifications",
        "Appearance",
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    ForEach(rows.prefix(3), id: \.self) { row in
                        settingsRow(title: row)
                    }
                }

                Section("Preferences") {
                    ForEach(rows.suffix(2), id: \.self) { row in
                        settingsRow(title: row)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
        }
        .preferredColorScheme(.dark)
    }

    private func settingsRow(title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .listRowBackground(Color.white.opacity(0.05))
    }
}
