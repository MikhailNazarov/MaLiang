//
//  ScrollableCanvas.swift
//  MaLiang_Example
//
//  Created by Harley.xk on 2018/5/2.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

#if canImport(UIKit)
import UIKit
public typealias MView = UIView
public typealias MVisualEffectView = UIVisualEffectView
#endif

#if canImport(Cocoa)
import Cocoa
public typealias MView = NSView
public typealias MVisualEffectView = NSVisualEffectView
#endif

open class ScrollableCanvas: Canvas {
    
    open override func setup() {
        super.setup()
        
        setupScrollIndicators()
        
        contentSize = bounds.size
        
        #if os(iOS)
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGestureRecognizer(_:)))
        addGestureRecognizer(pinchGesture)
        
        moveGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMoveGestureRecognizer(_:)))
        moveGesture.minimumNumberOfTouches = 2
        addGestureRecognizer(moveGesture)
        #endif
    }
    
    /// the max zoomScale of canvas, will cause redraw if the new value is less than current
    open var maxScale: CGFloat = 5 {
        didSet {
            if maxScale < zoom {
                self.zoom = maxScale
                self.scale = maxScale
                self.redraw()
            }
        }
    }
    
    /// the actural size of canvas in points, wrapper of contentSize
    open override var size: CGSize {
        return contentSize
    }
    
    /// the actural drawable size of canvas, may larger than current bounds
    /// contentSize must between bounds size and 5120x5120
    open var contentSize: CGSize = .zero {
        didSet {
            updateScrollIndicators()
        }
    }
    #if os(iOS)
    /// get snapthot image for the same size to content
    open override func snapshot() -> MImage? {
        /// create a new render target with same size to the content, for snapshoting
        let target = SnapshotTarget(canvas: self)
        return target.getImage()
    }
   
    private var pinchGesture: UIPinchGestureRecognizer!
    private var moveGesture: UIPanGestureRecognizer!
    #endif
    private var currentZoomScale: CGFloat = 1
    private var offsetAnchor: CGPoint = .zero
    private var beginLocation: CGPoint = .zero
    #if os(iOS)
    @objc private func handlePinchGestureRecognizer(_ gesture: UIPinchGestureRecognizer) {
        let location = gesture.location(in: self)
        switch gesture.state {
        case .began:
            beginLocation = location
            offsetAnchor = location + contentOffset
            showScrollIndicators()
        case .changed:
            guard gesture.numberOfTouches >= 2 else {
                return
            }
            var scale = currentZoomScale * gesture.scale * gesture.scale
            scale = scale.valueBetween(min: 1, max: maxScale)
            self.zoom = scale
            self.scale = zoom
            
            var offset = offsetAnchor * (scale / currentZoomScale) - location
            offset = offset.between(min: .zero, max: maxOffset)
            let offsetChanged = contentOffset == offset
            contentOffset = offset
            
            redraw()
            updateScrollIndicators()
            
            actionObservers.canvas(self, didZoomTo: zoom)
            if offsetChanged {
                actionObservers.canvasDidScroll(self)
            }

        case .ended: fallthrough
        case .cancelled: fallthrough
        case .failed:
            currentZoomScale = zoom
            hidesScrollIndicators()
            actionObservers.canvas(self, didZoomTo: zoom)
        default: break
        }
    }
    
    @objc private func handleMoveGestureRecognizer(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        switch gesture.state {
        case .began:
            offsetAnchor = location + contentOffset
            showScrollIndicators()
        case .changed:
            guard gesture.numberOfTouches >= 2 else {
                return
            }
            contentOffset = (offsetAnchor - location).between(min: .zero, max: maxOffset)
            redraw()
            updateScrollIndicators()
            actionObservers.canvasDidScroll(self)
        default: hidesScrollIndicators()
        }
    }
    #endif
    private var maxOffset: CGPoint {
        return CGPoint(x: contentSize.width * zoom - bounds.width, y: contentSize.height * zoom - bounds.height)
    }
    
    // MARK: - Scrolling Indicators
    
    /// show indicator while scrolling, like UIScrollView
    
    // defaults to true if width of contentSize is larger than bounds
    open var showHorizontalScrollIndicator = true
    
    // defaults to true if height of contentSize is larger than bounds
    open var showVerticalScrollIndicator = true
    
    private weak var horizontalScrollIndicator: MView!
    private weak var verticalScrollIndicator: MView!
    
    private func setupScrollIndicators() {
        
        // horizontal scroll indicator
        #if os(iOS)
        let horizontalScrollIndicator = MVisualEffectView(effect: UIBlurEffect(style: .dark))
        horizontalScrollIndicator.layer.cornerRadius = 2
        horizontalScrollIndicator.clipsToBounds = true
        #else
        let horizontalScrollIndicator = MVisualEffectView()
        horizontalScrollIndicator.layer?.cornerRadius = 2
        //horizontalScrollIndicator.clipsToBounds = true
        #endif
        
        
        addSubview(horizontalScrollIndicator)
        self.horizontalScrollIndicator = horizontalScrollIndicator
        
        // vertical scroll indicator
        #if os(iOS)
        let verticalScrollIndicator = MVisualEffectView(effect: UIBlurEffect(style: .dark))
        verticalScrollIndicator.layer.cornerRadius = 2
        verticalScrollIndicator.clipsToBounds = true
        #else
        let verticalScrollIndicator = MVisualEffectView()
        verticalScrollIndicator.layer?.cornerRadius = 2
        //verticalScrollIndicator.clipsToBounds = true
        #endif
        
       
        addSubview(verticalScrollIndicator)
        self.verticalScrollIndicator = verticalScrollIndicator
        
        hidesScrollIndicators()
    }
    
    private func updateScrollIndicators() {
        
        let showHorizontal = showHorizontalScrollIndicator && contentSize.width > bounds.width
        horizontalScrollIndicator?.isHidden = !showHorizontal
        if showHorizontal {
            updateHorizontalScrollIndicator()
        }
        
        let showVertical = showVerticalScrollIndicator && contentSize.height > bounds.height
        verticalScrollIndicator.isHidden = !showVertical
        if showVertical {
            updateVerticalScrollIndicator()
        }
    }
    
    private func updateHorizontalScrollIndicator() {
        let ratio = bounds.width / contentSize.width / zoom
        let offsetRatio = contentOffset.x / contentSize.width / zoom
        let width = bounds.width - 12
        let frame = CGRect(x: offsetRatio * width + 4, y: bounds.height - 6, width: width * ratio, height: 4)
        horizontalScrollIndicator.frame = frame
    }
    
    private func updateVerticalScrollIndicator() {
        let ratio = bounds.height / contentSize.height / zoom
        let offsetRatio = contentOffset.y / contentSize.height / zoom
        let height = bounds.height - 12
        let frame = CGRect(x: bounds.width - 6, y: height * offsetRatio + 4, width: 4, height: height * ratio)
        verticalScrollIndicator.frame = frame
    }
    
    private func showScrollIndicators() {
        #if os(iOS)
        horizontalScrollIndicator.alpha = 0.8
        verticalScrollIndicator.alpha = 0.8
        #else
        horizontalScrollIndicator.alphaValue = 0.8
        verticalScrollIndicator.alphaValue = 0.8
        #endif
    }
    
    private func hidesScrollIndicators() {
        #if os(iOS)
        MView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.horizontalScrollIndicator.alpha = 0
            self.verticalScrollIndicator.alpha = 0
        })
        #else
        //todo: animation
        self.horizontalScrollIndicator.alphaValue = 0
        self.verticalScrollIndicator.alphaValue = 0
        #endif
    }
}
