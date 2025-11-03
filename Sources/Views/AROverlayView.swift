//
//  AROverlayView.swift
//  ARCodeClone
//
//  Overlay UI pour AR view: close, screenshot, share, reset, scale, distance
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct AROverlayView: View {
    @Binding var arView: ARSCNView?
    @Binding var showARView: Bool
    @State private var currentScale: Float = 1.0
    @State private var distanceToObject: Float = 0.0
    @State private var showShareSheet: Bool = false
    @State private var screenshotImage: UIImage?
    @State private var showScaleIndicator: Bool = true
    @State private var showDistanceMeasurement: Bool = false
    
    let selectedNode: SCNNode?
    let ctaLinks: [ARCodeCTALink]
    let onCTATap: (ARCodeCTALink) -> Void
    
    var body: some View {
        ZStack {
            // Top controls
            VStack {
                HStack {
                    // Close button
                    Button(action: {
                        showARView = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Screenshot button
                    Button(action: {
                        takeScreenshot()
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Share button
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // CTA Links Overlay
                if !ctaLinks.isEmpty {
                    ARCTALinkOverlay(ctaLinks: ctaLinks, onCTATap: onCTATap)
                }
                
                // Bottom controls
                VStack(spacing: 16) {
                    // Reset placement button
                    Button(action: {
                        resetPlacement()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(ARTypography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(25)
                    }
                    
                    // Scale indicator
                    if showScaleIndicator, let node = selectedNode {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.and.down")
                            Text("Scale: \(String(format: "%.2fx", currentScale))")
                        }
                        .font(ARTypography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                        .onAppear {
                            updateScaleIndicator(node: node)
                        }
                    }
                    
                    // Distance measurement
                    if showDistanceMeasurement, let node = selectedNode {
                        HStack(spacing: 8) {
                            Image(systemName: "ruler")
                            Text("Distance: \(String(format: "%.2f", distanceToObject))m")
                        }
                        .font(ARTypography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = screenshotImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            startMonitoringNode()
        }
    }
    
    // MARK: - Actions
    
    private func takeScreenshot() {
        guard let arView = arView else { return }
        
        // Capturer snapshot
        let image = arView.snapshot()
        screenshotImage = image
        
        // Sauvegarder dans Photos
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Feedback haptique
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Feedback visuel
        showShareSheet = true
    }
    
    private func resetPlacement() {
        guard let node = selectedNode else { return }
        
        // Reset position et rotation
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        node.position = SCNVector3(0, 0, -1) // Devant la caméra
        node.eulerAngles = SCNVector3(0, 0, 0)
        node.scale = SCNVector3(1, 1, 1)
        SCNTransaction.commit()
        
        currentScale = 1.0
        updateScaleIndicator(node: node)
        
        // Feedback haptique
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func updateScaleIndicator(node: SCNNode) {
        currentScale = node.scale.x // Assume uniform scale
    }
    
    private func startMonitoringNode() {
        // Timer pour mettre à jour scale et distance
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let node = selectedNode,
                  let arView = arView,
                  let camera = arView.pointOfView else { return }
            
            // Update scale
            updateScaleIndicator(node: node)
            
            // Calculate distance
            let nodePos = node.position
            let cameraPos = camera.position
            let dx = nodePos.x - cameraPos.x
            let dy = nodePos.y - cameraPos.y
            let dz = nodePos.z - cameraPos.z
            distanceToObject = sqrt(dx*dx + dy*dy + dz*dz)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

