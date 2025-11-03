//
//  ARExperienceView.swift
//  ARCodeClone
//
//  Vue AR complète avec pipeline de rendu, gestes, overlay, performance
//

import SwiftUI
import ARKit
import SceneKit

struct ARExperienceView: View {
    @StateObject private var viewModel: ARExperienceViewModel
    @State private var arView: ARSCNView?
    @State private var selectedNode: SCNNode?
    @State private var showOverlay: Bool = true
    @State private var showPerformanceMetrics: Bool = false
    
    init(viewModel: ARExperienceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // AR View
            ARExperienceViewContainer(
                viewModel: viewModel,
                arView: $arView,
                selectedNode: $selectedNode
            )
            .ignoresSafeArea()
            
            // Overlay UI
            if showOverlay {
                AROverlayView(
                    arView: $arView,
                    showARView: .constant(true), // Géré par navigation parent
                    selectedNode: selectedNode,
                    ctaLinks: viewModel.ctaLinks,
                    onCTATap: { link in
                        viewModel.handleCTATap(link)
                    }
                )
            }
            
            // Performance Metrics (debug)
            if showPerformanceMetrics {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FPS: \(String(format: "%.1f", viewModel.currentFPS))")
                            Text("Memory: \(String(format: "%.1f", viewModel.memoryUsage / 1024.0 / 1024.0))MB")
                            Text("FrameTime: \(String(format: "%.2f", viewModel.averageFrameTime * 1000))ms")
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.setupARView(arView)
            showPerformanceMetrics = false // Désactiver en production
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - AR Experience View Container

struct ARExperienceViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARExperienceViewModel
    @Binding var arView: ARSCNView?
    @Binding var selectedNode: SCNNode?
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        // Configuration AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        // Créer scène
        let scene = SCNScene()
        arView.scene = scene
        
        // Configuration rendering
        arView.antialiasingMode = .multisampling4X
        arView.preferredFramesPerSecond = 60
        arView.automaticallyUpdatesLighting = true
        arView.autoenablesDefaultLighting = false
        
        // Démarrage session
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Setup pipeline et gestes
        viewModel.setupARView(arView)
        
        // Définir delegate
        arView.session.delegate = context.coordinator
        arView.delegate = context.coordinator
        
        self.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Mises à jour si nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, selectedNode: $selectedNode)
    }
    
    class Coordinator: NSObject, ARSessionDelegate, ARSCNViewDelegate {
        @ObservedObject var viewModel: ARExperienceViewModel
        @Binding var selectedNode: SCNNode?
        
        init(viewModel: ARExperienceViewModel, selectedNode: Binding<SCNNode?>) {
            self.viewModel = viewModel
            _selectedNode = selectedNode
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            viewModel.updateFrame(frame)
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            viewModel.handleAnchorsAdded(anchors)
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            viewModel.handleAnchorsUpdated(anchors)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // Ajouter visualisation pour anchor si nécessaire
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            // Mettre à jour visualisation anchor
        }
    }
}

// MARK: - AR Experience ViewModel

final class ARExperienceViewModel: ObservableObject {
    @Published var currentFPS: Float = 0
    @Published var memoryUsage: UInt64 = 0
    @Published var averageFrameTime: CFTimeInterval = 0
    @Published var ctaLinks: [ARCodeCTALink] = []
    
    private var arView: ARSCNView?
    private let renderingPipeline: ARRenderingPipelineProtocol
    private let optimization: ARRenderingOptimizationProtocol
    private let gestureManager: ARGestureManagerProtocol
    private let performanceMonitor: ARPerformanceMonitorProtocol
    private let ctaLinkService: CTALinkServiceProtocol
    private let abTestingService: ABTestingServiceProtocol
    private let arCodeId: String?
    
    init(
        renderingPipeline: ARRenderingPipelineProtocol,
        optimization: ARRenderingOptimizationProtocol,
        gestureManager: ARGestureManagerProtocol,
        performanceMonitor: ARPerformanceMonitorProtocol,
        ctaLinkService: CTALinkServiceProtocol,
        abTestingService: ABTestingServiceProtocol,
        arCodeId: String? = nil
    ) {
        self.renderingPipeline = renderingPipeline
        self.optimization = optimization
        self.gestureManager = gestureManager
        self.performanceMonitor = performanceMonitor
        self.ctaLinkService = ctaLinkService
        self.abTestingService = abTestingService
        self.arCodeId = arCodeId
        
        // Setup callbacks
        setupCallbacks()
        
        // Load CTA links
        loadCTALinks()
    }
    
    func setupARView(_ arView: ARSCNView?) {
        guard let arView = arView else { return }
        self.arView = arView
        
        // Setup rendering pipeline
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        renderingPipeline.setupPipeline(for: arView, configuration: configuration)
        
        // Setup optimization
        optimization.setupPostProcessing(for: arView)
        optimization.enableFXAA(enabled: true)
        optimization.enableBloom(enabled: true, intensity: 0.2)
        optimization.applyToneMapping(enabled: true)
        
        if let scene = arView.scene {
            optimization.setupReflectionProbes(in: scene)
            optimization.updateShadowQuality(quality: .medium)
        }
        
        // Setup gestures
        if let scene = arView.scene {
            gestureManager.setupGestures(for: arView, scene: scene)
        }
        
        // Setup performance monitoring
        if let monitor = performanceMonitor as? ARPerformanceMonitor {
            monitor.arView = arView
            monitor.startMonitoring()
        }
    }
    
    func updateFrame(_ frame: ARFrame) {
        guard let scene = arView?.scene else { return }
        renderingPipeline.updatePipeline(frame: frame, scene: scene)
        
        // Update metrics
        currentFPS = renderingPipeline.getCurrentFPS()
        averageFrameTime = renderingPipeline.getAverageFrameTime()
        
        if let monitor = performanceMonitor as? ARPerformanceMonitor {
            let metrics = monitor.getCurrentMetrics()
            memoryUsage = metrics.memoryUsage
        }
    }
    
    func handleAnchorsAdded(_ anchors: [ARAnchor]) {
        if let planeAnchors = anchors as? [ARPlaneAnchor] {
            renderingPipeline.handlePlaneUpdates(planeAnchors)
        }
    }
    
    func handleAnchorsUpdated(_ anchors: [ARAnchor]) {
        if let planeAnchors = anchors as? [ARPlaneAnchor] {
            renderingPipeline.handlePlaneUpdates(planeAnchors)
        }
    }
    
    private func setupCallbacks() {
        gestureManager.onNodeSelected = { [weak self] node in
            // Node sélectionné
            DispatchQueue.main.async {
                // Mettre à jour UI si nécessaire
            }
        }
        
        if let monitor = performanceMonitor as? ARPerformanceMonitor {
            monitor.onPerformanceWarning = { [weak self] warning in
                DispatchQueue.main.async {
                    switch warning {
                    case .lowFPS(let actual, let target):
                        print("⚠️ Performance Warning: Low FPS (\(actual)/\(target))")
                    case .highMemory(let used, let limit):
                        print("⚠️ Performance Warning: High Memory (\(used)/\(limit))")
                    case .highLatency(let ms):
                        print("⚠️ Performance Warning: High Latency (\(ms)ms)")
                    }
                }
            }
        }
    }
    
    func cleanup() {
        if let monitor = performanceMonitor as? ARPerformanceMonitor {
            monitor.stopMonitoring()
        }
        gestureManager.detachFromNode()
        arView = nil
    }
    
    // MARK: - CTA Links
    
    private func loadCTALinks() {
        guard let arCodeId = arCodeId else { return }
        
        ctaLinkService.getCTALinks(for: arCodeId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let links):
                    // Appliquer A/B testing si disponible
                    self?.applyABTesting(links: links)
                case .failure:
                    // CTA links optionnels, continuer sans
                    break
                }
            }
        }
    }
    
    private func applyABTesting(links: [ARCodeCTALink]) {
        guard let arCodeId = arCodeId else {
            self.ctaLinks = links.filter { $0.isEnabled }
            return
        }
        
        abTestingService.getABTest(for: arCodeId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let abTest):
                    if let test = abTest, test.isActive {
                        // Sélectionner variant
                        if let variant = self?.abTestingService.selectVariant(for: test.id, userId: nil) {
                            // Appliquer variant aux links
                            var updatedLinks = links
                            for (index, link) in updatedLinks.enumerated() {
                                if link.analyticsId == test.id {
                                    updatedLinks[index].buttonText = variant.buttonText
                                    updatedLinks[index].buttonStyle = variant.buttonStyle
                                    updatedLinks[index].position = variant.position
                                    updatedLinks[index].variant = variant.variantName
                                }
                            }
                            self?.ctaLinks = updatedLinks.filter { $0.isEnabled }
                        } else {
                            self?.ctaLinks = links.filter { $0.isEnabled }
                        }
                    } else {
                        self?.ctaLinks = links.filter { $0.isEnabled }
                    }
                case .failure:
                    self?.ctaLinks = links.filter { $0.isEnabled }
                }
            }
        }
    }
    
    func handleCTATap(_ link: ARCodeCTALink) {
        // Track click
        ctaLinkService.trackCTAClick(linkId: link.id, variant: link.variant) { _ in }
        
        // Handle redirection
        let success = ctaLinkService.handleCTARedirection(
            url: link.destinationURL,
            destinationType: link.destinationType
        )
        
        if !success {
            print("⚠️ Failed to redirect CTA link: \(link.id)")
        }
        
        // Track conversion if A/B test
        if let variant = link.variant {
            abTestingService.trackConversion(variantId: variant) { _ in }
        }
    }
}

