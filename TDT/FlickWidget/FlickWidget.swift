//
//  FlickWidget.swift
//  FlickWidget
//
//  Created by Yunjae Kim on 2021/02/10.
//

import WidgetKit
import SwiftUI


struct TodoEntry: TimelineEntry {
    let date = Date()
    let todo: [String]
    
    
    
}


@available(iOS 14.0, *)
struct Provider: TimelineProvider {
    let myDefaults = UserDefaults.init(suiteName: "group.YunaeKim.TDT")
    var todoData: Data = Data()


    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        guard let todo = myDefaults?.string(forKey: "todo")  else { return}
        let entry = TodoEntry(todo: [todo])
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
        
    }
    
    func placeholder(in context: Context) -> TodoEntry {
        guard let todo = myDefaults?.string(forKey: "todo")  else { return TodoEntry(todo: [""])}
        return TodoEntry(todo: [todo])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        guard let todo = myDefaults?.string(forKey: "todo")  else { return}
        
        let entry = TodoEntry(todo: [todo])
        completion(entry)
        
        
        
    }
    
   
    
    
    typealias Entry = TodoEntry
    
    
    
}


struct PlaceholderView: View{
    let entry: Provider.Entry
    var body: some View {
       
        Text(entry.todo[0])
        
    }
    
    
}


@available(iOS 14.0, *)
struct WidgetEntryView: View {
    let entry: Provider.Entry
    
    var body: some View {
        Text(entry.todo[0])
            .onAppear(perform: {
                Text(entry.todo[0])
            })
    }
     
    
}



@main
struct FlickWidget: Widget {
    private let kind = "FlickWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
            
        }
        .configurationDisplayName("오늘의 할일")
        .description("오늘의 할일을 체크해보세요")
        
    }
    
    
}
