/**
 * Filters third-party stock metadata so moodboard results stay safe and on-brand
 * (premium editorial stills, not memes / shock / junk alt-text).
 */

export type ImageSensorFields = {
  alt: string;
  author?: string;
  imageUrl?: string;
  detailUrl?: string;
  /** When set, blocked terms that appear in the user's request are allowed. */
  transcript?: string;
  /** Generated images are not described by stock metadata; rely on model safety instead. */
  source?: string;
};

function normalize(value: string) {
  return value
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function transcriptAllowsTerm(transcriptNorm: string, term: string) {
  if (!transcriptNorm || !term) {
    return false;
  }
  if (transcriptNorm.includes(term)) {
    return true;
  }
  if (term.includes(' ')) {
    return false;
  }
  const re = new RegExp(`(^|\\s)${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(\\s|$)`);
  return re.test(transcriptNorm);
}

/** Single-word tokens matched with word boundaries against alt/author/urls. */
const BLOCKED_WORDS = [
  'nude',
  'naked',
  'nsfw',
  'porn',
  'porno',
  'xxx',
  'erotic',
  'fetish',
  'bdsm',
  'lingerie',
  'topless',
  'bottomless',
  'sex',
  'orgy',
  'thong',
  'provocative',
  'seductive',
  'blood',
  'bloody',
  'gore',
  'gory',
  'corpse',
  'suicide',
  'mutilation',
  'torture',
  'beheading',
  'massacre',
  'swastika',
  'kkk',
  'cocaine',
  'heroin',
  'methamphetamine',
  'meth',
  'crack',
  'syringe',
  'feces',
  'urine',
];

/** Multi-word or fragile phrases (substring match on normalized haystack). */
const BLOCKED_PHRASES = [
  'not safe for work',
  'adult content',
  'explicit content',
  'sex toy',
  'strip club',
  'gun point',
  'white power',
  'hate crime',
  'dead body',
  'crime scene',
  'car accident',
  'graphic violence',
  'child abuse',
  'animal abuse',
];

/** Off-topic or low-fit results for a premium design moodboard. */
const AESTHETIC_DRIFT_PHRASES = [
  'meme',
  'memes',
  'lol',
  'lmao',
  'clipart',
  'clip art',
  'cartoon character',
  'emoji',
  'screenshot',
  'tiktok',
  'youtube thumbnail',
  'clickbait',
  'watermark',
  'shutterstock',
  'getty images',
  'istock',
  'vector pack',
  'icon pack',
  'powerpoint template',
  'political rally',
  'election poster',
  'protest sign',
  'riot police',
  'war zone',
  'soldier aiming',
  'military parade',
  'funeral',
  'coffin',
  'morgue',
  'surgery',
  'wound',
  'rash',
  'std',
  'toilet',
  'middle finger',
];

function collectHaystack(photo: ImageSensorFields) {
  return normalize(
    [photo.alt, photo.author, photo.imageUrl, photo.detailUrl].filter(Boolean).join(' ')
  );
}

function phraseHit(haystack: string, phrase: string) {
  const p = phrase.trim();
  if (!p) {
    return false;
  }
  if (!p.includes(' ')) {
    return false;
  }
  return haystack.includes(p);
}

function wordHit(haystack: string, word: string) {
  const w = word.trim();
  if (!w || w.includes(' ')) {
    return false;
  }
  const re = new RegExp(`(^|\\s)${w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(\\s|$)`);
  return re.test(haystack);
}

/**
 * Returns false when metadata suggests unsafe, graphic, or off-brand stock.
 * Pass the user transcript so intentional requests are not stripped.
 */
export function photoPassesImageContentSensor(photo: ImageSensorFields): boolean {
  if (photo.source === 'gemini') {
    return true;
  }

  const transcriptNorm = normalize(photo.transcript ?? '');
  const haystack = collectHaystack(photo);
  if (!haystack) {
    return true;
  }

  for (const phrase of BLOCKED_PHRASES) {
    const p = normalize(phrase);
    if (phraseHit(haystack, p) && !transcriptAllowsTerm(transcriptNorm, p)) {
      return false;
    }
  }

  for (const word of BLOCKED_WORDS) {
    if (wordHit(haystack, word) && !transcriptAllowsTerm(transcriptNorm, word)) {
      return false;
    }
  }

  for (const phrase of AESTHETIC_DRIFT_PHRASES) {
    const p = normalize(phrase);
    if (p.includes(' ')) {
      if (phraseHit(haystack, p) && !transcriptAllowsTerm(transcriptNorm, p)) {
        return false;
      }
    } else if (wordHit(haystack, p) && !transcriptAllowsTerm(transcriptNorm, p)) {
      return false;
    }
  }

  return true;
}

export function filterPhotosThroughImageContentSensor<T extends ImageSensorFields>(
  photos: T[],
  transcript: string
): T[] {
  const t = transcript.trim();
  return photos.filter((p) => photoPassesImageContentSensor({ ...p, transcript: t }));
}
