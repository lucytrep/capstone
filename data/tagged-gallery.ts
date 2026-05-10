/**
 * Curated assets keyed by tags that appear in filenames / image semantics.
 * Used to surface library artwork on the output screen when dictation text matches.
 */

export type TaggedGalleryEntry = {
  id: string;
  /** Metro `require()` module id */
  imageModule: number;
  alt: string;
  /** Lowercase keywords — match substrings in the normalized transcript */
  tags: readonly string[];
};

const uiNikeGoChartreuse = require('../assets/ui-nike-go-chartreuse-swoosh.png');
const softSpatialUi01 = require('../assets/soft-spatial-ui-1.png');
const softSpatialUi02 = require('../assets/soft-spatial-ui-2.png');
const softSpatialUi03 = require('../assets/soft-spatial-ui-3.png');
const softSpatialUi04 = require('../assets/soft-spatial-ui-4.png');
const nikeEditorial01 = require('../assets/nike-editorial-1.jpg');
const nikeEditorial02 = require('../assets/nike-editorial-2.jpg');
const nikeEditorial03 = require('../assets/nike-editorial-3.jpg');
const nikeEditorial04 = require('../assets/nike-editorial-4.jpg');
const nikeEditorial05 = require('../assets/nike-editorial-5.jpg');

/** Order is stable; scoring picks the best overlaps first. */
export const TAGGED_GALLERY: readonly TaggedGalleryEntry[] = [
  {
    id: 'tagged-ui-nike-go-chartreuse',
    imageModule: uiNikeGoChartreuse,
    alt: 'Nike swoosh on neon chartreuse with GO typography and ripple line energy',
    tags: [
      'nike',
      'swoosh',
      'go',
      'chartreuse',
      'neon',
      'yellow',
      'lime',
      'athletic',
      'fitness',
      'energy',
      'movement',
      'logo',
      'ripple',
      'ripples',
      'motivation',
      'speed',
      'campaign',
      'graphic',
      'design',
      'brand',
    ],
  },
  {
    id: 'tagged-soft-spatial-ui-1',
    imageModule: softSpatialUi01,
    alt: 'Avatar cluster with tooltip and soft floating profile circles',
    tags: ['spatial', 'soft', 'ui', 'avatar', 'cluster', 'profile', 'floating', 'tooltip', 'onboarding'],
  },
  {
    id: 'tagged-soft-spatial-ui-2',
    imageModule: softSpatialUi02,
    alt: 'Floating marketplace cards around centered editorial copy',
    tags: ['spatial', 'soft', 'ui', 'floating', 'cards', 'marketplace', 'editorial', 'commerce'],
  },
  {
    id: 'tagged-soft-spatial-ui-3',
    imageModule: softSpatialUi03,
    alt: 'Interest picker onboarding with rounded image cards',
    tags: ['spatial', 'soft', 'ui', 'picker', 'interest', 'onboarding', 'selection', 'circles'],
  },
  {
    id: 'tagged-soft-spatial-ui-4',
    imageModule: softSpatialUi04,
    alt: 'Gather circles spatial onboarding selection tray',
    tags: ['spatial', 'soft', 'ui', 'tray', 'selection', 'gather', 'onboarding', 'minimal'],
  },
  {
    id: 'tagged-nike-editorial-1',
    imageModule: nikeEditorial01,
    alt: 'Profile portrait with oversized Nike wordmark',
    tags: ['nike', 'portrait', 'wordmark', 'profile', 'editorial', 'hair', 'cyan', 'campaign'],
  },
  {
    id: 'tagged-nike-editorial-2',
    imageModule: nikeEditorial02,
    alt: 'Street fashion with sculptural yellow bag Times Square',
    tags: ['nike', 'street', 'tote', 'bag', 'city', 'yellow', 'fashion', 'urban'],
  },
  {
    id: 'tagged-nike-editorial-3',
    imageModule: nikeEditorial03,
    alt: 'Neon yellow garment dynamic fashion motion',
    tags: ['nike', 'motion', 'neon', 'yellow', 'dynamic', 'activewear', 'sky'],
  },
  {
    id: 'tagged-nike-editorial-4',
    imageModule: nikeEditorial04,
    alt: 'Bold black typographic lockup on bright yellow',
    tags: ['nike', 'type', 'typography', 'lockup', 'yellow', 'bold', 'lettering'],
  },
  {
    id: 'tagged-nike-editorial-5',
    imageModule: nikeEditorial05,
    alt: 'GET INTO IT poster typography yellow activewear',
    tags: ['nike', 'poster', 'campaign', 'typography', 'activewear', 'yellow'],
  },
];

function tokenizeTranscript(transcript: string): { blob: string; words: Set<string> } {
  const blob = transcript
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const words = new Set(blob.split(' ').filter((w) => w.length > 0));
  return { blob, words };
}

function scoreEntry(words: Set<string>, blob: string, entry: TaggedGalleryEntry): number {
  let score = 0;
  for (const tag of entry.tags) {
    if (!tag) continue;
    if (words.has(tag)) {
      score += tag.length >= 5 ? 4 : 3;
      continue;
    }
    // Phrase / compound tags (e.g. brand names) may appear without spaces
    if (tag.length >= 4 && blob.includes(tag)) {
      score += 2;
    }
  }
  return score;
}

/**
 * Returns curated matches when the dictation transcript overlaps tag vocabulary.
 * Minimum score avoids noisy single-letter overlaps.
 */
export function matchTaggedGallery(transcript: string): TaggedGalleryEntry[] {
  const { blob, words } = tokenizeTranscript(transcript);
  if (!blob) return [];

  const minScore = 3;

  return TAGGED_GALLERY.map((entry) => ({ entry, score: scoreEntry(words, blob, entry) }))
    .filter(({ score }) => score >= minScore)
    .sort((a, b) => b.score - a.score)
    .map(({ entry }) => entry);
}
