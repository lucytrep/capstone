import {
  ANTHROPIC_API_KEY,
  GEMINI_API_KEY,
  PEXELS_API_KEY,
  PINTEREST_SERVICE_URL,
  UNSPLASH_ACCESS_KEY,
} from '@/config/keys';
import { getMatchingImageSearchTerms } from '@/constants/image-search-taxonomy';
import { SEMANTIC_CORE, SEMANTIC_WEIGHTS } from '@/data/semantic-core';

const CLAUDE_MODEL = 'claude-sonnet-4-6';
const THE_COLOR_API_BASE = 'https://www.thecolorapi.com';
const COLORMIND_API_URL = 'http://colormind.io/api/';
const PEXELS_API_BASE = 'https://api.pexels.com/v1';
const UNSPLASH_API_BASE = 'https://api.unsplash.com';
const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_IMAGE_MODEL = 'imagen-4.0-generate-001';

type PaletteSwatch = {
  name: string;
  hex: string;
};

type PaletteOption = {
  id: string;
  source: 'the-color-api' | 'colormind';
  swatches: PaletteSwatch[];
};

type TheColorApiSchemeResponse = {
  colors?: Array<{
    name?: { value?: string };
    hex?: { value?: string };
  }>;
};

type TheColorApiIdResponse = {
  name?: { value?: string };
  hex?: { value?: string };
};

type ColormindResponse = {
  result?: number[][];
};

type PhotoItem = {
  id: string;
  imageUrl: string;
  thumbUrl: string;
  alt: string;
  source: 'pexels' | 'unsplash' | 'gemini' | 'pinterest';
  author: string;
  detailUrl: string;
};

type PhotoDisplayMode = 'image' | 'moodboard';

type PhotoOption = {
  id: string;
  displayMode: PhotoDisplayMode;
  source: 'pexels' | 'unsplash' | 'gemini' | 'pinterest' | 'mixed';
  direction?: 'editorial' | 'clean' | 'experimental';
  photos: PhotoItem[];
};

type UiOption = {
  id: string;
  direction: 'editorial' | 'minimal' | 'bold';
  label: string;
  productName: string;
  headline: string;
  supportingText: string;
  primaryCta: string;
  secondaryCta: string;
  accent: string;
  background: string;
  surface: string;
  mutedSurface: string;
  text: string;
  mutedText: string;
};

type PexelsPhotoItem = PhotoItem & { source: 'pexels' };
type UnsplashPhotoItem = PhotoItem & { source: 'unsplash' };
type GeminiPhotoItem = PhotoItem & { source: 'gemini' };
type PinterestPhotoItem = PhotoItem & { source: 'pinterest' };

type PexelsSearchResponse = {
  photos?: Array<{
    id?: number;
    alt?: string;
    url?: string;
    photographer?: string;
    src?: {
      large2x?: string;
      large?: string;
      medium?: string;
    };
  }>;
};

type UnsplashSearchResponse = {
  results?: Array<{
    id?: string;
    alt_description?: string | null;
    description?: string | null;
    links?: {
      html?: string;
    };
    user?: {
      name?: string;
    };
    urls?: {
      regular?: string;
      small?: string;
    };
  }>;
};

type GeminiImagenResponse = {
  generatedImages?: Array<{
    image?: {
      imageBytes?: string;
      mimeType?: string;
    };
  }>;
  predictions?: Array<{
    bytesBase64Encoded?: string;
    mimeType?: string;
    image?: {
      imageBytes?: string;
      mimeType?: string;
    };
  }>;
};

type SemanticCategory = 'Color' | 'UI' | 'Photo';
type BoardType = 'color' | 'photos' | 'ui';

const PHOTO_DIRECTIONS = [
  {
    id: 'editorial' as const,
    title: 'Editorial',
    geminiPrompt: 'Favor cinematic editorial photography, polished styling, dramatic crop choices, and elevated magazine-like composition.',
    sourcePriority: ['unsplash', 'gemini', 'pexels'] as const,
  },
  {
    id: 'clean' as const,
    title: 'Clean',
    geminiPrompt: 'Favor clean lifestyle photography, natural light, balanced composition, whitespace, and calm premium product storytelling.',
    sourcePriority: ['pexels', 'unsplash', 'gemini'] as const,
  },
  {
    id: 'experimental' as const,
    title: 'Experimental',
    geminiPrompt: 'Favor expressive angles, unusual framing, bold close crops, layered depth, and art-directed unexpected composition.',
    sourcePriority: ['gemini', 'unsplash', 'pexels'] as const,
  },
];

type PhotoFocus = 'interior' | 'food' | 'portrait' | 'landscape' | 'general';

function inferPhotoFocus(transcript: string): PhotoFocus {
  const lowered = transcript.toLowerCase();

  if (/(kitchen|bathroom|living room|bedroom|interior|home|house|apartment|tile|tiles|cabinet|countertop|counter|sink|stove)/i.test(lowered)) {
    return 'interior';
  }

  if (/(food|meal|dish|recipe|restaurant|coffee|dessert|kitchen table|cooking|baking)/i.test(lowered)) {
    return 'food';
  }

  if (/(portrait|person|people|woman|man|model|fashion|couple|friends|family)/i.test(lowered)) {
    return 'portrait';
  }

  if (/(nature|landscape|mountain|beach|forest|ocean|desert|valley|sunset|waterfall)/i.test(lowered)) {
    return 'landscape';
  }

  return 'general';
}

function getPhotoFocusKeywords(transcript: string, focus: PhotoFocus) {
  const lowered = transcript.toLowerCase();

  switch (focus) {
    case 'interior':
      return {
        required: ['kitchen', 'interior', 'home', 'tile', 'tiles', 'cabinet', 'counter', 'room'].filter(
          (term) => lowered.includes(term)
        ),
        blocked: ['person', 'people', 'portrait', 'woman', 'man', 'group', 'fashion', 'model', 'couple', 'friends', 'family', 'wedding'],
      };
    case 'food':
      return {
        required: ['food', 'meal', 'dish', 'recipe', 'coffee', 'dessert'].filter((term) =>
          lowered.includes(term)
        ),
        blocked: ['portrait', 'fashion', 'group', 'wedding', 'crowd'],
      };
    case 'landscape':
      return {
        required: ['nature', 'landscape', 'mountain', 'beach', 'forest', 'ocean', 'desert'].filter(
          (term) => lowered.includes(term)
        ),
        blocked: ['portrait', 'fashion', 'group', 'wedding', 'selfie'],
      };
    default:
      return { required: [] as string[], blocked: [] as string[] };
  }
}

function filterPhotosForFocus(photos: PhotoItem[], transcript: string) {
  const focus = inferPhotoFocus(transcript);
  const { required, blocked } = getPhotoFocusKeywords(transcript, focus);

  if (focus === 'general') {
    return photos;
  }

  const kept = photos.filter((photo) => {
    const haystack = `${photo.alt} ${photo.author}`.toLowerCase();
    if (blocked.some((term) => haystack.includes(term))) {
      return false;
    }

    if (required.length === 0) {
      return true;
    }

    return required.some((term) => haystack.includes(term));
  });

  return kept.length >= 5 ? kept : photos.filter((photo) => {
    const haystack = `${photo.alt} ${photo.author}`.toLowerCase();
    return !blocked.some((term) => haystack.includes(term));
  });
}

function scorePhotoForDirection(photo: PhotoItem, direction: 'editorial' | 'clean' | 'experimental') {
  const haystack = `${photo.alt} ${photo.author}`.toLowerCase();
  const directionSignals: Record<typeof direction, string[]> = {
    editorial: ['editorial', 'dramatic', 'moody', 'luxury', 'elegant', 'detail', 'styled', 'design'],
    clean: ['minimal', 'bright', 'clean', 'neutral', 'airy', 'soft', 'modern', 'simple'],
    experimental: ['bold', 'abstract', 'dramatic', 'shadow', 'angle', 'colorful', 'art', 'creative'],
  };

  return directionSignals[direction].reduce(
    (score, term) => score + (haystack.includes(term) ? 2 : 0),
    0
  );
}

function rankPhotosForDirection(
  photos: PhotoItem[],
  direction: 'editorial' | 'clean' | 'experimental',
  seed: number
) {
  return [...photos].sort((a, b) => {
    const scoreDiff = scorePhotoForDirection(b, direction) - scorePhotoForDirection(a, direction);
    if (scoreDiff !== 0) {
      return scoreDiff;
    }

    return hashString(`${b.id}-${seed}`) - hashString(`${a.id}-${seed}`);
  });
}

const SYSTEM_PROMPT = `You are a design artifact generator. The user will describe a design idea. You must ALWAYS respond with only valid HTML and CSS - never text, never questions, never explanations. This app supports exactly 3 board types: UI boards, photo boards, and color boards. Always return a complete, beautiful, self-contained HTML document with embedded CSS. Never ask for clarification. Just build it. Start your response directly with <!DOCTYPE html> and nothing else.

When the user asks for a UI, app screen, interface, product concept, or visual design mock, you MUST follow this exact product-shell pattern:

UI SHELL RULES:
- Background must be pure black: #000000
- Title area at top-left must always say "Draft" on line 1 and "UI" on line 2
- Top-right must include two circular action buttons with an "x" and a check mark
- Show exactly 3 swipeable screen options laid out horizontally
- The HTML itself must support horizontal swipe using CSS scroll snapping
- Each option must be sized for a single iPhone screen and fill the available width without shrinking
- Under the cards, show 3 pagination dots with the active dot elongated
- Do not include a bottom navigation bar; the app chrome is provided outside the generated UI
- The aesthetic should match the reference you provided: bold, high-contrast, polished, phone-mock presentation

CONTENT RULES FOR EACH UI OPTION:
- Each option should show the SAME product idea interpreted in 3 distinct visual directions
- Each option should include a large rounded feature card centered in the phone shell
- The card can contain imagery, gradients, typography, charts, controls, or product UI depending on the prompt
- Preserve the same overall structure across all 3 options; only the visual direction/content should change
- Use strong spacing, large rounded corners, and mobile-first sizing
- Never output a tiny desktop webpage inside the phone frame

Use a mobile-first document with this structure:
- outer black app canvas
- header row with title on left and 2 circular buttons on right
- horizontally scrollable track with 3 snap-aligned option screens
- pagination dots row

The result must be a complete self-contained HTML document with embedded CSS and optional inline SVG only. Do not rely on external assets.
You MUST label the three swipeable options clearly in the markup using data-ui-option="1", data-ui-option="2", and data-ui-option="3" on the 3 top-level option containers.

When the user asks for a color palette, you MUST follow this exact template — no exceptions:

STRUCTURE:
- Background: #000000
- Title: "Draft" in bold, subtitle "Color Palette" below it
- All swatches: border-radius 25px
- Gap between all items: 8px
- Mobile-first layout sized for a single iPhone screen with no desktop scaling
- The artifact must fill the full browser width on mobile and never render as a tiny zoomed-out page
- Generate exactly 6 colors based on the user's description, distributed across rows 1–3
- Explore one strong palette direction clearly enough that the app can derive multiple swipeable options from it
- Row 4 is always fixed: black (#000000) labeled "Night" and off-white (#F7F7F9) labeled "Seasalt"

SWATCH ROWS:
Row 1: 1 swatch — width: 344px; height: 143px
Row 2: 2 swatches — left: width 226px height 143px / right: width 108px height 143px
Row 3: 3 swatches — each width: 107px; height: 101px
Row 4: 2 fixed swatches — each width: 166px; height: 143px — left is #000000 "Night", right is #F7F7F9 "Seasalt"

TEXT ON EACH SWATCH:
- Color name on top line (bold)
- Hex code on line below
- Text color: #FFFFFF if dark swatch, #000000 if light swatch
- font-family: -apple-system, "SF Pro", sans-serif
- font-size: 18px
- font-weight: 700
- line-height: 120%
- letter-spacing: -0.31px
- Positioned bottom-left with padding

Use this exact HTML structure for the palette:
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
  </head>
  <body style="margin:0;background:#000;">
<div style="background:#000;padding:20px;min-height:100vh;width:100%;font-family:-apple-system,'SF Pro',sans-serif">
  <div style="margin-bottom:16px">
    <div style="color:#fff;font-size:28px;font-weight:700;line-height:120%;letter-spacing:-0.5px">Draft</div>
    <div style="color:#888;font-size:16px;font-weight:400;margin-top:2px">Color Palette</div>
  </div>
  <!-- Row 1: 1 swatch 344x143 -->
  <!-- Row 2: 2 swatches 226x143 + 108x143 -->
  <!-- Row 3: 3 swatches 107x101 each -->
  <!-- Row 4: 166x143 #000000 "Night" + 166x143 #F7F7F9 "Seasalt" -->
</div>
  </body>
</html>`;

const PALETTE_KEYWORDS: Record<string, string> = {
  earthy: '#7B5B45',
  forest: '#2E5E42',
  green: '#4C8A5A',
  mint: '#98D8C8',
  ocean: '#256D85',
  blue: '#4A6CF7',
  sky: '#72B6FF',
  purple: '#6A40F3',
  lavender: '#B39DDB',
  pink: '#E56AA6',
  rose: '#D75A7D',
  red: '#B13A30',
  orange: '#E68A2E',
  yellow: '#E5CF57',
  gold: '#D4A336',
  neutral: '#8A847B',
  beige: '#C7B299',
  monochrome: '#555555',
  dark: '#1E1E24',
  neon: '#8A2BE2',
  sunset: '#F06C4E',
  warm: '#D96C3F',
  cool: '#4B7BEC',
};

function normalizeSemanticText(value: string) {
  return value
    .toLowerCase()
    .replace(/[^\w\s+]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function mapCategoryToSemanticCategory(category: SemanticCategory) {
  return category.toLowerCase();
}

function getSemanticMatches(transcript: string, category: SemanticCategory, limit = 3) {
  const normalized = normalizeSemanticText(transcript);
  const target = mapCategoryToSemanticCategory(category);

  const weightedMatches = SEMANTIC_WEIGHTS.filter((row) =>
    normalized.includes(normalizeSemanticText(row.keyword))
  );

  const priorityScore = weightedMatches.reduce((score, row) => {
    const categoryBoost = normalizeSemanticText(row.categoryBoost);
    if (!categoryBoost.includes(target)) {
      return score;
    }
    return score + (row.priority === 'high' ? 3 : 1);
  }, 0);

  const ranked = SEMANTIC_CORE.map((row) => {
    const rowCategory = normalizeSemanticText(row.category);
    const terms = row.userWords
      .split(';')
      .map((term) => normalizeSemanticText(term))
      .filter(Boolean);
    const directMatches = terms.filter((term) => normalized.includes(term)).length;
    const score =
      (rowCategory === target ? 4 : 0) +
      directMatches * 3 +
      priorityScore +
      (normalized.includes(normalizeSemanticText(row.subcategory)) ? 2 : 0);

    return { row, score };
  })
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((entry) => entry.row);

  return ranked;
}

function buildSemanticPromptAugmentation(transcript: string, category: SemanticCategory) {
  const matches = getSemanticMatches(transcript, category);

  if (matches.length === 0) {
    return transcript;
  }

  const interpretedIntent = Array.from(
    new Set(matches.map((row) => row.interpretedIntent.trim()).filter(Boolean))
  ).join(' | ');
  const enrichedPrompts = Array.from(
    new Set(matches.map((row) => row.enrichedPrompt.trim()).filter(Boolean))
  ).slice(0, 2);

  return [
    transcript,
    '',
    `Semantic direction for ${category}:`,
    interpretedIntent ? `Interpreted intent: ${interpretedIntent}` : '',
    ...enrichedPrompts.map((prompt) => `Reference prompt language: ${prompt}`),
  ]
    .filter(Boolean)
    .join('\n');
}

function isPalettePrompt(transcript: string) {
  return /(color palette|palette|color scheme|brand colors?)/i.test(transcript);
}

function isMoodboardPrompt(transcript: string) {
  return /(mood\s*board|moodboard)/i.test(transcript);
}

function isUiPrompt(transcript: string) {
  return /(ui|app screen|interface|product concept|visual design mock|dashboard|landing page|mobile app|screen design|app design|build a screen|generate a screen|home screen|design an app|design a mobile app|design a dashboard|design a landing page|website|web page|webpage|site|header|hero|hero section|section design|design ideas?|creative direction|layout concept|brand direction)/i.test(
    transcript
  );
}

function isPhotoPrompt(transcript: string) {
  if (isMoodboardPrompt(transcript)) {
    return true;
  }

  if (
    /(photo|photos|imagery|images|art direction|moodboard|inspiration|reference images?)/i.test(
      transcript
    )
  ) {
    if (isUiPrompt(transcript)) {
      return false;
    }
    return true;
  }

  if (isPalettePrompt(transcript) || isUiPrompt(transcript)) {
    return false;
  }

  return false;
}

function resolveBoardType(transcript: string): BoardType {
  if (isMoodboardPrompt(transcript)) {
    return 'photos';
  }

  if (isPalettePrompt(transcript)) {
    return 'color';
  }

  if (isPhotoPrompt(transcript)) {
    return 'photos';
  }

  return 'ui';
}

function resolvePhotoDisplayMode(transcript: string): PhotoDisplayMode {
  return isMoodboardPrompt(transcript) ? 'moodboard' : 'image';
}

function hashString(input: string) {
  return Array.from(input).reduce((acc, char) => (acc * 31 + char.charCodeAt(0)) >>> 0, 7);
}

function clampRgb(value: number) {
  return Math.max(0, Math.min(255, Math.round(value)));
}

function rgbToHex(r: number, g: number, b: number) {
  return `#${[r, g, b]
    .map((value) => clampRgb(value).toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase()}`;
}

function mixHex(hex: string, targetHex: string, amount: number) {
  const from = hexToRgb(hex);
  const to = hexToRgb(targetHex);
  const mix = (start: number, end: number) => start + (end - start) * amount;

  return rgbToHex(mix(from.r, to.r), mix(from.g, to.g), mix(from.b, to.b));
}

function hexToRgb(hex: string) {
  const normalized = hex.replace('#', '');
  return {
    r: parseInt(normalized.slice(0, 2), 16),
    g: parseInt(normalized.slice(2, 4), 16),
    b: parseInt(normalized.slice(4, 6), 16),
  };
}

function inferSeedHex(transcript: string) {
  const lowered = transcript.toLowerCase();

  for (const [keyword, hex] of Object.entries(PALETTE_KEYWORDS)) {
    if (lowered.includes(keyword)) {
      return hex;
    }
  }

  const hash = hashString(lowered);
  const r = 48 + (hash & 0x7f);
  const g = 48 + ((hash >> 7) & 0x7f);
  const b = 48 + ((hash >> 14) & 0x7f);
  return rgbToHex(r, g, b);
}

async function fetchJson<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, init);

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Request failed (${response.status}) for ${url}: ${error}`);
  }

  return (await response.json()) as T;
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs: number, label: string): Promise<T> {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;

  try {
    return await Promise.race([
      promise,
      new Promise<T>((_, reject) => {
        timeoutId = setTimeout(() => {
          reject(new Error(`${label} timed out after ${timeoutMs}ms`));
        }, timeoutMs);
      }),
    ]);
  } finally {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
  }
}

async function getTheColorApiScheme(seedHex: string, mode: string): Promise<PaletteSwatch[]> {
  const hex = seedHex.replace('#', '');
  const url = `${THE_COLOR_API_BASE}/scheme?hex=${hex}&mode=${mode}&count=6`;
  const data = await fetchJson<TheColorApiSchemeResponse>(url);

  return (data.colors ?? [])
    .map((color) => ({
      name: color.name?.value?.trim() || 'Untitled',
      hex: color.hex?.value?.toUpperCase() || '#000000',
    }))
    .filter((color) => /^#[0-9A-F]{6}$/.test(color.hex))
    .slice(0, 6);
}

async function getTheColorApiName(hex: string): Promise<string> {
  const cleaned = hex.replace('#', '');
  const url = `${THE_COLOR_API_BASE}/id?hex=${cleaned}`;
  const data = await fetchJson<TheColorApiIdResponse>(url);
  return data.name?.value?.trim() || `Color ${cleaned.toUpperCase()}`;
}

async function getColormindPalette(seedHex: string): Promise<PaletteSwatch[]> {
  const { r, g, b } = hexToRgb(seedHex);
  const body = JSON.stringify({
    model: 'default',
    input: [[r, g, b], 'N', 'N', 'N', 'N'],
  });

  const data = await fetchJson<ColormindResponse>(COLORMIND_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body,
  });

  const colors = (data.result ?? []).slice(0, 5);
  const normalized = await Promise.all(
    colors.map(async (rgb, index) => {
      const [red = 0, green = 0, blue = 0] = rgb;
      const hex = rgbToHex(red, green, blue);
      const name = index === 0 ? 'Anchor' : await getTheColorApiName(hex);
      return { name, hex };
    })
  );

  if (normalized.length < 5) {
    throw new Error('Colormind returned too few colors.');
  }

  const liftedSeedName = await getTheColorApiName(seedHex);
  return [{ name: liftedSeedName, hex: seedHex }, ...normalized.slice(1, 5), {
    name: 'Accent',
    hex: normalized[0].hex,
  }].slice(0, 6);
}

function withFixedPaletteBase(swatches: PaletteSwatch[]) {
  return [
    ...swatches.slice(0, 6),
    { name: 'Night', hex: '#000000' },
    { name: 'Seasalt', hex: '#F7F7F9' },
  ];
}

function buildLocalPaletteOptions(seedHex: string): PaletteOption[] {
  const pastel = [
    { name: 'Anchor', hex: seedHex },
    { name: 'Mist', hex: mixHex(seedHex, '#FFFFFF', 0.58) },
    { name: 'Glow', hex: mixHex(seedHex, '#FFF4E8', 0.42) },
    { name: 'Bloom', hex: mixHex(seedHex, '#FFD9E8', 0.34) },
    { name: 'Skywash', hex: mixHex(seedHex, '#DDF1FF', 0.4) },
    { name: 'Clay', hex: mixHex(seedHex, '#E7C6B1', 0.28) },
  ];

  const airy = [
    { name: 'Petal', hex: mixHex(seedHex, '#FFE4EF', 0.5) },
    { name: 'Cloud', hex: mixHex(seedHex, '#FFFFFF', 0.7) },
    { name: 'Shell', hex: mixHex(seedHex, '#FFF4EC', 0.64) },
    { name: 'Haze', hex: mixHex(seedHex, '#E6F0FF', 0.5) },
    { name: 'Powder', hex: mixHex(seedHex, '#F2E9FF', 0.52) },
    { name: 'Petal Dust', hex: mixHex(seedHex, '#F7D8D0', 0.45) },
  ];

  const contrast = [
    { name: 'Core', hex: mixHex(seedHex, '#000000', 0.06) },
    { name: 'Sunwash', hex: mixHex(seedHex, '#FFF3C4', 0.36) },
    { name: 'Rosewater', hex: mixHex(seedHex, '#FFD4E6', 0.32) },
    { name: 'Cool Air', hex: mixHex(seedHex, '#D7EAFF', 0.28) },
    { name: 'Blush', hex: mixHex(seedHex, '#F3C4C4', 0.24) },
    { name: 'Creamlight', hex: mixHex(seedHex, '#FFF8F0', 0.6) },
  ];

  return [
    { id: 'palette-local-1', swatches: withFixedPaletteBase(pastel) },
    { id: 'palette-local-2', swatches: withFixedPaletteBase(airy) },
    { id: 'palette-local-3', swatches: withFixedPaletteBase(contrast) },
  ];
}

function extractCoreImagePrompt(transcript: string) {
  return transcript
    .replace(
      /\b(can you|could you|would you|i want|i need|help me|show me|give me|find me|make me|please|curate|put together|bring together|draft)\b/gi,
      ' '
    )
    .replace(/\b(some|a set of|set of|collection of)\b/gi, ' ')
    .replace(
      /\b(reference images?|reference photos?|image references?|photo references?|images?|photos?|imagery|art direction|moodboard)\b/gi,
      ' '
    )
    .replace(/\b(for me|for us|for this|based on|that feel like|that feels like)\b/gi, ' ')
    .replace(/[.,!?;:()[\]"]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function buildSearchQuery(transcript: string) {
  const cleanedTranscript = extractCoreImagePrompt(transcript);

  const matchedTerms = getMatchingImageSearchTerms(cleanedTranscript, 3);

  if (matchedTerms.length > 0) {
    return Array.from(new Set([cleanedTranscript, ...matchedTerms]))
      .filter(Boolean)
      .join(' ');
  }

  return cleanedTranscript;
}

function buildPaletteArtifactHtml(options: PaletteOption[]) {
  const json = JSON.stringify({ kind: 'palette-options', options });
  const preview = options[0]?.swatches ?? [];

  const rows = [
    preview[0] ? `<div style="height:146px;border-radius:25px;background:${preview[0].hex};padding:14px;display:flex;align-items:flex-end;font-weight:700">${preview[0].name}<br/>${preview[0].hex}</div>` : '',
    preview[1] && preview[2]
      ? `<div style="display:grid;grid-template-columns:2fr 1fr;gap:8px"><div style="height:138px;border-radius:25px;background:${preview[1].hex};padding:14px;display:flex;align-items:flex-end;font-weight:700">${preview[1].name}<br/>${preview[1].hex}</div><div style="height:138px;border-radius:25px;background:${preview[2].hex};padding:14px;display:flex;align-items:flex-end;font-weight:700">${preview[2].name}<br/>${preview[2].hex}</div></div>` : '',
  ].join('');

  return `<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
    <script id="draft-palette-options" type="application/json">${json}</script>
  </head>
  <body style="margin:0;background:#000;color:#fff;font-family:-apple-system,'SF Pro',sans-serif;">
    <div style="padding:20px;min-height:100vh;background:#000;">
      <div style="font-size:28px;font-weight:700;line-height:1.1;">Draft</div>
      <div style="font-size:16px;color:#8A8A8A;margin-bottom:16px;">Color Palette</div>
      <div style="display:grid;gap:8px;">${rows}</div>
    </div>
  </body>
</html>`;
}

async function generateColorPaletteArtifact(transcript: string): Promise<string> {
  const semanticTranscript = buildSemanticPromptAugmentation(transcript, 'Color');
  const seedHex = inferSeedHex(semanticTranscript);

  try {
    const [analogic, quad, colormind] = await Promise.all([
      getTheColorApiScheme(seedHex, 'analogic'),
      getTheColorApiScheme(seedHex, 'quad'),
      getColormindPalette(seedHex),
    ]);

    const options: PaletteOption[] = [
      { id: 'palette-1', source: 'the-color-api', swatches: withFixedPaletteBase(analogic) },
      { id: 'palette-2', source: 'the-color-api', swatches: withFixedPaletteBase(quad) },
      { id: 'palette-3', source: 'colormind', swatches: withFixedPaletteBase(colormind) },
    ];

    return buildPaletteArtifactHtml(options);
  } catch (error) {
    console.error('Palette API generation failed, using local palette fallback.', error);
    return buildPaletteArtifactHtml(buildLocalPaletteOptions(seedHex));
  }
}

async function getPexelsPhotos(query: string, seed: number): Promise<PhotoItem[]> {
  if (!PEXELS_API_KEY.trim()) {
    return [];
  }

  const page = (seed % 3) + 1;
  const url = `${PEXELS_API_BASE}/search?query=${encodeURIComponent(query)}&per_page=8&orientation=portrait&page=${page}`;
  const data = await fetchJson<PexelsSearchResponse>(url, {
    headers: {
      Authorization: PEXELS_API_KEY,
    },
  });

  return (data.photos ?? [])
    .map((photo) => {
      const large = photo.src?.large2x || photo.src?.large || photo.src?.medium;
      const thumb = photo.src?.medium || photo.src?.large || photo.src?.large2x;

      if (!photo.id || !large || !thumb) {
        return null;
      }

      const item: PexelsPhotoItem = {
        id: `pexels-${photo.id}`,
        imageUrl: large,
        thumbUrl: thumb,
        alt: photo.alt?.trim() || 'Pexels inspiration image',
        source: 'pexels',
        author: photo.photographer?.trim() || 'Pexels',
        detailUrl: photo.url || '',
      };

      return item;
    })
    .filter((photo): photo is PexelsPhotoItem => photo !== null);
}

async function getUnsplashPhotos(query: string, seed: number): Promise<PhotoItem[]> {
  if (!UNSPLASH_ACCESS_KEY.trim()) {
    return [];
  }

  const page = (seed % 3) + 1;
  const url = `${UNSPLASH_API_BASE}/search/photos?query=${encodeURIComponent(query)}&per_page=8&orientation=portrait&page=${page}`;
  const data = await fetchJson<UnsplashSearchResponse>(url, {
    headers: {
      Authorization: `Client-ID ${UNSPLASH_ACCESS_KEY}`,
      'Accept-Version': 'v1',
    },
  });

  return (data.results ?? [])
    .map((photo) => {
      const regular = photo.urls?.regular;
      const small = photo.urls?.small;

      if (!photo.id || !regular || !small) {
        return null;
      }

      const item: UnsplashPhotoItem = {
        id: `unsplash-${photo.id}`,
        imageUrl: regular,
        thumbUrl: small,
        alt:
          photo.alt_description?.trim() ||
          photo.description?.trim() ||
          'Unsplash inspiration image',
        source: 'unsplash',
        author: photo.user?.name?.trim() || 'Unsplash',
        detailUrl: photo.links?.html || '',
      };

      return item;
    })
    .filter((photo): photo is UnsplashPhotoItem => photo !== null);
}

type PinterestServiceResponse = {
  photos?: Array<{
    id?: string;
    imageUrl?: string;
    thumbUrl?: string;
    alt?: string;
    author?: string;
    detailUrl?: string;
  }>;
  error?: string;
};

async function getPinterestPhotos(query: string): Promise<PhotoItem[]> {
  if (!PINTEREST_SERVICE_URL.trim()) {
    return [];
  }

  const url = `${PINTEREST_SERVICE_URL}/search?q=${encodeURIComponent(query)}&max=10`;
  const data = await fetchJson<PinterestServiceResponse>(url);

  return (data.photos ?? [])
    .map((photo) => {
      if (!photo.id || !photo.imageUrl || !photo.thumbUrl) {
        return null;
      }

      const item: PinterestPhotoItem = {
        id: photo.id,
        imageUrl: photo.imageUrl,
        thumbUrl: photo.thumbUrl,
        alt: photo.alt?.trim() || 'Pinterest inspiration',
        source: 'pinterest',
        author: photo.author?.trim() || 'Pinterest',
        detailUrl: photo.detailUrl || '',
      };

      return item;
    })
    .filter((photo): photo is PinterestPhotoItem => photo !== null);
}

function buildGeminiImagePrompt(
  transcript: string,
  seed: number,
  directionPrompt?: string,
  displayMode: PhotoDisplayMode = 'image'
) {
  const corePrompt = extractCoreImagePrompt(transcript);
  const matchedTerms = getMatchingImageSearchTerms(corePrompt, 4);
  const keywordLine = matchedTerms.length > 0 ? ` Keywords: ${matchedTerms.join(', ')}.` : '';
  const directionPrompts = [
    'Favor cinematic editorial photography with bold close crops.',
    'Favor airy composition with varied distance and clean negative space.',
    'Favor expressive angles, layered depth, and unexpected framing.',
  ];
  const directionLine = directionPrompt || directionPrompts[seed % directionPrompts.length];

  return [
    `Create a high-quality vertical set of ${displayMode === 'moodboard' ? 'moodboard imagery' : 'editorial imagery'} for design inspiration.`,
    "Honor the user's dictation closely and keep the exact subject, styling cues, materials, mood words, era references, and composition notes from the request.",
    `User request: ${corePrompt || transcript}.`,
    keywordLine,
    directionLine,
    'Generate distinct compositions with varied crops, strong lighting, and polished photography.',
    'Avoid color chips, palette cards, flat swatches, UI mockups, abstract gradients, and text overlays unless the user explicitly asked for them.',
    'Images should feel suitable for a premium mobile moodboard.',
  ]
    .filter(Boolean)
    .join(' ');
}

async function getGeminiPhotos(
  transcript: string,
  seed: number,
  directionPrompt?: string,
  directionKey?: 'editorial' | 'clean' | 'experimental',
  displayMode: PhotoDisplayMode = 'image'
): Promise<PhotoItem[]> {
  if (!GEMINI_API_KEY.trim()) {
    return [];
  }

  const response = await fetch(`${GEMINI_API_BASE}/models/${GEMINI_IMAGE_MODEL}:predict`, {
    method: 'POST',
    headers: {
      'x-goog-api-key': GEMINI_API_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      instances: [
        {
          prompt: buildGeminiImagePrompt(transcript, seed, directionPrompt, displayMode),
        },
      ],
      parameters: {
        sampleCount: 2,
        aspectRatio: '9:16',
      },
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Gemini image API error (${response.status}): ${error}`);
  }

  const data = (await response.json()) as GeminiImagenResponse;
  const predictions =
    data.generatedImages?.map((item) => ({
      bytesBase64Encoded: item.image?.imageBytes,
      mimeType: item.image?.mimeType,
    })) ??
    data.predictions ??
    [];

  return predictions
    .map((prediction, index) => {
      const base64 = prediction.bytesBase64Encoded || prediction.image?.imageBytes;
      const mimeType = prediction.mimeType || prediction.image?.mimeType || 'image/png';

      if (!base64) {
        return null;
      }

      const dataUrl = `data:${mimeType};base64,${base64}`;
      const item: GeminiPhotoItem = {
        id: `gemini-${directionKey || 'default'}-${seed}-${index + 1}`,
        imageUrl: dataUrl,
        thumbUrl: dataUrl,
        alt: transcript.trim() || 'Gemini generated inspiration image',
        source: 'gemini',
        author: 'Gemini',
        detailUrl: '',
      };

      return item;
    })
    .filter((photo): photo is GeminiPhotoItem => photo !== null);
}

function dedupePhotos(photos: PhotoItem[]) {
  const seen = new Set<string>();
  return photos.filter((photo) => {
    const key = photo.id || photo.imageUrl;
    if (!key || seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  });
}

function hashSeed(input: string) {
  return Array.from(input).reduce((acc, char) => (acc * 33 + char.charCodeAt(0)) >>> 0, 5381);
}

function shufflePhotos(photos: PhotoItem[], seed: number) {
  const next = [...photos];
  let state = seed || 1;

  for (let i = next.length - 1; i > 0; i -= 1) {
    state = (state * 1664525 + 1013904223) >>> 0;
    const j = state % (i + 1);
    [next[i], next[j]] = [next[j], next[i]];
  }

  return next;
}

function fillPhotoSlots(photos: PhotoItem[], count = 5, offset = 0) {
  const unique = dedupePhotos(photos);

  if (unique.length < count) {
    return [];
  }

  const normalizedOffset = ((offset % unique.length) + unique.length) % unique.length;
  const rotated = [...unique.slice(normalizedOffset), ...unique.slice(0, normalizedOffset)];
  return rotated.slice(0, count);
}

function takeUniquePhotos(photos: PhotoItem[], usedPhotoIds: Set<string>, count = 5) {
  const next: PhotoItem[] = [];

  for (const photo of photos) {
    const key = photo.id || photo.imageUrl;
    if (!key || usedPhotoIds.has(key)) {
      continue;
    }

    usedPhotoIds.add(key);
    next.push(photo);

    if (next.length === count) {
      break;
    }
  }

  return next;
}

function buildPhotoOptions(
  pexelsPhotos: PhotoItem[],
  unsplashPhotos: PhotoItem[],
  geminiPhotosByDirection: Record<'editorial' | 'clean' | 'experimental', PhotoItem[]>,
  seedInput: string,
  transcript: string,
  displayMode: PhotoDisplayMode
) {
  const seed = hashSeed(seedInput);
  const filteredPexels = filterPhotosForFocus(dedupePhotos(pexelsPhotos), transcript);
  const filteredUnsplash = filterPhotosForFocus(dedupePhotos(unsplashPhotos), transcript);
  const shuffledPexels = shufflePhotos(filteredPexels, seed + 11);
  const shuffledUnsplash = shufflePhotos(filteredUnsplash, seed + 23);
  const shuffledGeminiByDirection = {
    editorial: shufflePhotos(
      filterPhotosForFocus(dedupePhotos(geminiPhotosByDirection.editorial), transcript),
      seed + 31
    ),
    clean: shufflePhotos(
      filterPhotosForFocus(dedupePhotos(geminiPhotosByDirection.clean), transcript),
      seed + 37
    ),
    experimental: shufflePhotos(
      filterPhotosForFocus(dedupePhotos(geminiPhotosByDirection.experimental), transcript),
      seed + 41
    ),
  };
  const allGemini = dedupePhotos([
    ...shuffledGeminiByDirection.editorial,
    ...shuffledGeminiByDirection.clean,
    ...shuffledGeminiByDirection.experimental,
  ]);
  const shuffledCombined = shufflePhotos(
    dedupePhotos([...shuffledPexels, ...shuffledUnsplash, ...allGemini]),
    seed + 53
  );

  const combinedFilled = fillPhotoSlots(shuffledCombined, 5, (seed >> 6) % 5);

  if (combinedFilled.length === 0) {
    return [];
  }

  const options: PhotoOption[] = [];
  const usedOptionKeys = new Set<string>();
  const usedPhotoIds = new Set<string>();

  const addOption = (option: PhotoOption) => {
    const dedupedPhotos = dedupePhotos(option.photos);
    if (dedupedPhotos.length < 5) {
      return;
    }

    const finalPhotos = dedupedPhotos.slice(0, 5);
    const key = finalPhotos.map((photo) => photo.id).join('|');

    if (!key || usedOptionKeys.has(key)) {
      return;
    }

    usedOptionKeys.add(key);
    options.push({
      ...option,
      photos: finalPhotos,
    });
  };

  const photosBySource = {
    pexels: shuffledPexels,
    unsplash: shuffledUnsplash,
    gemini: allGemini,
  };

  PHOTO_DIRECTIONS.forEach((direction, index) => {
    const directionGemini = fillPhotoSlots(
      shuffledGeminiByDirection[direction.id],
      Math.min(5, shuffledGeminiByDirection[direction.id].length),
      (seed + index) % 4
    );
    const prioritizedPool = rankPhotosForDirection(
      dedupePhotos([
      ...directionGemini,
      ...direction.sourcePriority.flatMap((source) => photosBySource[source]),
      ...combinedFilled,
      ...shuffledCombined,
      ]),
      direction.id,
      seed + index * 17
    );
    const curated = takeUniquePhotos(prioritizedPool, usedPhotoIds, 5);

    if (curated.length < 5) {
      return;
    }

    const primarySource = curated[0]?.source ?? 'mixed';
    const knownSources = ['gemini', 'pexels', 'unsplash', 'pinterest'] as const;
    addOption({
      id: `photos-${direction.id}`,
      displayMode,
      source: (knownSources as readonly string[]).includes(primarySource) ? primarySource as typeof knownSources[number] : 'mixed',
      direction: direction.id,
      photos: curated,
    });
  });

  for (let index = 1; options.length < 3 && index < shuffledCombined.length; index += 1) {
    const rotated = fillPhotoSlots(shuffledCombined, Math.min(5, shuffledCombined.length), index);
    if (rotated.length === 0) {
      continue;
    }
    const curated = takeUniquePhotos(rotated, usedPhotoIds, 5);
    if (curated.length < 5) {
      continue;
    }

    addOption({
      id: `photos-mixed-alt-${index}`,
      displayMode,
      source: 'mixed',
      photos: curated,
    });
  }

  return options.slice(0, 3).map((option, index) => ({
    ...option,
    id: option.id || `photos-${index + 1}`,
  }));
}

function buildPhotoArtifactHtml(options: PhotoOption[]) {
  const json = JSON.stringify({ kind: 'photo-options', options });
  const displayMode = options[0]?.displayMode ?? 'image';
  return `<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
    <script id="draft-photo-options" type="application/json">${json}</script>
  </head>
  <body style="margin:0;background:#000;color:#fff;font-family:-apple-system,'SF Pro',sans-serif;">
    <div style="padding:20px;min-height:100vh;background:#000;">
      <div style="font-size:28px;font-weight:700;line-height:1.1;">Draft</div>
      <div style="font-size:16px;color:#8A8A8A;margin-bottom:16px;">${displayMode === 'moodboard' ? 'Moodboard' : 'Image Gathering'}</div>
      <div style="font-size:14px;color:#A0A0A0;">Swipeable inspiration options ready.</div>
    </div>
  </body>
</html>`;
}

function toTitleCase(value: string) {
  return value
    .split(' ')
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function inferUiFallbackName(transcript: string) {
  const cleaned = transcript
    .toLowerCase()
    .replace(
      /\b(generate|design|create|build|make|show|give|app|screen|interface|ui|dashboard|landing page|mobile|website|site|header|hero|section|layout|ideas|concept|for|with|a|an|the)\b/gi,
      ' '
    )
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const tokens = cleaned.split(' ').filter(Boolean).slice(0, 2);
  const base = tokens.length > 0 ? toTitleCase(tokens.join(' ')) : 'Studio';
  return base.length > 18 ? `${base.slice(0, 18).trim()} Concept` : `${base} Concept`;
}

function buildUiConceptName(transcript: string) {
  return inferUiFallbackName(transcript).replace(/\s+Concept$/i, '');
}

function inferUiSubject(transcript: string) {
  const cleaned = transcript
    .toLowerCase()
    .replace(
      /\b(generate|design|create|build|make|show|give|ideas|inspiration|creative direction|for|a|an|the)\b/gi,
      ' '
    )
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  return cleaned || 'digital experience';
}

function buildUiOptions(transcript: string): UiOption[] {
  const productName = buildUiConceptName(transcript);
  const subject = inferUiSubject(transcript);

  return [
    {
      id: 'ui-1',
      direction: 'editorial',
      label: 'Editorial',
      productName,
      headline: `A dramatic ${subject} with layered storytelling`,
      supportingText: 'Strong hierarchy, image-led composition, and premium pacing built for a first-impression concept.',
      primaryCta: 'Explore concept',
      secondaryCta: 'View story',
      accent: '#D98752',
      background: '#F6ECDD',
      surface: '#FFF9F2',
      mutedSurface: '#EEDBC5',
      text: '#1D120A',
      mutedText: 'rgba(29,18,10,0.62)',
    },
    {
      id: 'ui-2',
      direction: 'minimal',
      label: 'Minimal',
      productName,
      headline: `A clear ${subject} system with calm spacing`,
      supportingText: 'Minimal framing, crisp modules, and a quieter visual rhythm for a refined polished direction.',
      primaryCta: 'See layout',
      secondaryCta: 'Read details',
      accent: '#6D8CFF',
      background: '#EEF3FF',
      surface: '#FFFFFF',
      mutedSurface: '#E1E9FF',
      text: '#111827',
      mutedText: 'rgba(17,24,39,0.62)',
    },
    {
      id: 'ui-3',
      direction: 'bold',
      label: 'Bold',
      productName,
      headline: `A high-energy ${subject} with punchy motion cues`,
      supportingText: 'Asymmetry, larger moments, and brighter contrast for a more expressive concept direction.',
      primaryCta: 'Launch idea',
      secondaryCta: 'See modules',
      accent: '#F46FA9',
      background: '#111111',
      surface: '#1F1F1F',
      mutedSurface: '#2A2A2A',
      text: '#FFFFFF',
      mutedText: 'rgba(255,255,255,0.62)',
    },
  ];
}

function buildUiArtifactHtml(options: UiOption[]) {
  const json = JSON.stringify({ kind: 'ui-options', options });
  return `<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
    <script id="draft-ui-options" type="application/json">${json}</script>
  </head>
  <body style="margin:0;background:#000;color:#fff;font-family:-apple-system,'SF Pro',sans-serif;">
    <div style="padding:20px;min-height:100vh;background:#000;">
      <div style="font-size:28px;font-weight:700;line-height:1.1;">Draft</div>
      <div style="font-size:16px;color:#8A8A8A;margin-bottom:16px;">UI</div>
      <div style="font-size:14px;color:#A0A0A0;">Swipeable concept directions ready.</div>
    </div>
  </body>
</html>`;
}

function buildUiFallbackArtifactHtml(transcript: string) {
  return buildUiArtifactHtml(buildUiOptions(transcript));
}

function hasPhotoProviderKeys() {
  return (
    Boolean(PEXELS_API_KEY.trim()) ||
    Boolean(UNSPLASH_ACCESS_KEY.trim()) ||
    Boolean(GEMINI_API_KEY.trim()) ||
    Boolean(PINTEREST_SERVICE_URL.trim())
  );
}

async function generateClaudePhotoArtifact(transcript: string): Promise<string> {
  try {
    return await requestClaudeArtifact(
      transcript,
      [
        'This is an image or moodboard request.',
        'Do not rely on external image URLs, stock APIs, or remote assets.',
        'Create a self-contained visual artifact with 3 swipeable directions using gradients, shapes, captions, and art-direction treatments.',
        'Treat each option as a different image-generation direction or moodboard concept for the same request.',
        'If photos would normally appear, simulate them with polished abstract editorial placeholders instead.',
      ].join('\n'),
      1600,
      12000
    );
  } catch (error) {
    console.error('Claude photo fallback failed.', error);
    return '';
  }
}

async function generatePhotoArtifact(transcript: string): Promise<string> {
  const displayMode = resolvePhotoDisplayMode(transcript);
  const corePrompt = extractCoreImagePrompt(transcript);
  const query = buildSearchQuery(transcript) || corePrompt || transcript;
  const requestSeed = `${transcript}::${Date.now()}`;
  const providerSeed = hashSeed(requestSeed);

  if (!hasPhotoProviderKeys()) {
    return '';
  }

  try {
    const [
      pexelsResult,
      unsplashResult,
      pinterestResult,
      geminiEditorialResult,
      geminiCleanResult,
      geminiExperimentalResult,
    ] = await Promise.allSettled([
      withTimeout(getPexelsPhotos(query, providerSeed + 1), 2500, 'Pexels'),
      withTimeout(getUnsplashPhotos(query, providerSeed + 2), 2500, 'Unsplash'),
      withTimeout(getPinterestPhotos(query), 30000, 'Pinterest'),
      withTimeout(
        getGeminiPhotos(
          transcript,
          providerSeed + 3,
          PHOTO_DIRECTIONS[0].geminiPrompt,
          'editorial',
          displayMode
        ),
        4500,
        'Gemini editorial'
      ),
      withTimeout(
        getGeminiPhotos(
          transcript,
          providerSeed + 4,
          PHOTO_DIRECTIONS[1].geminiPrompt,
          'clean',
          displayMode
        ),
        4500,
        'Gemini clean'
      ),
      withTimeout(
        getGeminiPhotos(
          transcript,
          providerSeed + 5,
          PHOTO_DIRECTIONS[2].geminiPrompt,
          'experimental',
          displayMode
        ),
        4500,
        'Gemini experimental'
      ),
    ]);

    const pexelsPhotos = pexelsResult.status === 'fulfilled' ? pexelsResult.value : [];
    const unsplashPhotos = unsplashResult.status === 'fulfilled' ? unsplashResult.value : [];
    const pinterestPhotos = pinterestResult.status === 'fulfilled' ? pinterestResult.value : [];
    const geminiPhotosByDirection = {
      editorial:
        geminiEditorialResult.status === 'fulfilled' ? geminiEditorialResult.value : [],
      clean: geminiCleanResult.status === 'fulfilled' ? geminiCleanResult.value : [],
      experimental:
        geminiExperimentalResult.status === 'fulfilled'
          ? geminiExperimentalResult.value
          : [],
    };

    if (pexelsResult.status === 'rejected') {
      console.warn('Pexels photo fetch skipped:', pexelsResult.reason);
    }
    if (unsplashResult.status === 'rejected') {
      console.warn('Unsplash photo fetch skipped:', unsplashResult.reason);
    }
    if (pinterestResult.status === 'rejected') {
      console.warn('Pinterest photo fetch skipped:', pinterestResult.reason);
    }
    if (geminiEditorialResult.status === 'rejected') {
      console.warn('Gemini editorial photo fetch skipped:', geminiEditorialResult.reason);
    }
    if (geminiCleanResult.status === 'rejected') {
      console.warn('Gemini clean photo fetch skipped:', geminiCleanResult.reason);
    }
    if (geminiExperimentalResult.status === 'rejected') {
      console.warn('Gemini experimental photo fetch skipped:', geminiExperimentalResult.reason);
    }

    const options = buildPhotoOptions(
      [...pexelsPhotos, ...pinterestPhotos],
      unsplashPhotos,
      geminiPhotosByDirection,
      requestSeed,
      transcript,
      displayMode
    );

    if (options.length === 0) {
      return '';
    }

    return buildPhotoArtifactHtml(options);
  } catch (error) {
    console.error('Photo API generation failed, falling back to Claude.', error);
    return '';
  }
}


async function requestClaudeArtifact(
  transcript: string,
  extraInstruction?: string,
  maxTokens = 2400,
  timeoutMs = 20000
): Promise<string> {
  if (!ANTHROPIC_API_KEY.trim()) {
    throw new Error('Anthropic API key is missing.');
  }

  const userContent = extraInstruction
    ? `${transcript}\n\nAdditional hard requirements:\n${extraInstruction}`
    : transcript;

  const response = await withTimeout(
    fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: maxTokens,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: userContent }],
      }),
    }),
    timeoutMs,
    'Claude'
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Claude API error (${response.status}): ${error}`);
  }

  const data = await response.json();
  const text = Array.isArray(data.content)
    ? data.content
        .filter((block: { type?: string; text?: string }) => block?.type === 'text' && block?.text)
        .map((block: { text: string }) => block.text)
        .join('\n')
    : '';

  if (!text.trim()) {
    throw new Error('Claude returned an empty response.');
  }

  let cleaned = text
    .replace(/^```html\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();

  const firstTag = cleaned.indexOf('<');
  if (firstTag > 0) {
    cleaned = cleaned.slice(firstTag);
  }

  console.log('[Claude cleaned HTML — first 300 chars]', cleaned.slice(0, 300));

  return cleaned;
}

function validateUiArtifact(html: string) {
  const optionMatches = html.match(/data-ui-option="([123])"/g) ?? [];
  const hasScrollSnap =
    /scroll-snap-type/i.test(html) ||
    /snap-aligned/i.test(html) ||
    /overflow-x:\s*(auto|scroll)/i.test(html);
  const hasDraftUiHeader = /Draft/i.test(html) && />\s*UI\s*</i.test(html);
  const tagCount = (html.match(/<div\b|<section\b|<button\b|<main\b|<article\b/gi) ?? []).length;
  const hasRichStructure =
    /border-radius/i.test(html) &&
    /display:\s*(flex|grid)/i.test(html) &&
    tagCount >= 12;

  return optionMatches.length >= 3 && hasScrollSnap && hasDraftUiHeader && hasRichStructure;
}
/**
 * Send a text transcript to Claude and get back a self-contained HTML design artifact.
 */
export async function generateArtifact(transcript: string): Promise<string> {
  const boardType = resolveBoardType(transcript);

  if (boardType === 'color') {
    return generateColorPaletteArtifact(transcript);
  }

  if (boardType === 'photos') {
    const photoArtifact = await generatePhotoArtifact(transcript);
    if (photoArtifact) {
      return photoArtifact;
    }

    const claudePhotoArtifact = await generateClaudePhotoArtifact(transcript);
    if (claudePhotoArtifact) {
      return claudePhotoArtifact;
    }
  }

  if (boardType === 'ui' && isUiPrompt(transcript)) {
    return buildUiArtifactHtml(buildUiOptions(transcript));
  }

  const semanticCategory: SemanticCategory = 'UI';
  const semanticTranscript = buildSemanticPromptAugmentation(transcript, semanticCategory);
  const uiInstructions = [
    'Return exactly 3 swipeable UI options.',
    'Each option container must include data-ui-option="1", data-ui-option="2", and data-ui-option="3".',
    'Make the 3 options genuinely distinct directions, not minor color tweaks.',
    'The three directions must differ in layout, hierarchy, composition, and component structure.',
    'Changing only color is invalid.',
    'Use a clear trio such as editorial, minimal, and experimental, or another equally distinct set of directions.',
    'Use horizontal scroll snapping so the user can land on one option at a time.',
    'Keep the Draft / UI header, top-right action buttons, and pagination dots.',
    'Do not include a bottom navigation bar; app chrome is already provided outside the generated UI.',
  ].join('\n');

  let artifact = '';

  try {
    artifact = await requestClaudeArtifact(
      semanticTranscript,
      isUiPrompt(transcript) ? uiInstructions : undefined,
      isUiPrompt(transcript) ? 2600 : 2400,
      isUiPrompt(transcript) ? 18000 : 16000
    );

    if (isUiPrompt(transcript) && !validateUiArtifact(artifact)) {
      console.warn('Claude returned malformed UI HTML, using local fallback.');
      artifact = buildUiFallbackArtifactHtml(transcript);
    }
  } catch (error) {
    console.error('UI generation failed, using local fallback.', error);
    artifact = buildUiFallbackArtifactHtml(transcript);
  }

  if (!artifact.trim()) {
    return buildUiFallbackArtifactHtml(transcript);
  }

  return artifact;
}
