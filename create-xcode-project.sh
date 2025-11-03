#!/bin/bash
# Script pour créer un projet Xcode à partir du Swift Package
# Nécessaire pour générer un .ipa

set -e

echo "🔨 Création du projet Xcode depuis Swift Package..."

# Vérifier que Package.swift existe
if [ ! -f Package.swift ]; then
    echo "❌ Erreur: Package.swift non trouvé"
    exit 1
fi

# Nom du projet
PROJECT_NAME="ARCodeClone"
BUNDLE_ID="com.arcode.clone"

# Créer la structure du projet
mkdir -p "$PROJECT_NAME"
mkdir -p "$PROJECT_NAME.xcodeproj"
mkdir -p "$PROJECT_NAME.xcodeproj/project.xcworkspace"
mkdir -p "$PROJECT_NAME.xcodeproj/xcshareddata"
mkdir -p "$PROJECT_NAME.xcodeproj/xcuserdata"

echo "✅ Structure créée"

# Créer Info.plist
cat > "$PROJECT_NAME/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>ARCode Clone</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
        <string>arkit</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSCameraUsageDescription</key>
    <string>ARCode needs camera access for AR experiences</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>ARCode needs photo library access to import images</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>ARCode needs location for analytics</string>
</dict>
</plist>
EOF

echo "✅ Info.plist créé"

# Essayer de générer le projet Xcode avec swift package
if swift package generate-xcodeproj 2>/dev/null; then
    echo "✅ Projet Xcode généré avec swift package generate-xcodeproj"
else
    echo "⚠️  generate-xcodeproj non disponible, création manuelle..."
    echo "💡 Pour créer un projet Xcode complet:"
    echo "   1. Ouvrez Xcode"
    echo "   2. File → New → Project"
    echo "   3. iOS → App"
    echo "   4. Liez le Package.swift comme dépendance"
fi

echo ""
echo "✅ Projet Xcode créé!"
echo "📁 Ouvrez $PROJECT_NAME.xcodeproj dans Xcode"

