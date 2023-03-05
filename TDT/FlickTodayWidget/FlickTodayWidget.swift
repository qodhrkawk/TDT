//
//  FlickTodayWidget.swift
//  FlickTodayWidget
//
//  Created by Yunjae Kim on 2023/03/05.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    private var todoDatas: [WidgetTodoData] {
        guard let widgetData = WidgetDataManager.shared.widgetData else { return [] }
        
        let todayDateString = Date().stringValue()
        let todayData = widgetData.filter { $0.date == todayDateString }

        let storedTodoDatas = todayData.map { WidgetTodoData(todoData: $0) }
        
        return storedTodoDatas
    }
    
    func placeholder(in context: Context) -> FlickTodayWidgetEntry {
        return FlickTodayWidgetEntry(date: Date(), todoDatas: todoDatas)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlickTodayWidgetEntry) -> ()) {
        let entry = FlickTodayWidgetEntry(date: Date(), todoDatas: todoDatas)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [FlickTodayWidgetEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FlickTodayWidgetEntry(date: entryDate, todoDatas: todoDatas)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct FlickTodayWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemMedium:
            switch entry.todoDatas.count {
            case let x where x > 4 :
                FlickTodayMediumWidgetView(todoDatas: Array(entry.todoDatas[x-4..<x]))
            case let x where x > 0 && x <= 4 :
                FlickTodayMediumWidgetView(todoDatas: entry.todoDatas)
            default:
                FlickWidgetEmptyView(emptyCase: .today)
            }
        default:
            switch entry.todoDatas.count {
            case let x where x > 9 :
                FlickTodayLargeWidgetView(todoDatas: Array(entry.todoDatas[x-9..<x]))
            case let x where x > 0 && x <= 9:
                FlickTodayLargeWidgetView(todoDatas: entry.todoDatas)
            default:
                VStack {
                    Spacer()
                    FlickWidgetEmptyView(emptyCase: .today)
                    Spacer()
                    FlickLargeWidgetButtonView()
                        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 44, maxHeight: 44)
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                }
            }
        }
    }
}

struct FlickTodayWidget: Widget {
    let kind: String = "FlickTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FlickTodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘의 할 일")
        .description("예슬방귀 뿡뿡방귀")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
