//
//  FlickWidget.swift
//  FlickWidget
//
//  Created by Yunjae Kim on 2023/03/04.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    private var todoDatas: [WidgetTodoData] {
        guard let widgetData = WidgetDataManager.shared.widgetData else { return [] }
        let storedTodoDatas = widgetData.map { WidgetTodoData(todoData: $0) }
        
        return storedTodoDatas
    }
    
    func placeholder(in context: Context) -> FlickWidgetEntry {
        return FlickWidgetEntry(date: Date(), todoDatas: todoDatas)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlickWidgetEntry) -> ()) {
        let entry = FlickWidgetEntry(date: Date(), todoDatas: todoDatas)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [FlickWidgetEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FlickWidgetEntry(date: entryDate, todoDatas: todoDatas)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct FlickWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemMedium:
            switch entry.todoDatas.count {
            case let x where x > 5 :
                FlickMediumWidgetView(todoDatas: Array(entry.todoDatas[x-5..<x]))
            case let x where x > 0 && x <= 5 :
                FlickMediumWidgetView(todoDatas: entry.todoDatas)
            default:
                FlickWidgetEmptyView()
            }
        default:
            switch entry.todoDatas.count {
            case let x where x > 10 :
                FlickLargeWidgetView(todoDatas: Array(entry.todoDatas[..<10]))
            case let x where x > 0 && x <= 10:
                FlickLargeWidgetView(todoDatas: entry.todoDatas)
            default:
                VStack {
                    Spacer()
                    FlickWidgetEmptyView()
                    Spacer()
                    FlickLargeWidgetButtonView()
                        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 44, maxHeight: 44)
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                }
            }
        }
    }
}

struct FlickWidget: Widget {
    let kind: String = "FlickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FlickWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("플릭 위젯")
        .description("골라봐~")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
