//
//  MessageStore.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 06/06/2023.
//

import Foundation

class MessageStore: ObservableObject {
    @Published var message : String = "";
    
    private var timer: Timer? = nil;
    private var delay: Double = 3.0
    
    func showError(message: String) {
        self.message = message
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats:false) {_ in
            self.message = "";
        }
        
    }
    
}
