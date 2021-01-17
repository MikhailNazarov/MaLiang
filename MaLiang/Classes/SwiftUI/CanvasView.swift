//
//  File.swift
//  
//
//  Created by Mikhail Nazarov on 17.01.2021.
//

import SwiftUI

public struct CanvasView: NSViewRepresentable{
    
    public init(){
        
    }
    
    public func makeNSView(context: Context) -> Canvas {
        let canvas = Canvas()
        canvas.backgroundColor = .red
        canvas.clear()
        return canvas
    }
    
    public func updateNSView(_ nsView: Canvas, context: Context) {
        nsView.clear()
    }
    
    
    
}
