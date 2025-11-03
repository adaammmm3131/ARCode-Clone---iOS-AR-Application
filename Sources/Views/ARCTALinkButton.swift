//
//  ARCTALinkButton.swift
//  ARCodeClone
//
//  Bouton CTA dans expérience AR
//

import SwiftUI
import ARKit
import SceneKit

struct ARCTALinkButton: View {
    let ctaLink: ARCodeCTALink
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if ctaLink.buttonStyle == .icon {
                    Image(systemName: getIconForDestination(ctaLink.destinationType))
                        .font(.system(size: 20))
                } else {
                    Text(ctaLink.buttonText)
                        .font(.headline)
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Styling
    
    private var backgroundColor: Color {
        switch ctaLink.buttonStyle {
        case .primary:
            return Color(red: 0.42, green: 0.36, blue: 0.91) // #6C5CE7
        case .secondary:
            return Color(red: 0.0, green: 0.72, blue: 0.58) // #00B894
        case .outline:
            return Color.clear
        case .text, .icon:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch ctaLink.buttonStyle {
        case .primary, .secondary:
            return .white
        case .outline, .text, .icon:
            return Color(red: 0.42, green: 0.36, blue: 0.91) // #6C5CE7
        }
    }
    
    private var borderColor: Color {
        switch ctaLink.buttonStyle {
        case .outline:
            return Color(red: 0.42, green: 0.36, blue: 0.91) // #6C5CE7
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        return ctaLink.buttonStyle == .outline ? 2 : 0
    }
    
    private var cornerRadius: CGFloat {
        return 12
    }
    
    private var shadowColor: Color {
        return Color.black.opacity(0.2)
    }
    
    private func getIconForDestination(_ type: CTADestinationType) -> String {
        switch type {
        case .productPage:
            return "cart.fill"
        case .landingPage:
            return "arrow.right.circle.fill"
        case .appDownload:
            return "arrow.down.circle.fill"
        case .socialMedia:
            return "person.2.fill"
        case .website:
            return "safari.fill"
        case .deepLink:
            return "link.circle.fill"
        case .email:
            return "envelope.fill"
        case .phone:
            return "phone.fill"
        }
    }
}

// MARK: - AR Overlay avec CTA

struct ARCTALinkOverlay: View {
    let ctaLinks: [ARCodeCTALink]
    let onCTATap: (ARCodeCTALink) -> Void
    
    var body: some View {
        VStack {
            // Top CTAs
            HStack {
                if let topLeft = ctaLinks.first(where: { $0.position == .topLeft }) {
                    ARCTALinkButton(ctaLink: topLeft) {
                        onCTATap(topLeft)
                    }
                }
                
                Spacer()
                
                if let topRight = ctaLinks.first(where: { $0.position == .topRight }) {
                    ARCTALinkButton(ctaLink: topRight) {
                        onCTATap(topRight)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // Center CTA (floating)
            if let centerCTA = ctaLinks.first(where: { $0.position == .center || $0.position == .floating }) {
                ARCTALinkButton(ctaLink: centerCTA) {
                    onCTATap(centerCTA)
                }
                .padding(.bottom, 100)
            }
            
            // Bottom CTAs
            HStack {
                if let bottomLeft = ctaLinks.first(where: { $0.position == .bottomLeft }) {
                    ARCTALinkButton(ctaLink: bottomLeft) {
                        onCTATap(bottomLeft)
                    }
                }
                
                Spacer()
                
                if let bottomCenter = ctaLinks.first(where: { $0.position == .bottomCenter }) {
                    ARCTALinkButton(ctaLink: bottomCenter) {
                        onCTATap(bottomCenter)
                    }
                }
                
                Spacer()
                
                if let bottomRight = ctaLinks.first(where: { $0.position == .bottomRight }) {
                    ARCTALinkButton(ctaLink: bottomRight) {
                        onCTATap(bottomRight)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}







