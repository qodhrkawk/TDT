import UIKit

var str = "Hello, playground"

struct TodoData{
    var date: String?
    var todo: String?
    var isImportant: Bool?
    
    init(date: String, todo: String,isImportant: Bool) {
        self.date = date
        self.todo = todo
        self.isImportant = isImportant
    }
    
}

var dic : [Int : [TodoData]] = [1:[], 2:[], 3:[]]

