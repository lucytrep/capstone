import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "desert-dreams-1" asset catalog image resource.
    static let desertDreams1 = DeveloperToolsSupport.ImageResource(name: "desert-dreams-1", bundle: resourceBundle)

    /// The "desert-dreams-2" asset catalog image resource.
    static let desertDreams2 = DeveloperToolsSupport.ImageResource(name: "desert-dreams-2", bundle: resourceBundle)

    /// The "desert-dreams-3" asset catalog image resource.
    static let desertDreams3 = DeveloperToolsSupport.ImageResource(name: "desert-dreams-3", bundle: resourceBundle)

    /// The "desert-dreams-4" asset catalog image resource.
    static let desertDreams4 = DeveloperToolsSupport.ImageResource(name: "desert-dreams-4", bundle: resourceBundle)

    /// The "desert-dreams-5" asset catalog image resource.
    static let desertDreams5 = DeveloperToolsSupport.ImageResource(name: "desert-dreams-5", bundle: resourceBundle)

    /// The "nike-editorial-1" asset catalog image resource.
    static let nikeEditorial1 = DeveloperToolsSupport.ImageResource(name: "nike-editorial-1", bundle: resourceBundle)

    /// The "nike-editorial-2" asset catalog image resource.
    static let nikeEditorial2 = DeveloperToolsSupport.ImageResource(name: "nike-editorial-2", bundle: resourceBundle)

    /// The "nike-editorial-3" asset catalog image resource.
    static let nikeEditorial3 = DeveloperToolsSupport.ImageResource(name: "nike-editorial-3", bundle: resourceBundle)

    /// The "nike-editorial-4" asset catalog image resource.
    static let nikeEditorial4 = DeveloperToolsSupport.ImageResource(name: "nike-editorial-4", bundle: resourceBundle)

    /// The "nike-editorial-5" asset catalog image resource.
    static let nikeEditorial5 = DeveloperToolsSupport.ImageResource(name: "nike-editorial-5", bundle: resourceBundle)

    /// The "open-court-1" asset catalog image resource.
    static let openCourt1 = DeveloperToolsSupport.ImageResource(name: "open-court-1", bundle: resourceBundle)

    /// The "open-court-2" asset catalog image resource.
    static let openCourt2 = DeveloperToolsSupport.ImageResource(name: "open-court-2", bundle: resourceBundle)

    /// The "open-court-3" asset catalog image resource.
    static let openCourt3 = DeveloperToolsSupport.ImageResource(name: "open-court-3", bundle: resourceBundle)

    /// The "open-court-4" asset catalog image resource.
    static let openCourt4 = DeveloperToolsSupport.ImageResource(name: "open-court-4", bundle: resourceBundle)

    /// The "open-court-5" asset catalog image resource.
    static let openCourt5 = DeveloperToolsSupport.ImageResource(name: "open-court-5", bundle: resourceBundle)

    /// The "open-court-6" asset catalog image resource.
    static let openCourt6 = DeveloperToolsSupport.ImageResource(name: "open-court-6", bundle: resourceBundle)

    /// The "open-court-7" asset catalog image resource.
    static let openCourt7 = DeveloperToolsSupport.ImageResource(name: "open-court-7", bundle: resourceBundle)

    /// The "open-court-8" asset catalog image resource.
    static let openCourt8 = DeveloperToolsSupport.ImageResource(name: "open-court-8", bundle: resourceBundle)

    /// The "recipe-app-concept-1" asset catalog image resource.
    static let recipeAppConcept1 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-1", bundle: resourceBundle)

    /// The "recipe-app-concept-2" asset catalog image resource.
    static let recipeAppConcept2 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-2", bundle: resourceBundle)

    /// The "recipe-app-concept-3" asset catalog image resource.
    static let recipeAppConcept3 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-3", bundle: resourceBundle)

    /// The "recipe-app-concept-4" asset catalog image resource.
    static let recipeAppConcept4 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-4", bundle: resourceBundle)

    /// The "soft-spatial-ui-1" asset catalog image resource.
    static let softSpatialUi1 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-1", bundle: resourceBundle)

    /// The "soft-spatial-ui-2" asset catalog image resource.
    static let softSpatialUi2 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-2", bundle: resourceBundle)

    /// The "soft-spatial-ui-3" asset catalog image resource.
    static let softSpatialUi3 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-3", bundle: resourceBundle)

    /// The "soft-spatial-ui-4" asset catalog image resource.
    static let softSpatialUi4 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-4", bundle: resourceBundle)

}

