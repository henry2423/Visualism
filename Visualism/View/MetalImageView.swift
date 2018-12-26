//
//  MetalImageView.swift
//  Visualism
//
//  Created by Henry Huang on 12/9/18.
//  Copyright © 2018 Henry Huang. All rights reserved.
//

import UIKit
import MetalKit

enum MetalImageViewContentMode {
    case ScaleToFill
    case ScaleAspectFit
    case ScaleAspectFill
    case Center
    case Top
    case Bottom
    case Left
    case Right
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
}

class MetalImageView: MTKView {
    
    var image: CIImage? {
        didSet {
            self.draw()
        }
    }
    var imageContentMode: MetalImageViewContentMode = .ScaleAspectFit
    var commandQueue: MTLCommandQueue!
    let context: CIContext!
    
    // MARK: - Initialization
    convenience init(frame frameRect: CGRect) {
        let device = MTLCreateSystemDefaultDevice()
        self.init(frame: frameRect, device: device)
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        guard let device = device else {
            fatalError("Can't use Metal")
        }
        commandQueue = device.makeCommandQueue()
        context = CIContext(mtlDevice: device, options: [CIContextOption.useSoftwareRenderer:false])
        super.init(frame: frameRect, device: device)

        self.framebufferOnly = false
        //self.enableSetNeedsDisplay = false
        //self.isPaused = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Draw new Image
    override func draw(_ rect: CGRect) {
        guard let image = self.image, let colorSpace = image.colorSpace else {
            return
        }
        guard let drawable = self.currentDrawable, let texture = self.currentDrawable?.texture else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        var drawImage: CIImage = image
        var drawableRect: CGRect
        switch self.imageContentMode {
        case .ScaleToFill:
            // UIScreen.main.bounds.width * UIScreen.main.scale == self.drawableSize.width
            drawImage = image.transformed(by: CGAffineTransform(scaleX: self.drawableSize.width / image.extent.width, y: self.drawableSize.height / image.extent.height))
            drawableRect = alignCenter(from: drawImage.extent)
        case .ScaleAspectFit:
            let scale = min(self.drawableSize.height / image.extent.height, self.drawableSize.width / image.extent.width)
            drawImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            drawableRect = alignCenter(from: drawImage.extent)
        case .ScaleAspectFill:
            let scale = max(self.drawableSize.height / image.extent.height, self.drawableSize.width / image.extent.width)
            drawImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            drawableRect = alignCenter(from: drawImage.extent)
        case .Center:
            drawableRect = alignCenter(from: drawImage.extent)
        case .Top:
            drawableRect = alignTop(from: drawImage.extent)
        case .Bottom:
            drawableRect = alignBottom(from: drawImage.extent)
        case .Left:
            drawableRect = alignLeft(from: drawImage.extent)
        case .Right:
            drawableRect = alignRight(from: drawImage.extent)
        case .TopLeft:
            drawableRect = alignTopLeft(from: drawImage.extent)
        case .TopRight:
            drawableRect = alignTopRight(from: drawImage.extent)
        case .BottomLeft:
            drawableRect = alignBottomLeft(from: drawImage.extent)
        case .BottomRight:
            drawableRect = alignBottomRight(from: drawImage.extent)
        }

        context.render(drawImage, to: texture, commandBuffer: commandBuffer, bounds: drawableRect, colorSpace: colorSpace)

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    // MARK: - Supporting methods
    // Notice the (0,0) of CIImage is on Left-Bottom, and drawableRect is calaulated to set new Rect.origin with Image
    func alignCenter(from imageSize: CGRect) -> CGRect {
        let expectedX = (imageSize.width - self.drawableSize.width) / 2.0
        let expectedY = (imageSize.height - self.drawableSize.height) / 2.0
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
     
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignTop(from imageSize: CGRect) -> CGRect {
        let expectedX = (imageSize.width - self.drawableSize.width) / 2.0
        let expectedY = (imageSize.height - self.drawableSize.height)
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignBottom(from imageSize: CGRect) -> CGRect {
        let expectedX = (imageSize.width - self.drawableSize.width) / 2.0
        let expectedY = CGFloat(0.0)
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignLeft(from imageSize: CGRect) -> CGRect {
        let expectedX = CGFloat(0.0)
        let expectedY = (imageSize.height - self.drawableSize.height) / 2.0
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignRight(from imageSize: CGRect) -> CGRect {
        let expectedX = (imageSize.width - self.drawableSize.width)
        let expectedY = (imageSize.height - self.drawableSize.height) / 2.0
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignTopLeft(from imageSize: CGRect) -> CGRect {
        let expectedX = CGFloat(0.0)
        let expectedY = (imageSize.height - self.drawableSize.height)
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignTopRight(from imageSize: CGRect) -> CGRect {
        let expectedX = (imageSize.width - self.drawableSize.width)
        let expectedY = (imageSize.height - self.drawableSize.height)
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignBottomLeft(from imageSize: CGRect) -> CGRect {
        let expectedX = CGFloat(0.0)
        let expectedY = CGFloat(0.0)
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
    
    func alignBottomRight(from imageSize: CGRect) -> CGRect {
        let expectedX = (imageSize.width - self.drawableSize.width)
        let expectedY = CGFloat(0.0)
        let expectedWidth = self.drawableSize.width
        let expectedHeight = self.drawableSize.height
        
        return CGRect(x: expectedX, y: expectedY, width: expectedWidth, height: expectedHeight)
    }
}
