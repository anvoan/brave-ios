// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WidgetKit
import SwiftUI
import Shared

struct FavoriteEntry: TimelineEntry {
    var date: Date
    var favorites: [Favorite]
}

struct Favorite {
    var url: URL
    fileprivate var faviconAttributes: FaviconAttributes?
}

private struct FaviconAttributes: Codable {
    var image: UIImage?
    var backgroundColor: UIColor?
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var includePadding: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case image
        case backgroundColor
        case contentMode
        case includePadding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image?.sd_imageData(), forKey: .image)
        var (r, g, b): (CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0)
        backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: nil)
        let rgb: Int = (Int(r * 255.0) << 16) | (Int(g * 255.0) << 8) | Int(b * 255.0)
        try container.encode(rgb, forKey: .backgroundColor)
        try container.encode(contentMode.rawValue, forKey: .contentMode)
        try container.encode(includePadding, forKey: .includePadding)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let imageData = try container.decode(Data?.self, forKey: .image) {
            image = UIImage(data: imageData)
        }
        if let rgb = try container.decode(Int?.self, forKey: .backgroundColor) {
            backgroundColor = UIColor(rgb: rgb)
        }
        contentMode = UIView.ContentMode(rawValue: try container.decode(Int.self, forKey: .contentMode)) ?? .scaleAspectFit
        includePadding = try container.decode(Bool.self, forKey: .includePadding)
    }
}

struct FavoritesProvider: TimelineProvider {
    typealias Entry = FavoriteEntry
    
    func favorites() -> [Favorite] {
        struct FavData: Decodable {
            var url: URL
            var favicon: FaviconAttributes?
        }
        if let sharedFolder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier) {
            let json = sharedFolder.appendingPathComponent("widget_data/favs.json")
            do {
                let jsonData = try Data(contentsOf: json)
                let favData = try JSONDecoder().decode([FavData].self, from: jsonData)
                return favData.map { data in
                    return Favorite(url: data.url, faviconAttributes: data.favicon)
                }
            } catch {
            }
        }
        return []
    }
    
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), favorites: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), favorites: favorites()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: Date(), favorites: favorites())], policy: .never))
    }
}

struct FaviconImage: View {
    var image: UIImage
    var contentMode: UIView.ContentMode
    
    var body: some View {
        switch contentMode {
        case .scaleToFill, .scaleAspectFit, .scaleAspectFill:
            Image(uiImage: image)
                .resizable()
        default:
            Image(uiImage: image)
                .resizable()
                .frame(width: 44, height: 44)
        }
    }
}

struct FavoritesView: View {
    var entry: FavoriteEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var numberOfRows: Int {
        switch widgetFamily {
        case .systemMedium:
            return 2
        case .systemLarge:
            return 4
        case .systemSmall:
            assertionFailure("systemSmall widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var verticalSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 8
        case .systemLarge:
            return 22
        case .systemSmall:
            assertionFailure("systemSmall widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var horizontalSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 18
        case .systemLarge:
            return 18
        case .systemSmall:
            assertionFailure("systemSmall widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var itemShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: widgetFamily == .systemMedium ? 16 : 12, style: .continuous)
    }
    
    func favorite(atRow row: Int, column: Int) -> Favorite? {
        let index = (row * 4) + column
        if index < entry.favorites.count {
            return entry.favorites[index]
        }
        return nil
    }
    
    @Environment(\.pixelLength) var pixelLength
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            ForEach(0..<numberOfRows) { row in
                HStack(spacing: horizontalSpacing) {
                    ForEach(0..<4) { column in
                        if let favorite = favorite(atRow: row, column: column) {
                            Link(destination: favorite.url, label: {
                                Group {
                                    if let attributes = favorite.faviconAttributes, let image = attributes.image {
                                        FaviconImage(image: image, contentMode: attributes.contentMode)
                                            .padding(attributes.includePadding ? 4 : 0)
                                            .background(Color(attributes.backgroundColor ?? .white))
                                    } else {
                                        Text(verbatim: favorite.url.baseDomain?.first?.uppercased() ?? "")
                                            .font(.system(size: 36))
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .overlay(
                                    itemShape
                                        .strokeBorder(Color.black.opacity(0.1), lineWidth: pixelLength)
                                )
                                .background(Color.white)
                                .clipShape(itemShape)
                            })
                        } else {
                            itemShape
                                .fill(Color.black.opacity(0.05))
                                .overlay(
                                    itemShape
                                        .strokeBorder(Color.black.opacity(0.2), lineWidth: pixelLength)
                                )
                                .aspectRatio(1.0, contentMode: .fit)
                        }
                    }
                }
            }
        }
//        .border(Color.red)
        .padding(8)
        .padding(widgetFamily == .systemLarge ? 4 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(red: 59.0/255.0, green: 62.0/255.0, blue: 79.0/255.0, alpha: 1.0)))
//        .border(Color.black)
    }
}

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FavoritesWidget", provider: FavoritesProvider()) { entry in
            FavoritesView(entry: entry)
        }
        .configurationDisplayName("Favorites")
        .description("Your favorite sites")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(entry: .init(date: Date(), favorites: [
//            .init(url: URL(string: "https://brave.com")!, faviconAttributes: <#T##FaviconAttributes?#>)
        ]))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        FavoritesView(entry: .init(date: Date(), favorites: []))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
