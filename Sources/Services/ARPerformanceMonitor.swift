//
//  ARPerformanceMonitor.swift
//  ARCodeClone
//
//  Monitoring de performance AR: FPS, memory, latency
//

import Foundation
import ARKit
import SceneKit
import os.log
import Darwin

protocol ARPerformanceMonitorProtocol {
    func startMonitoring()
    func stopMonitoring()
    func getCurrentMetrics() -> ARPerformanceMetrics
    var onPerformanceWarning: ((ARPerformanceWarning) -> Void)? { get set }
}

struct ARPerformanceMetrics {
    var fps: Float = 0
    var averageFrameTime: CFTimeInterval = 0
    var memoryUsage: UInt64 = 0
    var drawCalls: Int = 0
    var polygonCount: Int = 0
    var textureMemory: UInt64 = 0
}

enum ARPerformanceWarning {
    case lowFPS(actual: Float, target: Float)
    case highMemory(used: UInt64, limit: UInt64)
    case highLatency(ms: CFTimeInterval)
}

final class ARPerformanceMonitor: ARPerformanceMonitorProtocol {
    private var isMonitoring: Bool = false
    private var monitoringTimer: Timer?
    private var lastMetrics: ARPerformanceMetrics = ARPerformanceMetrics()
    
    private var arView: ARSCNView?
    private var renderingPipeline: ARRenderingPipelineProtocol?
    
    // Targets
    private let targetFPS: Float = 60.0
    private let minimumFPS: Float = 30.0
    private let memoryLimit: UInt64 = 150 * 1024 * 1024 // 150MB
    private let maxLatency: CFTimeInterval = 0.05 // 50ms
    
    // Callbacks
    var onPerformanceWarning: ((ARPerformanceWarning) -> Void)?
    
    init(arView: ARSCNView?, renderingPipeline: ARRenderingPipelineProtocol?) {
        self.arView = arView
        self.renderingPipeline = renderingPipeline
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Monitor every second
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func getCurrentMetrics() -> ARPerformanceMetrics {
        return lastMetrics
    }
    
    // MARK: - Metrics Collection
    
    private func collectMetrics() {
        var metrics = ARPerformanceMetrics()
        
        // FPS
        if let pipeline = renderingPipeline {
            metrics.fps = pipeline.getCurrentFPS()
            metrics.averageFrameTime = pipeline.getAverageFrameTime()
            
            // Check FPS warning
            if metrics.fps < minimumFPS {
                onPerformanceWarning?(.lowFPS(actual: metrics.fps, target: targetFPS))
            }
            
            // Check latency warning
            if metrics.averageFrameTime > maxLatency {
                onPerformanceWarning?(.highLatency(ms: metrics.averageFrameTime * 1000))
            }
        }
        
        // Memory
        metrics.memoryUsage = getMemoryUsage()
        
        // Check memory warning
        if metrics.memoryUsage > memoryLimit {
            onPerformanceWarning?(.highMemory(used: metrics.memoryUsage, limit: memoryLimit))
        }
        
        // Scene metrics
        if let scene = arView?.scene {
            metrics.drawCalls = estimateDrawCalls(scene: scene)
            metrics.polygonCount = estimatePolygonCount(scene: scene)
            metrics.textureMemory = estimateTextureMemory(scene: scene)
        }
        
        lastMetrics = metrics
        
        // Log metrics (debug)
        #if DEBUG
        logMetrics(metrics)
        #endif
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        }
        return 0
    }
    
    private func estimateDrawCalls(scene: SCNScene) -> Int {
        // Estimation basique du nombre de draw calls
        var drawCalls = 0
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.geometry != nil {
                drawCalls += 1
            }
        }
        return drawCalls
    }
    
    private func estimatePolygonCount(scene: SCNScene) -> Int {
        // Estimation basique du nombre de polygones
        var polygonCount = 0
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                // Estimation approximative
                if let sources = geometry.sources(for: .vertex) {
                    if let source = sources.first {
                        let vertexCount = source.vectorCount
                        // Estimation: ~2 triangles par vertex en moyenne
                        polygonCount += vertexCount * 2
                    }
                }
            }
        }
        return polygonCount
    }
    
    private func estimateTextureMemory(scene: SCNScene) -> UInt64 {
        // Estimation basique de la mémoire texture
        var textureMemory: UInt64 = 0
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                for material in geometry.materials {
                    // Estimation approximative
                    if let diffuse = material.diffuse.contents as? UIImage {
                        let width = Int(diffuse.size.width)
                        let height = Int(diffuse.size.height)
                        // RGBA = 4 bytes par pixel
                        textureMemory += UInt64(width * height * 4)
                    }
                }
            }
        }
        return textureMemory
    }
    
    private func logMetrics(_ metrics: ARPerformanceMetrics) {
        os_log("AR Performance - FPS: %.1f, FrameTime: %.2fms, Memory: %.2fMB, DrawCalls: %d, Polygons: %d",
               log: .default,
               type: .debug,
               metrics.fps,
               metrics.averageFrameTime * 1000,
               Double(metrics.memoryUsage) / 1024.0 / 1024.0,
               metrics.drawCalls,
               metrics.polygonCount)
    }
}

