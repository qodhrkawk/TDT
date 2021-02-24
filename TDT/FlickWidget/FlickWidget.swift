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
    let dateString : String
   
    
    
    
}


@available(iOS 14.0, *)
struct Provider: TimelineProvider {
    let myDefaults = UserDefaults.init(suiteName: "group.YunaeKim.TDT")
    var todoData: Data = Data()


    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        guard let todos = myDefaults?.stringArray(forKey: "todo")  else { return}
        let dateFormatter = DateFormatter()
        let date = Date()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: date)
       
        let entry = TodoEntry(todo: todos,dateString: dateString)
        let timeline = Timeline(entries: [entry], policy: .never)
        
        completion(timeline)
        
    }
    
    func placeholder(in context: Context) -> TodoEntry {
        guard let todos = myDefaults?.stringArray(forKey: "todo")  else { return TodoEntry(todo: [""],dateString: "")}
        let dateFormatter = DateFormatter()
        let date = Date()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: date)
        return TodoEntry(todo: todos,dateString: dateString)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        guard let todos = myDefaults?.stringArray(forKey: "todo")  else { return}
        let dateFormatter = DateFormatter()
        let date = Date()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: date)
        let entry = TodoEntry(todo: todos,dateString: dateString)
        completion(entry)
        
        
        
    }
    
   
    
    
    typealias Entry = TodoEntry
    
    
    
}


struct PlaceholderView: View{
    @Environment(\.widgetFamily) var size
    let entry: Provider.Entry
   
    
    var body: some View {
        var todos = entry.todo

        switch size {
      
        case .systemMedium :
            NavigationView {
                List {
                    ForEach(todos,id: \.self){ todo in
                        Text(todo)
                    }
                }
            }
            
            
            
        case .systemLarge :
            Text("4")
            
        default:
            Text("2")
        }
        
    }
    
    
}


@available(iOS 14.0, *)
struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var size
    let entry: Provider.Entry
    
    var body: some View {
        var todos = entry.todo
        
        switch size {
      
        case .systemMedium :
            GeometryReader { metrics in
                VStack {
                    
                    HStack {
                        Image("imgWidgetlogo")
                            .frame(minWidth: 0, idealWidth: 52, maxWidth: 52, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(EdgeInsets(top: 20, leading: 16, bottom: 15, trailing: 0))
                        Spacer()
                        
                        Text(entry.dateString)
//                        Text("2020.02.14")
                            
                            
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 15, trailing: 16))
                            .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: .infinity, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .trailing)
                            .font(.system(size: 15))
                            

                    }
                    .background(Color(UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 239.0/255.0, alpha: 1.0)))
                    .frame(width: metrics.size.width, height: metrics.size.height*0.27, alignment: .center)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .ignoresSafeArea()
                    
                    
                    
                    VStack{
                        
                        if todos.count == 0 {
                            
                        }
                        else if todos.count < 3 {
                            ForEach(todos,id: \.self){ item in
                                Text(item)
                                    .frame(width: metrics.size.width-32.0, height: metrics.size.height*0.1, alignment: .leading)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 15))
                                    
                                    
                                Divider()

                            }
                            .padding(EdgeInsets(top: 0, leading:16, bottom: 0, trailing: 16))
                        }
                        else {
                            
                            Text(todos[0])
                                .frame(width: metrics.size.width-32.0, height: metrics.size.height*0.1, alignment: .leading)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 15))
                                .padding(EdgeInsets(top: 0, leading:16, bottom: 0, trailing: 16))
                            Divider()
                                .padding(EdgeInsets(top: 0, leading:16, bottom: 0, trailing: 16))
                            Text(todos[1])
                                .frame(width: metrics.size.width-32.0, height: metrics.size.height*0.1, alignment: .leading)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 15))
                                .padding(EdgeInsets(top: 0, leading:16, bottom: 0, trailing: 16))
                            Divider()
                                .padding(EdgeInsets(top: 0, leading:16, bottom: 0, trailing: 16))
                            Text(todos[2])
                                .frame(width: metrics.size.width-32.0, height: metrics.size.height*0.1, alignment: .leading)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 15))
                                .padding(EdgeInsets(top: 0, leading:16, bottom: 0, trailing: 16))
                           
                            
                            
                            
                        }

                    
                  
                    }
                    .background(Color.white)
                    
                }
                .frame(width: metrics.size.width, height: metrics.size.height, alignment: .top)
                .ignoresSafeArea()
            
                
            }
            
            
        case .systemLarge :
            Text("98998")
            
            
        default:
            Text("2")
        }
//        Text(entry.todo[0])
//            .onAppear(perform: {
//                Text(entry.todo[0])
//            })
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
        .supportedFamilies([.systemMedium,.systemLarge])
        
    }
    
    
}


