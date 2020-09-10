// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WidgetKit
import SwiftUI
import Intents
import Shared
import BraveShared

struct StatEntry: TimelineEntry {
    var date: Date
    var statData: StatData
}

struct StatData {
    var name: String
    var value: String
    var color: UIColor = .white
}

extension StatKind {
    var valueColor: UIColor {
        switch self {
        case .adsBlocked:
            return UIColor(rgb: 0xFB542B)
        case .httpsUpgrades:
            return UIColor(rgb: 0xA0A5EB)
        case .timeSaved:
            return .white
        case .unknown:
            return .white
        }
    }
    
    var name: String {
        switch self {
        case .adsBlocked:
            return Strings.shieldsAdAndTrackerStats
        case .httpsUpgrades:
            return Strings.shieldsHttpsStats
        case .timeSaved:
            return Strings.shieldsTimeStats
        case .unknown:
            return ""
        }
    }
    
    var displayString: String {
        switch self {
        case .adsBlocked:
            return BraveGlobalShieldStats.shared.adblock.kFormattedNumber
        case .httpsUpgrades:
            return BraveGlobalShieldStats.shared.httpse.kFormattedNumber
        case .timeSaved:
            return BraveGlobalShieldStats.shared.timeSaved
        case .unknown:
            return ""
        }
    }
}

struct StatProvider: IntentTimelineProvider {
    typealias Intent = StatsConfigurationIntent
    typealias Entry = StatEntry
    
    func placeholder(in context: Context) -> Entry {
        StatEntry(date: Date(), statData: .init(name: "Placeholder Count", value: "100k"))
    }
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        let stat = configuration.statKind
        let entry = StatEntry(date: Date(), statData: .init(name: stat.name, value: stat.displayString, color: stat.valueColor))
        completion(entry)
    }
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let stat = configuration.statKind
        let entry = StatEntry(date: Date(), statData: .init(name: stat.name, value: stat.displayString, color: stat.valueColor))
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct PlaceholderStatView: View {
    var entry: StatEntry
    
    var body: some View {
        StatView(entry: entry)
            .redacted(reason: .placeholder)
    }
}

struct StatView: View {
    var entry: StatEntry
    
    @ScaledMetric private var fontSize: CGFloat = 40
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(verbatim: entry.statData.value)
                .font(.system(size: fontSize))
                .foregroundColor(Color(entry.statData.color))
            Text(verbatim: entry.statData.name)
                .font(.caption)
                .bold()
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.25))
    }
}

struct StatWidget: Widget {
    let kind: String = "StatWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: StatsConfigurationIntent.self, provider: StatProvider()) { entry in
            StatView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Shields Stat")
        .description("Displays a shield stat")
    }
}

struct StatWidget_Previews: PreviewProvider {
    static var previews: some View {
        StatView(entry: StatEntry(date: Date(), statData: .init(name: "Ads & Trackers Blocked", value: "100k", color: BraveUX.braveOrange)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        StatView(entry: StatEntry(date: Date(), statData: .init(name: "Placeholder Count", value: "100k", color: BraveUX.braveOrange)))
            .redacted(reason: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
