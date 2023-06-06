//
//  DataStore.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 06/06/2023.
//

import Foundation
import SwiftUI
import Combine

struct Task: Identifiable {
    var id = String()
    var name = String()
}

class TaskDataStore: ObservableObject {
    @Published var tasks = [Task]()
    @Published var finished = [Task]()
    
    
    public func add(task: String) {
        tasks.append(Task(id:UUID().uuidString, name: task))
    }
    
    public func remove(id: String) {
        if let index = tasks.firstIndex(where: {$0.id.elementsEqual(id)}) {
            let task = tasks[index]
            tasks.remove(at: index)
            finished.append(task)
        }
    }
    
}
