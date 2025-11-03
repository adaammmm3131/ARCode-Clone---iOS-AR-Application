//
//  PromptGeneratorService.swift
//  ARCodeClone
//
//  Service pour génération de prompts optimisés avec templates multi-langue
//

import Foundation

protocol PromptGeneratorServiceProtocol {
    func generatePrompt(
        template: PromptTemplate,
        parameters: [String: String],
        language: String
    ) -> String
    
    func optimizePrompt(_ prompt: String, for task: PromptTask) -> String
    
    func getAvailableTemplates() -> [PromptTemplate]
}

enum PromptTemplate: String, CaseIterable {
    case virtualTryOn = "virtual_try_on"
    case productPlacement = "product_placement"
    case styleTransfer = "style_transfer"
    case textToImage = "text_to_image"
    case imageEnhancement = "image_enhancement"
    case backgroundReplacement = "background_replacement"
    
    var displayName: String {
        switch self {
        case .virtualTryOn: return "Virtual Try-On"
        case .productPlacement: return "Product Placement"
        case .styleTransfer: return "Style Transfer"
        case .textToImage: return "Text to Image"
        case .imageEnhancement: return "Image Enhancement"
        case .backgroundReplacement: return "Background Replacement"
        }
    }
}

enum PromptTask {
    case generation
    case inpainting
    case img2img
    case txt2img
}

struct PromptTemplateDefinition {
    let id: String
    let basePrompt: String
    let parameters: [String]
    let negativePrompt: String
    let optimizationHints: [String]
}

final class PromptGeneratorService: PromptGeneratorServiceProtocol {
    
    private let templates: [PromptTemplate: PromptTemplateDefinition]
    
    init() {
        // Initialiser templates
        self.templates = Self.loadTemplates()
    }
    
    // MARK: - Prompt Generation
    
    func generatePrompt(
        template: PromptTemplate,
        parameters: [String: String],
        language: String = "en"
    ) -> String {
        guard let templateDef = templates[template] else {
            return parameters.values.joined(separator: ", ")
        }
        
        var prompt = templateDef.basePrompt
        
        // Remplacer paramètres
        for (key, value) in parameters {
            prompt = prompt.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        // Traduire si nécessaire
        if language != "en" {
            prompt = translatePrompt(prompt, to: language)
        }
        
        return prompt
    }
    
    // MARK: - Prompt Optimization
    
    func optimizePrompt(_ prompt: String, for task: PromptTask) -> String {
        var optimized = prompt
        
        // Ajouter qualifiers selon task
        switch task {
        case .generation, .txt2img:
            optimized = addQualityModifiers(optimized)
        case .inpainting:
            optimized = addInpaintingModifiers(optimized)
        case .img2img:
            optimized = addImg2ImgModifiers(optimized)
        }
        
        // Optimiser longueur
        optimized = optimizeLength(optimized)
        
        return optimized
    }
    
    // MARK: - Templates
    
    func getAvailableTemplates() -> [PromptTemplate] {
        return PromptTemplate.allCases
    }
    
    // MARK: - Helper Methods
    
    private static func loadTemplates() -> [PromptTemplate: PromptTemplateDefinition] {
        var templates: [PromptTemplate: PromptTemplateDefinition] = [:]
        
        // Template Virtual Try-On
        templates[.virtualTryOn] = PromptTemplateDefinition(
            id: "virtual_try_on",
            basePrompt: "photorealistic virtual try-on, {clothing_type} on person, perfect fit, natural lighting, high quality, detailed textures, realistic fabric, seamless integration, professional photography, 8k, ultra detailed",
            parameters: ["clothing_type"],
            negativePrompt: "blurry, distorted, artifacts, low quality, unrealistic, fake, cartoon, anime",
            optimizationHints: ["Specify clothing type", "Include fit details", "Mention lighting conditions"]
        )
        
        // Template Product Placement
        templates[.productPlacement] = PromptTemplateDefinition(
            id: "product_placement",
            basePrompt: "{product_name} placed on {surface}, professional product photography, studio lighting, white background, high quality, sharp focus, commercial photography, product showcase",
            parameters: ["product_name", "surface"],
            negativePrompt: "blurry, cluttered background, poor lighting, low quality",
            optimizationHints: ["Specify product and surface", "Mention lighting style"]
        )
        
        // Template Style Transfer
        templates[.styleTransfer] = PromptTemplateDefinition(
            id: "style_transfer",
            basePrompt: "{subject} in the style of {art_style}, {style_details}, high quality artwork, detailed, artistic composition",
            parameters: ["subject", "art_style", "style_details"],
            negativePrompt: "low quality, distorted, blurry",
            optimizationHints: ["Specify subject and art style", "Add style details"]
        )
        
        // Template Text to Image
        templates[.textToImage] = PromptTemplateDefinition(
            id: "text_to_image",
            basePrompt: "{description}, {quality_modifiers}, {style_modifiers}, {lighting_modifiers}, high quality, detailed",
            parameters: ["description", "quality_modifiers", "style_modifiers", "lighting_modifiers"],
            negativePrompt: "low quality, blurry, distorted, artifacts",
            optimizationHints: ["Be specific in description", "Add quality and style modifiers"]
        )
        
        // Template Image Enhancement
        templates[.imageEnhancement] = PromptTemplateDefinition(
            id: "image_enhancement",
            basePrompt: "enhance image quality, improve sharpness, enhance colors, {enhancement_type}, professional retouching, high quality output",
            parameters: ["enhancement_type"],
            negativePrompt: "oversaturated, overprocessed, artifacts",
            optimizationHints: ["Specify enhancement type", "Maintain natural look"]
        )
        
        // Template Background Replacement
        templates[.backgroundReplacement] = PromptTemplateDefinition(
            id: "background_replacement",
            basePrompt: "{subject} with {background_description}, seamless background replacement, natural lighting match, professional composite, realistic integration",
            parameters: ["subject", "background_description"],
            negativePrompt: "obvious cutout, harsh edges, lighting mismatch, unrealistic",
            optimizationHints: ["Describe subject and new background", "Match lighting conditions"]
        )
        
        return templates
    }
    
    private func translatePrompt(_ prompt: String, to language: String) -> String {
        // Traduction basique (en production, utiliser API traduction)
        // Support 27+ langues: EN, FR, ES, DE, IT, PT, RU, ZH, JA, KO, AR, NL, PL, TR, etc.
        
        // Pour l'instant, retourner prompt original
        // TODO: Implémenter traduction avec service de traduction
        return prompt
    }
    
    private func addQualityModifiers(_ prompt: String) -> String {
        var modifiers = ["8k", "ultra detailed", "high quality", "sharp focus", "professional"]
        
        // Ajouter seulement si pas déjà présents
        var optimized = prompt
        for modifier in modifiers {
            if !optimized.lowercased().contains(modifier.lowercased()) {
                optimized += ", \(modifier)"
            }
        }
        
        return optimized
    }
    
    private func addInpaintingModifiers(_ prompt: String) -> String {
        let modifiers = "seamless integration, perfect blend, natural transition"
        if !prompt.lowercased().contains("seamless") {
            return "\(prompt), \(modifiers)"
        }
        return prompt
    }
    
    private func addImg2ImgModifiers(_ prompt: String) -> String {
        let modifiers = "preserve original composition, maintain aspect ratio"
        return "\(prompt), \(modifiers)"
    }
    
    private func optimizeLength(_ prompt: String) -> String {
        // Optimiser longueur prompt (trop long peut dégrader qualité)
        // Stable Diffusion performe mieux avec prompts de 50-150 tokens
        let words = prompt.components(separatedBy: .whitespaces)
        if words.count > 150 {
            // Garder les mots les plus importants
            return words.prefix(150).joined(separator: " ")
        }
        return prompt
    }
}

// MARK: - Multi-language Support

extension PromptGeneratorService {
    /// Langues supportées (27+)
    static let supportedLanguages: [String] = [
        "en", "fr", "es", "de", "it", "pt", "ru", "zh", "ja", "ko",
        "ar", "nl", "pl", "tr", "sv", "da", "fi", "no", "cs", "hu",
        "ro", "el", "he", "hi", "th", "vi", "id", "ms"
    ]
    
    func generatePromptMultiLanguage(
        template: PromptTemplate,
        parameters: [String: String],
        languages: [String]
    ) -> [String: String] {
        var results: [String: String] = [:]
        for language in languages {
            results[language] = generatePrompt(
                template: template,
                parameters: parameters,
                language: language
            )
        }
        return results
    }
}










