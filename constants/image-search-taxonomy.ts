const rawTaxonomy = `
nature, landscape, forest, mountains, ocean, beach, sky, sunrise, sunset, waterfall, desert, lake, river, snow, rain, flowers, plants, trees, wildlife, seasons, aerial view, golden hour, misty forest, rocky coast, tropical, alpine, savanna, tundra, rainforest, field, valley, canyon, cliff, island, tide pools, foggy, overcast, starry sky, aurora, travel, city, street, architecture, landmarks, ruins, road trip, map, passport, luggage, airport, train, boat, bridge, market, village, skyline, neighborhood, alley, cobblestone, neon signs, old town, rooftop view, night city, café culture, local market, coastal town, mountain town, European street, Asian city, Mediterranean, Latin America, Scandinavia, Middle East, Southeast Asia, portrait, woman, man, couple, friends, family, children, crowd, group, candid, lifestyle, diversity, community, elderly, baby, teenager, smile, emotion, hands, candid street, cultural portrait, Black and African, studio portrait, silhouette, profile, close-up, natural light portrait, outdoor portrait, joyful, pensive, working, dancing, laughing, reading, food, coffee, restaurant, cooking, baking, fruit, vegetables, bread, dessert, wine, cocktail, tea, breakfast, lunch, dinner, meal, ingredients, kitchen, flat lay, overhead shot, dark food photography, rustic table, fresh market, street food, plant-based, farm to table, café, latte art, charcuterie, harvest, spices, seafood, pasta, sushi, tacos, pizza, smoothie bowl, interior, house, apartment, building, minimal interior, furniture, room, design, exterior, facade, staircase, window, door, ceiling, floor, industrial, modern, classic, Scandinavian design, mid-century, brutalism, glass and steel, wooden cabin, open plan, studio apartment, luxury home, cozy corner, library, museum, cathedral, skyscraper, concrete, exposed brick, business, office, laptop, meeting, teamwork, entrepreneur, startup, desk, workspace, finance, money, chart, presentation, handshake, coworking, remote work, productivity, notebook, strategy, flat lay workspace, standing desk, video call, whiteboard, brainstorm, freelance, coffee and laptop, corporate, hustle, focused work, pen and paper, minimalist desk, tools, planner, wellness, yoga, fitness, gym, meditation, running, hiking, cycling, swimming, sport, healthy food, mental health, sleep, skincare, spa, stretching, mindfulness, nutrition, outdoors exercise, sunrise run, home workout, green juice, foam rolling, trail running, pilates, breathwork, cold plunge, sauna, wellness retreat, supplements, weight training, HIIT, dance, martial arts, swimming pool, technology, computer, phone, code, AI, robot, data, circuit board, digital, innovation, software, hardware, gadget, screen, keyboard, electric car, drone, VR, wearable, neon tech, dark mode, server room, developer, startup lab, futuristic, machine learning, cyberpunk aesthetic, microchip, smart home, 3D printing, solar panel, EV charging, satellite, art, painting, illustration, sculpture, graffiti, photography, drawing, color, abstract, gallery, street art, animation, film, fashion, graphic design, collage, print, oil painting, watercolor, urban art, studio, dark moody, pastel, vintage aesthetic, editorial, surrealism, geometric, typographic, retro, pop art, mixed media, concept art, 3D render, flat design, texture, background, pattern, wallpaper, gradient, marble, wood, stone, metal, fabric, paper, grunge, minimal background, dark background, light background, bokeh, blur, linen, leather, glass, rust, terrazzo, ceramic, sand, water surface, smoke, ink, neon background, pastel background, neutral tones, noise texture, color wash, spirituality, religion, temple, church, mosque, prayer, ritual, ceremony, festival, candle, sacred, culture, tradition, symbol, incense, pilgrimage, altar, light and shadow, golden hour temple, lantern festival, zen garden, boho, crystals, mandala, lotus, monk, sacred geometry, indigenous, cultural celebration, faith, mystical, fog and light, spiritual practice, cinema, camera, analog, grain, double exposure, long exposure, black and white, dramatic lighting, moody, cinematic, portrait film, 35mm, disposable camera, darkroom, motion blur, light leak, film noir, infrared, lomography, color grading, teal and orange, high contrast, backlit, shadows, dreamy, overexposed, underexposed, vintage camera, photojournalism, event, concert, protest, demonstration, politics, news, celebration, parade, graduation, wedding, party, conference, sports event, cultural event, LGBTQ+, social justice, climate, election, documentary style, press photo, crowd energy, night concert, outdoor festival, stadium, fireworks, red carpet, black tie, volunteer, activism, awareness, animals, dog, cat, bird, horse, lion, elephant, bear, wolf, deer, fox, fish, insects, underwater, pet, farm animal, exotic, safari, zoo, macro insect, bird in flight, underwater world, golden hour wildlife, conservation, endangered species, domestic pet, wild horses, marine life, raptor, nocturnal animal, baby animals, migration, nest, aesthetic, dark aesthetic, light aesthetic, cottagecore, dark academia, minimalist, cozy, vintage, soft girl, Y2K, cyberpunk, maximalist, Japandi, warm tones, cool tones, earth tones, monochrome, pink aesthetic, blue aesthetic, green aesthetic, golden, silver, dusty rose, sage green, terracotta, burnt orange, cream, charcoal, fog, haze, desktop wallpaper, phone wallpaper, 4K, HD, 8K, mobile wallpaper, laptop wallpaper, dark wallpaper, light wallpaper, minimal wallpaper, nature wallpaper, space wallpaper, abstract wallpaper, vertical orientation, horizontal orientation, dual monitor, ultra-wide, portrait mode, lock screen, home screen, lofi aesthetic, geometric wallpaper, gradient wallpaper, city at night wallpaper, space, galaxy, stars, moon, planet, cosmos, nebula, astronomy, night sky, Milky Way, solar system, telescope, astronaut, rocket, black hole, aurora borealis, comet, eclipse, long exposure night sky, star trail, dark sky photography, deep space, astrophotography, observatory, ISS, Mars, Jupiter, exoplanet, scientific visualization, space exploration, winter, summer, autumn, spring, fall foliage, storm, sunshine, clouds, blue hour, rainbow, frost, bloom, cherry blossom, tropical heat, cozy winter, first snow, spring thaw, summer haze, autumn colors, thunderstorm, heavy rain, misty morning, cold breath, ice, dried leaves, wildflowers, monsoon, hurricane, wind, negative space, mockup, product photography, brand, influencer, content creator, blog, Instagram, Pinterest, YouTube thumbnail, TikTok, story template, quote background, white background, clean background, minimal flat lay, overhead product, hand holding, close-up detail, golden hour lifestyle, coffee and journal, morning routine, GRWM, OOTD, recipe photography, travel diary
`;

export const IMAGE_SEARCH_TAXONOMY = rawTaxonomy
  .split(',')
  .map((term) => term.trim())
  .filter(Boolean);

function normalizeForMatch(value: string) {
  return value
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^\w\s+]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function getMatchingImageSearchTerms(transcript: string, maxTerms = 8) {
  const normalizedTranscript = normalizeForMatch(transcript);

  if (!normalizedTranscript) {
    return [];
  }

  const matches: string[] = [];

  for (const term of IMAGE_SEARCH_TAXONOMY) {
    const normalizedTerm = normalizeForMatch(term);
    if (!normalizedTerm) {
      continue;
    }

    const hasPhraseMatch = normalizedTranscript.includes(normalizedTerm);
    const hasWordBoundaryMatch =
      normalizedTerm.includes(' ') ||
      new RegExp(`(^|\\s)${normalizedTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(\\s|$)`).test(
        normalizedTranscript
      );

    if (!hasPhraseMatch && !hasWordBoundaryMatch) {
      continue;
    }

    matches.push(term);

    if (matches.length >= maxTerms) {
      break;
    }
  }

  return Array.from(new Set(matches));
}
