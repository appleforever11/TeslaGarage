import SwiftUI
import AppKit
import MapKit

struct GarageCanvas: View {
    @Bindable var store: GarageStore
    @State private var mapPanelWidth: CGFloat = -1
    @State private var mapDragStartWidth: CGFloat?
    var body: some View {
        GeometryReader { proxy in
            let defaultMapWidth = proxy.size.width * 0.595
            let maximumMapWidth = max(0, proxy.size.width - 250)
            let visibleMapWidth = min(max(mapPanelWidth < 0 ? defaultMapWidth : mapPanelWidth, 0), maximumMapWidth)
            let vehicleWidth = proxy.size.width - visibleMapWidth
            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.035)
                HStack(spacing: 0) {
                    VehicleStage(store: store)
                        .frame(width: vehicleWidth)
                    MapStage(store: store)
                        .frame(width: visibleMapWidth)
                        .frame(maxHeight: .infinity)
                }
                MapSplitDragZone(
                    onChanged: { translation in
                        if mapDragStartWidth == nil { mapDragStartWidth = visibleMapWidth }
                        let start = mapDragStartWidth ?? visibleMapWidth
                        mapPanelWidth = min(max(start - translation, 0), maximumMapWidth)
                    },
                    onEnded: { _ in
                        mapDragStartWidth = nil
                        if visibleMapWidth < 78 {
                            withAnimation(.easeInOut(duration: 0.34)) { mapPanelWidth = 0 }
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, max(0, visibleMapWidth - 12))
                if store.showVehicleMenu {
                    VehicleSettingsMenu(store: store)
                        .frame(width: defaultMapWidth, height: max(360, proxy.size.height - 114))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 62)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                VStack(spacing: 0) {
                    CockpitStatus(store: store).padding(.horizontal, 20).padding(.top, 13)
                    Spacer()
                    AppDock(store: store).padding(.horizontal, 22).padding(.bottom, 14)
                }
            }
        }
    }
}

private struct MapSplitDragZone: View {
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void
    var body: some View {
        Color.clear
            .frame(width: 24)
            .contentShape(Rectangle())
            .onHover { isHovering in
                if isHovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in onChanged(value.translation.width) }
                    .onEnded { value in onEnded(value.translation.width) }
            )
    }
}

private struct CockpitStatus: View {
    @Bindable var store: GarageStore
    var body: some View {
        HStack {
            HStack(spacing: 5) { Text("P"); Text("R"); Text("N"); Text("D") }.font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.58))
            Spacer()
            Label("\(store.snapshot.batteryLevel)%", systemImage: "battery.75percent").font(.caption.weight(.medium))
            Divider().frame(height: 12)
            Label("7:43 AM", systemImage: "lock.fill").font(.caption)
            Divider().frame(height: 12)
            Text("72°F").font(.caption)
            Divider().frame(height: 12)
            Label("Kevin", systemImage: "person.crop.circle").font(.caption)
        }.foregroundStyle(.white.opacity(0.88))
    }
}

private struct VehicleStage: View {
    @Bindable var store: GarageStore
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(colors: [.white.opacity(0.08), .clear], center: .center, startRadius: 12, endRadius: 270)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.43)
                HeroVehicleImage()
                    .frame(width: min(proxy.size.width * 0.88, 470), height: min(proxy.size.height * 0.43, 285))
                    .shadow(color: .black.opacity(0.7), radius: 18, y: 18)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.43)
                Image(systemName: "lock.fill")
                    .font(.system(size: 17, weight: .medium))
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.19)
                VehicleCallout(title: "Open", action: "Frunk")
                    .position(x: proxy.size.width * 0.18, y: proxy.size.height * 0.36)
                VehicleCallout(title: "Open", action: "Trunk")
                    .position(x: proxy.size.width * 0.82, y: proxy.size.height * 0.29)
                MediaCard()
                    .frame(maxWidth: 390)
                    .padding(.horizontal, 14)
                    // Keep the complete player above the persistent app dock at compact heights.
                    .position(x: proxy.size.width * 0.5, y: max(150, proxy.size.height - 151))
            }
        }
        .background(LinearGradient(colors: [Color.black.opacity(0.48), Color.black.opacity(0.08)], startPoint: .top, endPoint: .bottom))
    }
}

private struct HeroVehicleImage: View {
    var body: some View {
        if let url = Bundle.module.url(forResource: "model3-hero", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image).resizable().scaledToFit()
        } else {
            Image(systemName: "car.side.fill").resizable().scaledToFit().foregroundStyle(.white.opacity(0.75))
        }
    }
}

private struct VehicleCallout: View {
    let title: String; let action: String
    var body: some View { VStack(alignment: .leading, spacing: 2) { Text(title).font(.caption2).foregroundStyle(.white.opacity(0.55)); Text(action).font(.caption.weight(.medium)) }.padding(.leading, 9).overlay(alignment: .leading) { Rectangle().fill(.white.opacity(0.5)).frame(width: 1, height: 38).offset(x: -9) } }
}

private struct MediaCard: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 5).fill(LinearGradient(colors: [.gray, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom)).frame(width: 45, height: 45).overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.8)))
                VStack(alignment: .leading, spacing: 3) { Text("A PERFECT WORLD").font(.caption.weight(.semibold)); Text("The Kid LAROI").font(.caption2).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "shuffle").font(.caption); Image(systemName: "repeat").font(.caption)
            }.padding(13)
            Divider().overlay(.white.opacity(0.08))
            HStack { Image(systemName: "backward.fill"); Spacer(); Image(systemName: "play.fill").font(.title3); Spacer(); Image(systemName: "forward.fill"); Spacer(); Image(systemName: "heart"); Spacer(); Image(systemName: "slider.horizontal.3") }.font(.caption).padding(.horizontal, 24).padding(.vertical, 13)
        }.background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct MapStage: View {
    @Bindable var store: GarageStore
    @State private var position = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1430),
        span: MKCoordinateSpan(latitudeDelta: 0.034, longitudeDelta: 0.042)
    ))

    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $position, interactionModes: []) {
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1430)) {
                    ZStack {
                        Image(systemName: "location.north.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        Image(systemName: "location.north.fill").font(.system(size: 26, weight: .bold)).foregroundStyle(.red).opacity(0.94)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
            .colorScheme(.dark)
            .saturation(0.32)
            .brightness(-0.25)
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 10) { Image(systemName: "magnifyingglass"); Text("Navigate").font(.subheadline).foregroundStyle(.white.opacity(0.72)) }
                HStack(spacing: 30) { Label("Home", systemImage: "house.fill"); Divider().frame(height: 20); Label("Work", systemImage: "briefcase.fill") }.font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.80))
            }.padding(29)
            VStack { Spacer(); HStack { Spacer(); Text("Local map preview").font(.caption2).padding(8).background(.black.opacity(0.35), in: Capsule()) } }.padding(17)
        }
    }
}

private struct VehicleSettingsMenu: View {
    @Bindable var store: GarageStore
    private let rows = GarageSection.allCases

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.caption)
                    Text("Search Settings").font(.caption)
                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.52))
                .padding(.horizontal, 16).padding(.vertical, 14)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(rows) { section in
                            Button {
                                store.selectedSection = section
                            } label: {
                                Label(section.rawValue, systemImage: section.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(store.selectedSection == section ? 0.96 : 0.68))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 15).padding(.vertical, 9)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .stroke(store.selectedSection == section ? .white.opacity(0.74) : .clear, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 7).padding(.bottom, 14)
                }
            }
            .frame(width: 220)
            .padding(.top, 8)
            .background(Color(red: 0.18, green: 0.18, blue: 0.18))

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(store.selectedSection.rawValue.uppercased())
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Button { withAnimation(.easeInOut(duration: 0.2)) { store.showVehicleMenu = false } } label: {
                        Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.55)).frame(width: 28, height: 28)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 22).padding(.vertical, 15)

                Divider().overlay(.white.opacity(0.08))
                ScrollView(.vertical, showsIndicators: true) {
                    ControlMenuContent(section: store.selectedSection, snapshot: store.snapshot)
                        .padding(22)
                        .padding(.bottom, 34)
                }
            }
            .background(Color(red: 0.135, green: 0.135, blue: 0.135))
        }
        .clipShape(RoundedRectangle(cornerRadius: 1))
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.10)).frame(height: 1) }
    }
}

private struct ControlMenuContent: View {
    let section: GarageSection
    let snapshot: VehicleSnapshot

    var body: some View {
        if section == .controls {
            VStack(alignment: .leading, spacing: 18) {
                Text("Quick Controls").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ControlTile(title: "Front Trunk", symbol: "square.and.arrow.up", value: "Closed")
                    ControlTile(title: "Rear Trunk", symbol: "rectangle.portrait.and.arrow.forward", value: "Closed")
                    ControlTile(title: "Charge Port", symbol: "bolt.car", value: "Closed")
                    ControlTile(title: "Open Glovebox", symbol: "rectangle.portrait.and.arrow.right", value: "Ready")
                    ControlTile(title: "Mirror Fold", symbol: "rectangle.on.rectangle", value: "Extended")
                    ControlTile(title: "Car Wash Mode", symbol: "drop.fill", value: "Off")
                }

                Text("Security").font(.headline).padding(.top, 4)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ToggleControl(title: "Sentry Mode", detail: "Off", symbol: "eye.fill")
                    ToggleControl(title: "Child Lock", detail: "Off", symbol: "lock.fill")
                    ToggleControl(title: "Window Lock", detail: "Off", symbol: "window.vertical.closed")
                    ToggleControl(title: "Tilt & Intrusion", detail: "Off", symbol: "shield.fill")
                }

                Text("Vehicle").font(.headline).padding(.top, 4)
                HStack(spacing: 20) {
                    Label("Locked", systemImage: "lock.fill")
                    Label("Pearl White", systemImage: "paintpalette.fill")
                    Label("Parked", systemImage: "parkingsign")
                }.font(.subheadline).foregroundStyle(.white.opacity(0.76))
            }
        } else {
            VStack(alignment: .leading, spacing: 15) {
                Text(section.rawValue).font(.headline)
                Text("Vehicle controls for your 2021 Model 3 Standard Range Plus.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.58))
                Divider().overlay(.white.opacity(0.12))
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Image(systemName: section.icon).frame(width: 20)
                        Text(sectionDetail(section, index: index))
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.38))
                    }
                    .font(.subheadline)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func sectionDetail(_ section: GarageSection, index: Int) -> String {
        let details: [GarageSection: [String]] = [
            .dynamics: ["Acceleration", "Steering Mode", "Stopping Mode", "Chill Mode", "Slip Start"],
            .charging: ["Charge Limit", "Charging Current", "Scheduled Charging", "Departure", "Supercharging"],
            .autopilot: ["Autosteer", "Traffic-Aware Cruise", "Full Self-Driving", "Speed Limit", "Autopilot Visualization"],
            .locks: ["Walk-Away Door Lock", "Driver Door Unlock Mode", "Unlock on Park", "Child Protection", "Phone Key"],
            .lights: ["Headlights", "Dome Lights", "Auto High Beam", "Ambient Lights", "Headlight After Exit"],
            .seats: ["Front Seat Heaters", "Rear Seat Heaters", "Steering Wheel Heat", "Keep Climate On", "Seat Position"],
            .display: ["Display Brightness", "Screen Clean Mode", "Appearance", "Language", "Touchscreen"],
            .schedule: ["Scheduled Departure", "Precondition", "Off-Peak Charging", "Departure Days", "Climate"],
            .safety: ["Forward Collision Warning", "Automatic Emergency Braking", "Lane Departure Avoidance", "Emergency Lane Departure", "Dashcam"],
            .service: ["Towing", "Wheel Configuration", "Owner's Manual", "Factory Reset", "Service Mode"],
            .software: ["Software Update", "Release Notes", "Vehicle Information", "Install Update", "Additional Information"],
            .navigation: ["Trip Planner", "Online Routing", "Avoid Ferries", "Avoid Tolls", "Home Address"],
            .trips: ["Current Trip", "Since Last Charge", "Since Last Reset", "Lifetime", "Energy"],
            .wifi: ["Wi-Fi Networks", "Known Networks", "Connect Automatically", "Hotspot", "Network Details"],
            .bluetooth: ["Paired Devices", "Phone Key", "Add Device", "Media Source", "Device Priority"],
            .audio: ["Equalizer", "Balance", "Immersive Sound", "Subwoofer", "Streaming Quality"],
            .upgrades: ["Autopilot Upgrades", "Premium Connectivity", "Acceleration Boost", "Accessories", "Shop Tesla"]
        ]
        return details[section]?[index] ?? "Vehicle Setting"
    }
}

private struct ControlTile: View {
    let title: String
    let symbol: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol).font(.title3)
            Text(title).font(.caption.weight(.medium))
            Text(value).font(.caption2).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct ToggleControl: View {
    let title: String
    let detail: String
    let symbol: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.body).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.medium))
                Text(detail).font(.caption2).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Capsule().fill(.white.opacity(0.16)).frame(width: 28, height: 16)
                .overlay(alignment: .leading) { Circle().fill(.white.opacity(0.72)).frame(width: 12, height: 12).padding(2) }
        }
        .padding(12)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct AppDock: View {
    @Bindable var store: GarageStore
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 18) {
                TeslaDockGlyph(symbol: "car.fill", label: "Controls") { withAnimation(.easeInOut(duration: 0.22)) { store.showVehicleMenu.toggle() } }
                DockChevron(direction: "left")
                Text("69").font(.system(size: 25, weight: .regular, design: .rounded)).monospacedDigit()
                DockChevron(direction: "right")
            }
            .frame(width: 292, alignment: .leading)

            HStack(spacing: 34) {
                DockAppIcon(app: .navigation, label: "Navigation") { store.selectedSection = .controls }
                DockAppIcon(app: .phone, label: "Phone") {}
                DockAppIcon(app: .calendar, label: "Calendar") { store.selectedSection = .schedule }
                DockAppIcon(app: .bluetooth, label: "Bluetooth") {}
                DockAppIcon(app: .spotify, label: "Spotify") {}
                DockAppIcon(app: .theater, label: "Theater") {}
                DockAppIcon(app: .more, label: "More") {}
                DockAppIcon(app: .arcade, label: "Arcade") {}
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 19) {
                DockChevron(direction: "left")
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 19, weight: .medium))
                DockChevron(direction: "right")
            }
            .frame(width: 155, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(0.78))
        .padding(.horizontal, 28)
        .frame(height: 62)
        .background(Color.black.opacity(0.97))
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.10)).frame(height: 1) }
    }
}

private struct TeslaDockGlyph: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 25, height: 30)
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

private struct DockChevron: View {
    let direction: String
    var body: some View {
        Image(systemName: "chevron." + direction)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .frame(width: 18, height: 30)
    }
}

private enum DockApp { case navigation, phone, calendar, bluetooth, spotify, theater, more, arcade }

private struct DockAppIcon: View {
    let app: DockApp
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                iconFace
            }
            .frame(width: 25, height: 25)
        }
        .buttonStyle(.plain)
        .help(label)
    }

    @ViewBuilder private var iconFace: some View {
        switch app {
        case .navigation:
            RasterDockIcon(name: "tesla-nav-reference")
        case .phone:
            Image(systemName: "phone.fill").font(.system(size: 23, weight: .medium)).foregroundStyle(Color(red: 0.25, green: 0.90, blue: 0.37))
        case .calendar:
            TeslaCalendarMark()
        case .bluetooth:
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color(red: 0.08, green: 0.46, blue: 0.88))
            TeslaBluetoothMark().stroke(.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)).frame(width: 13, height: 17)
        case .spotify:
            TeslaSpotifyMark()
        case .theater:
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color(red: 0.18, green: 0.18, blue: 0.18))
            Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)).foregroundStyle(.orange).offset(x: -4, y: -3)
            Circle().fill(Color(red: 0.35, green: 0.75, blue: 0.61)).frame(width: 6, height: 6).offset(x: 6, y: 5)
            RoundedRectangle(cornerRadius: 1.5).fill(Color(red: 0.94, green: 0.51, blue: 0.26)).frame(width: 8, height: 4).rotationEffect(.degrees(25)).offset(x: -4, y: 7)
        case .more:
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.black)
            RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(.white.opacity(0.70), lineWidth: 1)
            Image(systemName: "ellipsis").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
        case .arcade:
            RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.21, green: 0.21, blue: 0.21)).frame(width: 23, height: 7).offset(y: 6)
            Rectangle().fill(Color(red: 0.55, green: 0.55, blue: 0.55)).frame(width: 1.5, height: 11).offset(x: -4, y: -1)
            Circle().fill(Color(red: 0.85, green: 0.20, blue: 0.25)).frame(width: 7, height: 7).offset(x: -4, y: -7)
        }
    }
}

private struct TeslaNavigationMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(red: 0.16, green: 0.17, blue: 0.19))
            Rectangle()
                .fill(.white.opacity(0.16))
                .frame(width: 4, height: 32)
                .rotationEffect(.degrees(31))
                .offset(x: -2)
            Rectangle()
                .fill(Color(red: 0.24, green: 0.36, blue: 0.87))
                .frame(width: 5, height: 31)
                .rotationEffect(.degrees(31))
                .offset(x: 2)
            TeslaNavigationArrow()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.30))
                .overlay { TeslaNavigationArrow().stroke(.white.opacity(0.90), lineWidth: 0.65) }
                .frame(width: 8, height: 12)
                .rotationEffect(.degrees(31))
                .offset(x: -3.2, y: -0.7)
        }
    }
}

private struct TeslaCalendarMark: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 4)
                .fill(Color(red: 0.93, green: 0.18, blue: 0.18))
                .frame(height: 5)
            Text("9")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.88))
                .padding(.top, 4)
        }
    }
}

private struct TeslaNavigationArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Tesla's launcher uses a small, narrow direction pointer rather than a paper-plane glyph.
        path.move(to: CGPoint(x: rect.maxX * 0.86, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.90))
        path.addLine(to: CGPoint(x: rect.midX * 1.06, y: rect.maxY * 0.67))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.30, y: rect.maxY * 0.48))
        path.closeSubpath()
        return path
    }
}

private struct TeslaSpotifyMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.10, green: 0.82, blue: 0.32))
            SpotifyLines().stroke(.black, style: StrokeStyle(lineWidth: 2.25, lineCap: .round))
                .frame(width: 16, height: 13)
                .offset(y: 1)
        }
    }
}

private struct SpotifyLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let widths: [(CGFloat, CGFloat)] = [(0.06, 0.95), (0.12, 0.89), (0.19, 0.82)]
        for (index, pair) in widths.enumerated() {
            let y = rect.minY + CGFloat(index) * rect.height * 0.34
            path.move(to: CGPoint(x: rect.minX + rect.width * pair.0, y: y))
            path.addCurve(
                to: CGPoint(x: rect.minX + rect.width * pair.1, y: y + 1.2),
                control1: CGPoint(x: rect.minX + rect.width * 0.37, y: y - 2.1),
                control2: CGPoint(x: rect.minX + rect.width * 0.69, y: y - 0.8)
            )
        }
        return path
    }
}

private struct TeslaBluetoothMark: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.midX
        let top = rect.minY
        let bottom = rect.maxY
        let left = rect.minX
        let right = rect.maxX
        var path = Path()
        path.move(to: CGPoint(x: x, y: top))
        path.addLine(to: CGPoint(x: right, y: rect.midY - 4))
        path.addLine(to: CGPoint(x: x, y: rect.midY))
        path.addLine(to: CGPoint(x: right, y: rect.midY + 4))
        path.addLine(to: CGPoint(x: x, y: bottom))
        path.addLine(to: CGPoint(x: x, y: top))
        path.move(to: CGPoint(x: left, y: top + 4))
        path.addLine(to: CGPoint(x: right, y: bottom - 4))
        path.move(to: CGPoint(x: left, y: bottom - 4))
        path.addLine(to: CGPoint(x: right, y: top + 4))
        return path
    }
}

private struct ReferenceDockIcon: View {
    let name: String

    private var colorImage: NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "svg"),
              let image = NSImage(contentsOf: url),
              let copy = image.copy() as? NSImage else { return nil }
        copy.isTemplate = false
        return copy
    }

    var body: some View {
        if let colorImage {
            Image(nsImage: colorImage)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
        }
    }
}

private struct RasterDockIcon: View {
    let name: String

    var body: some View {
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
        }
    }
}
