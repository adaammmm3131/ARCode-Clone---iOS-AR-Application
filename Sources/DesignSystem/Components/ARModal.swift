//
//  ARModal.swift
//  ARCodeClone
//
//  Composant modal réutilisable du design system
//

import SwiftUI

/// Modal réutilisable AR Code
struct ARModal<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String?
    let content: Content
    let dismissAction: (() -> Void)?
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        dismissAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .opacity(opacity)
                .onTapGesture {
                    dismiss()
                }
            
            // Modal Content
            VStack(spacing: 0) {
                // Header
                if let title = title {
                    HStack {
                        Text(title)
                            .font(ARTypography.titleLarge)
                            .foregroundColor(ARColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(ARColors.textSecondary)
                        }
                    }
                    .padding(20)
                }
                
                // Content
                content
                    .padding(title != nil ? [.horizontal, .bottom] : .all, 20)
            }
            .background(ARColors.surface)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(20)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: isPresented) { newValue in
            if !newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scale = 0.8
                    opacity = 0.0
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            dismissAction?()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Affiche une modal AR Code
    func arModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        dismissAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                ARModal(
                    isPresented: isPresented,
                    title: title,
                    dismissAction: dismissAction,
                    content: content
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showModal = false
        
        var body: some View {
            VStack {
                ARButton("Show Modal") {
                    showModal = true
                }
            }
            .arModal(isPresented: $showModal, title: "Modal Title") {
                VStack(spacing: 16) {
                    Text("Modal content goes here")
                        .font(ARTypography.bodyMedium)
                    
                    ARButton("Close", style: .primary) {
                        showModal = false
                    }
                }
            }
        }
    }
    
    return PreviewWrapper()
}









