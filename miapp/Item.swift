//
//  Item.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
