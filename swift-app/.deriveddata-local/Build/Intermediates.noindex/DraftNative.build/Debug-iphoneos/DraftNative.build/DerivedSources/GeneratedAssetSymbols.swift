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

    /// The "color_apricot_wash" asset catalog image resource.
    static let colorApricotWash = DeveloperToolsSupport.ImageResource(name: "color_apricot_wash", bundle: resourceBundle)

    /// The "color_aqua_wash" asset catalog image resource.
    static let colorAquaWash = DeveloperToolsSupport.ImageResource(name: "color_aqua_wash", bundle: resourceBundle)

    /// The "color_butter_cream" asset catalog image resource.
    static let colorButterCream = DeveloperToolsSupport.ImageResource(name: "color_butter_cream", bundle: resourceBundle)

    /// The "color_citrus_lime" asset catalog image resource.
    static let colorCitrusLime = DeveloperToolsSupport.ImageResource(name: "color_citrus_lime", bundle: resourceBundle)

    /// The "color_cobalt_pop" asset catalog image resource.
    static let colorCobaltPop = DeveloperToolsSupport.ImageResource(name: "color_cobalt_pop", bundle: resourceBundle)

    /// The "color_cream_mist" asset catalog image resource.
    static let colorCreamMist = DeveloperToolsSupport.ImageResource(name: "color_cream_mist", bundle: resourceBundle)

    /// The "color_electric_yellow" asset catalog image resource.
    static let colorElectricYellow = DeveloperToolsSupport.ImageResource(name: "color_electric_yellow", bundle: resourceBundle)

    /// The "color_fuchsia_pop" asset catalog image resource.
    static let colorFuchsiaPop = DeveloperToolsSupport.ImageResource(name: "color_fuchsia_pop", bundle: resourceBundle)

    /// The "color_hot_pink_haze" asset catalog image resource.
    static let colorHotPinkHaze = DeveloperToolsSupport.ImageResource(name: "color_hot_pink_haze", bundle: resourceBundle)

    /// The "color_lavender_mist" asset catalog image resource.
    static let colorLavenderMist = DeveloperToolsSupport.ImageResource(name: "color_lavender_mist", bundle: resourceBundle)

    /// The "color_magenta_beam" asset catalog image resource.
    static let colorMagentaBeam = DeveloperToolsSupport.ImageResource(name: "color_magenta_beam", bundle: resourceBundle)

    /// The "color_melon_orange" asset catalog image resource.
    static let colorMelonOrange = DeveloperToolsSupport.ImageResource(name: "color_melon_orange", bundle: resourceBundle)

    /// The "color_mulberry_bloom" asset catalog image resource.
    static let colorMulberryBloom = DeveloperToolsSupport.ImageResource(name: "color_mulberry_bloom", bundle: resourceBundle)

    /// The "color_pale_butter" asset catalog image resource.
    static let colorPaleButter = DeveloperToolsSupport.ImageResource(name: "color_pale_butter", bundle: resourceBundle)

    /// The "color_powder_blush" asset catalog image resource.
    static let colorPowderBlush = DeveloperToolsSupport.ImageResource(name: "color_powder_blush", bundle: resourceBundle)

    /// The "color_punch_red" asset catalog image resource.
    static let colorPunchRed = DeveloperToolsSupport.ImageResource(name: "color_punch_red", bundle: resourceBundle)

    /// The "color_rose_pink" asset catalog image resource.
    static let colorRosePink = DeveloperToolsSupport.ImageResource(name: "color_rose_pink", bundle: resourceBundle)

    /// The "color_soft_vanilla" asset catalog image resource.
    static let colorSoftVanilla = DeveloperToolsSupport.ImageResource(name: "color_soft_vanilla", bundle: resourceBundle)

    /// The "color_teal_pool" asset catalog image resource.
    static let colorTealPool = DeveloperToolsSupport.ImageResource(name: "color_teal_pool", bundle: resourceBundle)

    /// The "color_ultramarine_blur" asset catalog image resource.
    static let colorUltramarineBlur = DeveloperToolsSupport.ImageResource(name: "color_ultramarine_blur", bundle: resourceBundle)

    /// The "color_yellow_glow" asset catalog image resource.
    static let colorYellowGlow = DeveloperToolsSupport.ImageResource(name: "color_yellow_glow", bundle: resourceBundle)

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

    /// The "dir3-athletic" asset catalog image resource.
    static let dir3Athletic = DeveloperToolsSupport.ImageResource(name: "dir3-athletic", bundle: resourceBundle)

    /// The "dir3-track" asset catalog image resource.
    static let dir3Track = DeveloperToolsSupport.ImageResource(name: "dir3-track", bundle: resourceBundle)

    /// The "home-arcmatrix" asset catalog image resource.
    static let homeArcmatrix = DeveloperToolsSupport.ImageResource(name: "home-arcmatrix", bundle: resourceBundle)

    /// The "home-athlete-red" asset catalog image resource.
    static let homeAthleteRed = DeveloperToolsSupport.ImageResource(name: "home-athlete-red", bundle: resourceBundle)

    /// The "home-aura-blue" asset catalog image resource.
    static let homeAuraBlue = DeveloperToolsSupport.ImageResource(name: "home-aura-blue", bundle: resourceBundle)

    /// The "home-aura-orange" asset catalog image resource.
    static let homeAuraOrange = DeveloperToolsSupport.ImageResource(name: "home-aura-orange", bundle: resourceBundle)

    /// The "home-ayarx-ui" asset catalog image resource.
    static let homeAyarxUi = DeveloperToolsSupport.ImageResource(name: "home-ayarx-ui", bundle: resourceBundle)

    /// The "home-blueberries" asset catalog image resource.
    static let homeBlueberries = DeveloperToolsSupport.ImageResource(name: "home-blueberries", bundle: resourceBundle)

    /// The "home-daffodil" asset catalog image resource.
    static let homeDaffodil = DeveloperToolsSupport.ImageResource(name: "home-daffodil", bundle: resourceBundle)

    /// The "home-desert-art" asset catalog image resource.
    static let homeDesertArt = DeveloperToolsSupport.ImageResource(name: "home-desert-art", bundle: resourceBundle)

    /// The "home-elasti-ui" asset catalog image resource.
    static let homeElastiUi = DeveloperToolsSupport.ImageResource(name: "home-elasti-ui", bundle: resourceBundle)

    /// The "home-grid-flower" asset catalog image resource.
    static let homeGridFlower = DeveloperToolsSupport.ImageResource(name: "home-grid-flower", bundle: resourceBundle)

    /// The "home-halftone" asset catalog image resource.
    static let homeHalftone = DeveloperToolsSupport.ImageResource(name: "home-halftone", bundle: resourceBundle)

    /// The "home-hat-collage" asset catalog image resource.
    static let homeHatCollage = DeveloperToolsSupport.ImageResource(name: "home-hat-collage", bundle: resourceBundle)

    /// The "home-jumping" asset catalog image resource.
    static let homeJumping = DeveloperToolsSupport.ImageResource(name: "home-jumping", bundle: resourceBundle)

    /// The "home-laughing" asset catalog image resource.
    static let homeLaughing = DeveloperToolsSupport.ImageResource(name: "home-laughing", bundle: resourceBundle)

    /// The "home-moma-eye" asset catalog image resource.
    static let homeMomaEye = DeveloperToolsSupport.ImageResource(name: "home-moma-eye", bundle: resourceBundle)

    /// The "home-neon-rays" asset catalog image resource.
    static let homeNeonRays = DeveloperToolsSupport.ImageResource(name: "home-neon-rays", bundle: resourceBundle)

    /// The "home-newspaper" asset catalog image resource.
    static let homeNewspaper = DeveloperToolsSupport.ImageResource(name: "home-newspaper", bundle: resourceBundle)

    /// The "home-nike-athlete" asset catalog image resource.
    static let homeNikeAthlete = DeveloperToolsSupport.ImageResource(name: "home-nike-athlete", bundle: resourceBundle)

    /// The "home-nike-rhythm" asset catalog image resource.
    static let homeNikeRhythm = DeveloperToolsSupport.ImageResource(name: "home-nike-rhythm", bundle: resourceBundle)

    /// The "home-orange-car" asset catalog image resource.
    static let homeOrangeCar = DeveloperToolsSupport.ImageResource(name: "home-orange-car", bundle: resourceBundle)

    /// The "home-orange-fit" asset catalog image resource.
    static let homeOrangeFit = DeveloperToolsSupport.ImageResource(name: "home-orange-fit", bundle: resourceBundle)

    /// The "home-pixelated" asset catalog image resource.
    static let homePixelated = DeveloperToolsSupport.ImageResource(name: "home-pixelated", bundle: resourceBundle)

    /// The "home-raspberries" asset catalog image resource.
    static let homeRaspberries = DeveloperToolsSupport.ImageResource(name: "home-raspberries", bundle: resourceBundle)

    /// The "home-running" asset catalog image resource.
    static let homeRunning = DeveloperToolsSupport.ImageResource(name: "home-running", bundle: resourceBundle)

    /// The "home-silhouettes" asset catalog image resource.
    static let homeSilhouettes = DeveloperToolsSupport.ImageResource(name: "home-silhouettes", bundle: resourceBundle)

    /// The "home-skyward" asset catalog image resource.
    static let homeSkyward = DeveloperToolsSupport.ImageResource(name: "home-skyward", bundle: resourceBundle)

    /// The "home-smiley-pool" asset catalog image resource.
    static let homeSmileyPool = DeveloperToolsSupport.ImageResource(name: "home-smiley-pool", bundle: resourceBundle)

    /// The "home-stadium" asset catalog image resource.
    static let homeStadium = DeveloperToolsSupport.ImageResource(name: "home-stadium", bundle: resourceBundle)

    /// The "home-surf-dots" asset catalog image resource.
    static let homeSurfDots = DeveloperToolsSupport.ImageResource(name: "home-surf-dots", bundle: resourceBundle)

    /// The "home-tulips" asset catalog image resource.
    static let homeTulips = DeveloperToolsSupport.ImageResource(name: "home-tulips", bundle: resourceBundle)

    /// The "home-whispers-ui" asset catalog image resource.
    static let homeWhispersUi = DeveloperToolsSupport.ImageResource(name: "home-whispers-ui", bundle: resourceBundle)

    /// The "home-woman" asset catalog image resource.
    static let homeWoman = DeveloperToolsSupport.ImageResource(name: "home-woman", bundle: resourceBundle)

    /// The "icon-profile" asset catalog image resource.
    static let iconProfile = DeveloperToolsSupport.ImageResource(name: "icon-profile", bundle: resourceBundle)

    /// The "icon-user" asset catalog image resource.
    static let iconUser = DeveloperToolsSupport.ImageResource(name: "icon-user", bundle: resourceBundle)

    /// The "image_bold_wordmark" asset catalog image resource.
    static let imageBoldWordmark = DeveloperToolsSupport.ImageResource(name: "image_bold_wordmark", bundle: resourceBundle)

    /// The "image_city_tote_crop" asset catalog image resource.
    static let imageCityToteCrop = DeveloperToolsSupport.ImageResource(name: "image_city_tote_crop", bundle: resourceBundle)

    /// The "image_city_tote_frame" asset catalog image resource.
    static let imageCityToteFrame = DeveloperToolsSupport.ImageResource(name: "image_city_tote_frame", bundle: resourceBundle)

    /// The "image_get_into_it_cover" asset catalog image resource.
    static let imageGetIntoItCover = DeveloperToolsSupport.ImageResource(name: "image_get_into_it_cover", bundle: resourceBundle)

    /// The "image_get_into_it_poster" asset catalog image resource.
    static let imageGetIntoItPoster = DeveloperToolsSupport.ImageResource(name: "image_get_into_it_poster", bundle: resourceBundle)

    /// The "image_headmark_portrait" asset catalog image resource.
    static let imageHeadmarkPortrait = DeveloperToolsSupport.ImageResource(name: "image_headmark_portrait", bundle: resourceBundle)

    /// The "image_lime_motion_crop" asset catalog image resource.
    static let imageLimeMotionCrop = DeveloperToolsSupport.ImageResource(name: "image_lime_motion_crop", bundle: resourceBundle)

    /// The "image_lime_motion_square" asset catalog image resource.
    static let imageLimeMotionSquare = DeveloperToolsSupport.ImageResource(name: "image_lime_motion_square", bundle: resourceBundle)

    /// The "image_outdoor_selfie" asset catalog image resource.
    static let imageOutdoorSelfie = DeveloperToolsSupport.ImageResource(name: "image_outdoor_selfie", bundle: resourceBundle)

    /// The "image_pinterest_bouquet_motion" asset catalog image resource.
    static let imagePinterestBouquetMotion = DeveloperToolsSupport.ImageResource(name: "image_pinterest_bouquet_motion", bundle: resourceBundle)

    /// The "image_pinterest_butterfly_meadow" asset catalog image resource.
    static let imagePinterestButterflyMeadow = DeveloperToolsSupport.ImageResource(name: "image_pinterest_butterfly_meadow", bundle: resourceBundle)

    /// The "image_pinterest_desert_dune_study" asset catalog image resource.
    static let imagePinterestDesertDuneStudy = DeveloperToolsSupport.ImageResource(name: "image_pinterest_desert_dune_study", bundle: resourceBundle)

    /// The "image_pinterest_dusk_lakeside" asset catalog image resource.
    static let imagePinterestDuskLakeside = DeveloperToolsSupport.ImageResource(name: "image_pinterest_dusk_lakeside", bundle: resourceBundle)

    /// The "image_pinterest_forest_contact_grid" asset catalog image resource.
    static let imagePinterestForestContactGrid = DeveloperToolsSupport.ImageResource(name: "image_pinterest_forest_contact_grid", bundle: resourceBundle)

    /// The "image_pinterest_lily_pond_blur" asset catalog image resource.
    static let imagePinterestLilyPondBlur = DeveloperToolsSupport.ImageResource(name: "image_pinterest_lily_pond_blur", bundle: resourceBundle)

    /// The "image_pinterest_night_meadow_runner" asset catalog image resource.
    static let imagePinterestNightMeadowRunner = DeveloperToolsSupport.ImageResource(name: "image_pinterest_night_meadow_runner", bundle: resourceBundle)

    /// The "image_pinterest_rolling_wildflower_hills" asset catalog image resource.
    static let imagePinterestRollingWildflowerHills = DeveloperToolsSupport.ImageResource(name: "image_pinterest_rolling_wildflower_hills", bundle: resourceBundle)

    /// The "image_pinterest_soft_blank_field" asset catalog image resource.
    static let imagePinterestSoftBlankField = DeveloperToolsSupport.ImageResource(name: "image_pinterest_soft_blank_field", bundle: resourceBundle)

    /// The "image_pinterest_wildflower_meadow" asset catalog image resource.
    static let imagePinterestWildflowerMeadow = DeveloperToolsSupport.ImageResource(name: "image_pinterest_wildflower_meadow", bundle: resourceBundle)

    /// The "image_pinterest_willow_light" asset catalog image resource.
    static let imagePinterestWillowLight = DeveloperToolsSupport.ImageResource(name: "image_pinterest_willow_light", bundle: resourceBundle)

    /// The "image_recipe_app_everything_orbit_motion" asset catalog image resource.
    static let imageRecipeAppEverythingOrbitMotion = DeveloperToolsSupport.ImageResource(name: "image_recipe_app_everything_orbit_motion", bundle: resourceBundle)

    /// The "image_wordmark_square" asset catalog image resource.
    static let imageWordmarkSquare = DeveloperToolsSupport.ImageResource(name: "image_wordmark_square", bundle: resourceBundle)

    /// The "logo-dmark" asset catalog image resource.
    static let logoDmark = DeveloperToolsSupport.ImageResource(name: "logo-dmark", bundle: resourceBundle)

    /// The "nav-library" asset catalog image resource.
    static let navLibrary = DeveloperToolsSupport.ImageResource(name: "nav-library", bundle: resourceBundle)

    /// The "nav-mic" asset catalog image resource.
    static let navMic = DeveloperToolsSupport.ImageResource(name: "nav-mic", bundle: resourceBundle)

    /// The "nav-soundwaves" asset catalog image resource.
    static let navSoundwaves = DeveloperToolsSupport.ImageResource(name: "nav-soundwaves", bundle: resourceBundle)

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

    /// The "recipe-app-concept-2" asset catalog image resource.
    static let recipeAppConcept2 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-2", bundle: resourceBundle)

    /// The "recipe-app-concept-3" asset catalog image resource.
    static let recipeAppConcept3 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-3", bundle: resourceBundle)

    /// The "recipe-app-concept-4" asset catalog image resource.
    static let recipeAppConcept4 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-4", bundle: resourceBundle)

    /// The "recipe-app-concept-5" asset catalog image resource.
    static let recipeAppConcept5 = DeveloperToolsSupport.ImageResource(name: "recipe-app-concept-5", bundle: resourceBundle)

    /// The "soft-spatial-ui-1" asset catalog image resource.
    static let softSpatialUi1 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-1", bundle: resourceBundle)

    /// The "soft-spatial-ui-2" asset catalog image resource.
    static let softSpatialUi2 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-2", bundle: resourceBundle)

    /// The "soft-spatial-ui-3" asset catalog image resource.
    static let softSpatialUi3 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-3", bundle: resourceBundle)

    /// The "soft-spatial-ui-4" asset catalog image resource.
    static let softSpatialUi4 = DeveloperToolsSupport.ImageResource(name: "soft-spatial-ui-4", bundle: resourceBundle)

    /// The "ui-glass-commerce-orbit" asset catalog image resource.
    static let uiGlassCommerceOrbit = DeveloperToolsSupport.ImageResource(name: "ui-glass-commerce-orbit", bundle: resourceBundle)

    /// The "ui-glass-home-tab" asset catalog image resource.
    static let uiGlassHomeTab = DeveloperToolsSupport.ImageResource(name: "ui-glass-home-tab", bundle: resourceBundle)

    /// The "ui-glass-message-composer" asset catalog image resource.
    static let uiGlassMessageComposer = DeveloperToolsSupport.ImageResource(name: "ui-glass-message-composer", bundle: resourceBundle)

    /// The "ui-glass-selector-rail" asset catalog image resource.
    static let uiGlassSelectorRail = DeveloperToolsSupport.ImageResource(name: "ui-glass-selector-rail", bundle: resourceBundle)

    /// The "ui-glass-subtitly-icon" asset catalog image resource.
    static let uiGlassSubtitlyIcon = DeveloperToolsSupport.ImageResource(name: "ui-glass-subtitly-icon", bundle: resourceBundle)

    /// The "ui-metrics-analytics-cards" asset catalog image resource.
    static let uiMetricsAnalyticsCards = DeveloperToolsSupport.ImageResource(name: "ui-metrics-analytics-cards", bundle: resourceBundle)

    /// The "ui-metrics-energy-bar" asset catalog image resource.
    static let uiMetricsEnergyBar = DeveloperToolsSupport.ImageResource(name: "ui-metrics-energy-bar", bundle: resourceBundle)

    /// The "ui-metrics-neon-bank" asset catalog image resource.
    static let uiMetricsNeonBank = DeveloperToolsSupport.ImageResource(name: "ui-metrics-neon-bank", bundle: resourceBundle)

    /// The "ui-metrics-soft-charts" asset catalog image resource.
    static let uiMetricsSoftCharts = DeveloperToolsSupport.ImageResource(name: "ui-metrics-soft-charts", bundle: resourceBundle)

    /// The "ui-metrics-viriability" asset catalog image resource.
    static let uiMetricsViriability = DeveloperToolsSupport.ImageResource(name: "ui-metrics-viriability", bundle: resourceBundle)

}

