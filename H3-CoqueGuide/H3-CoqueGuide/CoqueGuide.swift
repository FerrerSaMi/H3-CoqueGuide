

import Foundation
import SwiftData

@Model
final class CoqueGuide {
    var id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        
    }
    
}


