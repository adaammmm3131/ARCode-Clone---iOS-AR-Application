//
//  ARTextColorService.swift
//  ARCodeClone
//
//  Service pour sélection couleurs RGB et conversion
//

import Foundation
import SwiftUI
import UIKit

protocol ARTextColorServiceProtocol {
    func colorFromRGB(r: Double, g: Double, b: Double, alpha: Double) -> UIColor
    func colorToRGB(_ color: UIColor) -> (r: Double, g: Double, b: Double, alpha: Double)
    func getPresetColors() -> [PresetColor]
}

struct PresetColor {
    let name: String
    let color: UIColor
    let rgb: (r: Double, g: Double, b: Double)
}

final class ARTextColorService: ARTextColorServiceProtocol {
    
    // MARK: - RGB Conversion
    
    func colorFromRGB(r: Double, g: Double, b: Double, alpha: Double = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat(r),
            green: CGFloat(g),
            blue: CGFloat(b),
            alpha: CGFloat(alpha)
        )
    }
    
    func colorToRGB(_ color: UIColor) -> (r: Double, g: Double, b: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (r: Double(red), g: Double(green), b: Double(blue), alpha: Double(alpha))
    }
    
    // MARK: - Preset Colors
    
    func getPresetColors() -> [PresetColor] {
        return [
            PresetColor(name: "Rouge", color: .red, rgb: (1.0, 0.0, 0.0)),
            PresetColor(name: "Vert", color: .green, rgb: (0.0, 1.0, 0.0)),
            PresetColor(name: "Bleu", color: .blue, rgb: (0.0, 0.0, 1.0)),
            PresetColor(name: "Noir", color: .black, rgb: (0.0, 0.0, 0.0)),
            PresetColor(name: "Blanc", color: .white, rgb: (1.0, 1.0, 1.0)),
            PresetColor(name: "Jaune", color: .yellow, rgb: (1.0, 1.0, 0.0)),
            PresetColor(name: "Orange", color: .orange, rgb: (1.0, 0.5, 0.0)),
            PresetColor(name: "Violet", color: .purple, rgb: (0.5, 0.0, 0.5)),
            PresetColor(name: "Rose", color: .systemPink, rgb: (1.0, 0.0, 0.5)),
            PresetColor(name: "Cyan", color: .cyan, rgb: (0.0, 1.0, 1.0)),
            PresetColor(name: "Gris", color: .gray, rgb: (0.5, 0.5, 0.5)),
            PresetColor(name: "Doré", color: UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0), rgb: (0.83, 0.69, 0.22)),
            PresetColor(name: "Argenté", color: UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0), rgb: (0.75, 0.75, 0.75)),
        ]
    }
}










