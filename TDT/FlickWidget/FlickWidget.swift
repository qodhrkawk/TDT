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
        case .accessoryRectangular:
            switch entry.todoDatas.count {
            case let x where x > 3 :
                FlickAccessoryRectangularWidgetView(todoDatas: Array(entry.todoDatas[x-3..<x]))
            case let x where x > 0 && x <= 3 :
                FlickAccessoryRectangularWidgetView(todoDatas: entry.todoDatas)
            default:
                Text(EmptyCase.entire.emptyString)
                    .font(Font.custom("GmarketSansTTFMedium", size: 13))
                    .foregroundColor(Color("subText"))
            }
        case .systemMedium:
            switch entry.todoDatas.count {
            case let x where x > 5 :
                FlickMediumWidgetView(todoDatas: Array(entry.todoDatas[x-5..<x]))
            case let x where x > 0 && x <= 5 :
                FlickMediumWidgetView(todoDatas: entry.todoDatas)
            default:
                FlickWidgetEmptyView(emptyCase: .entire)
            }
        default:
            switch entry.todoDatas.count {
            case let x where x > 10 :
                FlickLargeWidgetView(todoDatas: Array(entry.todoDatas[x-10..<x]))
            case let x where x > 0 && x <= 10:
                FlickLargeWidgetView(todoDatas: entry.todoDatas)
            default:
                VStack {
                    Spacer()
                    FlickWidgetEmptyView(emptyCase: .entire)
                    Spacer()
                    FlickLargeWidgetButtonView()
                        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 38, maxHeight: 38)
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                }
            }
        }
    }
}

struct FlickWidget: Widget {
    let kind: String = "FlickWidget"
    var supportedFamilies: [WidgetFamily] = [.systemMedium, .systemLarge]
    
    init() {
        if #available(iOS 16.0, *) {
            supportedFamilies.append(.accessoryRectangular)
        }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FlickWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("할 일 보기")
        .description("최근 작성한 할 일을 모아보세요.")
        .supportedFamilies(supportedFamilies)
    }
}
