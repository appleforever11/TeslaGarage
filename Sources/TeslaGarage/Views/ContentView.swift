import SwiftUI

struct ContentView: View {
    @Bindable var store: GarageStore
    var body: some View {
        ZStack {
            GarageCanvas(store: store)
        }
        .preferredColorScheme(.dark)
    }
}

private struct Sidebar: View {
    @Bindable var store: GarageStore
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 9) { Image(systemName: "car.rear.road.lane").foregroundStyle(.red); Text("TESLA GARAGE").font(.system(size: 14, weight: .bold, design: .rounded)) }
            Text("MY VEHICLE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            Text(store.snapshot.name).font(.caption).foregroundStyle(.secondary)
            Divider().overlay(.white.opacity(0.12))
            ForEach(GarageSection.allCases) { section in
                Button { store.selectedSection = section } label: {
                    Label(section.rawValue, systemImage: section.icon).font(.system(size: 13, weight: .medium)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10).padding(.vertical, 8).background(store.selectedSection == section ? Color.white.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 7) {
                Label(store.refreshMessage, systemImage: "externaldrive.badge.timemachine").font(.caption).foregroundStyle(.secondary)
                Button("Refresh") { store.refresh() }.buttonStyle(.bordered).controlSize(.small)
            }
        }.padding(20)
    }
}
