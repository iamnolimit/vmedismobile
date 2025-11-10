// File: Utilities/LazyView.swift - Lazy loading utility for SwiftUI views
import SwiftUI

// LazyView helps prevent circular dependencies and improves performance
// by deferring view instantiation until actually needed
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}
