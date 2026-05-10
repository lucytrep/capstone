import React, { useEffect, useMemo, useState } from 'react';
import {
  StyleSheet,
  View,
  TouchableOpacity,
  SafeAreaView,
  Platform,
  ScrollView,
  useWindowDimensions,
} from 'react-native';
import { Image as ExpoImage } from 'expo-image';
import { WebView } from 'react-native-webview';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { AppText as Text } from '@/components/app-typography';
import { photoPassesImageContentSensor } from '@/constants/image-content-sensor';
import { PEXELS_API_KEY } from '@/config/keys';
import { matchTaggedGallery } from '@/data/tagged-gallery';
import { SessionStore } from '@/store/session';

const C = {
  bg: '#111111',
  bgCard: '#171614',
  amber: '#E8A87C',
  cream: '#F5F0E8',
  muted: '#6B6259',
  border: '#272320',
  savedGreen: '#7EC8A8',
};

type PaletteSwatch = {
  name: string;
  hex: string;
};

type PaletteOption = {
  id: string;
  swatches: PaletteSwatch[];
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

type PhotoOption = {
  id: string;
  displayMode?: 'image' | 'moodboard';
  source: 'pexels' | 'unsplash' | 'gemini' | 'pinterest' | 'mixed';
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

type EmbeddedPaletteOptions = {
  kind?: string;
  options?: {
    id?: string;
    swatches?: PaletteSwatch[];
  }[];
};

type EmbeddedPhotoOptions = {
  kind?: string;
  options?: {
    id?: string;
    displayMode?: 'image' | 'moodboard';
    source?: 'pexels' | 'unsplash' | 'gemini' | 'mixed';
    photos?: PhotoItem[];
  }[];
};

type EmbeddedUiOptions = {
  kind?: string;
  options?: UiOption[];
};

const WEBVIEW_BASE_STYLE = `
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      min-height: 100%;
      background: #111111;
      overflow-x: hidden;
      -webkit-text-size-adjust: 100%;
    }

    * {
      box-sizing: border-box;
      max-width: 100%;
    }

    img, svg, canvas, video {
      height: auto;
      max-width: 100%;
    }
  </style>
`;

function normalizeArtifactHtml(html: string) {
  const trimmed = html
    .trim()
    .replace(
      /<div[^>]*>\s*(?:<button[^>]*>.*?<\/button>\s*)?<span[^>]*>\s*Artifact\s*<\/span>[\s\S]*?<\/div>/i,
      ''
    );

  if (/<head[\s>]/i.test(trimmed)) {
    return trimmed.replace(/<head(\s[^>]*)?>/i, (match) => `${match}${WEBVIEW_BASE_STYLE}`);
  }

  if (/<html[\s>]/i.test(trimmed)) {
    return trimmed.replace(/<html(\s[^>]*)?>/i, (match) => `${match}<head>${WEBVIEW_BASE_STYLE}</head>`);
  }

  return `<!DOCTYPE html><html><head>${WEBVIEW_BASE_STYLE}</head><body>${trimmed}</body></html>`;
}

function getWebViewInjectionScript(isPaletteArtifact: boolean) {
  if (!isPaletteArtifact) {
    return `
      (function () {
        var artifactNode = Array.from(document.querySelectorAll('*')).find(function (node) {
          var text = (node.textContent || '').trim();
          return text === 'Artifact';
        });

        if (artifactNode) {
          var parent = artifactNode.parentElement;
          if (parent && parent instanceof HTMLElement) {
            parent.style.display = 'none';
          }
        }

        var track = Array.from(document.querySelectorAll('*')).find(function (node) {
          if (!(node instanceof HTMLElement)) {
            return false;
          }

          var hasOptionChildren = node.querySelector('[data-ui-option="1"]') && node.querySelector('[data-ui-option="2"]') && node.querySelector('[data-ui-option="3"]');
          var style = window.getComputedStyle(node);
          return Boolean(hasOptionChildren) && (style.overflowX === 'auto' || style.overflowX === 'scroll');
        });

        if (track instanceof HTMLElement) {
          var dots = Array.from(document.querySelectorAll('*')).filter(function (node) {
            if (!(node instanceof HTMLElement)) {
              return false;
            }

            var style = window.getComputedStyle(node);
            var width = parseFloat(style.width || '0');
            var height = parseFloat(style.height || '0');
            var radius = parseFloat(style.borderRadius || '0');
            return width >= 8 && width <= 24 && height >= 8 && height <= 12 && radius >= 4;
          }).slice(-3);

          var setActiveDot = function () {
            var pageWidth = track.clientWidth || window.innerWidth || 1;
            var index = Math.max(0, Math.min(2, Math.round(track.scrollLeft / pageWidth)));

            dots.forEach(function (dot, dotIndex) {
              if (!(dot instanceof HTMLElement)) {
                return;
              }

              dot.style.transition = 'all 160ms ease';
              dot.style.width = dotIndex === index ? '22px' : '10px';
              dot.style.opacity = dotIndex === index ? '1' : '0.5';
            });
          };

          setActiveDot();
          track.addEventListener('scroll', setActiveDot, { passive: true });
        }

        return true;
      })();
    `;
  }

  return `
    (function () {
      var html = document.documentElement;
      var body = document.body;
      var root = body && body.firstElementChild;

      var artifactNode = Array.from(document.querySelectorAll('*')).find(function (node) {
        var text = (node.textContent || '').trim();
        return text === 'Artifact';
      });

      if (artifactNode) {
        var parent = artifactNode.parentElement;
        if (parent && parent instanceof HTMLElement) {
          parent.style.display = 'none';
        }
      }

      var separators = Array.from(document.querySelectorAll('hr, [style*="border-bottom"], [style*="borderTop"], [style*="border-top"]'));
      separators.forEach(function (node) {
        if (node instanceof HTMLElement) {
          node.style.border = '0';
          node.style.borderBottom = '0';
          node.style.borderTop = '0';
        }
      });

      if (!body || !root) {
        return true;
      }

      html.style.height = '100%';
      body.style.height = '100%';
      body.style.minHeight = '100vh';
      body.style.overflowX = 'hidden';

      root.style.minHeight = '100vh';
      root.style.width = '100%';
      root.style.display = 'flex';
      root.style.flexDirection = 'column';
      root.style.justifyContent = 'space-between';
      root.style.paddingBottom = '120px';

      var children = Array.prototype.slice.call(root.children || []);
      children.forEach(function (child, index) {
        if (!(child instanceof HTMLElement)) {
          return;
        }

        child.style.width = child.style.width || '100%';

        if (index > 0) {
          child.style.flexShrink = '0';
        }
      });

      return true;
    })();
  `;
}

function parsePaletteSwatches(html: string): PaletteSwatch[] {
  const text = html
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<[^>]+>/g, '\n')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/\r/g, '')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);

  const swatches: PaletteSwatch[] = [];

  for (let i = 0; i < text.length - 1; i += 1) {
    const name = text[i];
    const maybeHex = text[i + 1]?.toUpperCase();

    if (!/^#[0-9A-F]{6}$/.test(maybeHex)) {
      continue;
    }

    if (/^draft$/i.test(name) || /^color palette$/i.test(name)) {
      continue;
    }

    swatches.push({ name, hex: maybeHex });

    if (swatches.length === 8) {
      break;
    }
  }

  return swatches;
}

function parseEmbeddedPaletteOptions(html: string): PaletteOption[] {
  const match = html.match(
    /<script id="draft-palette-options" type="application\/json">([\s\S]*?)<\/script>/i
  );

  if (!match?.[1]) {
    return [];
  }

  try {
    const parsed = JSON.parse(match[1]) as EmbeddedPaletteOptions;

    if (parsed.kind !== 'palette-options' || !Array.isArray(parsed.options)) {
      return [];
    }

    return parsed.options
      .map((option, index) => ({
        id: option.id || `palette-${index + 1}`,
        swatches: (option.swatches ?? []).filter(
          (swatch): swatch is PaletteSwatch =>
            Boolean(swatch?.name) && /^#[0-9A-Fa-f]{6}$/.test(swatch?.hex ?? '')
        ),
      }))
      .filter((option) => option.swatches.length >= 8);
  } catch (error) {
    console.error('Could not parse embedded palette options', error);
    return [];
  }
}

function parseEmbeddedPhotoOptions(html: string): PhotoOption[] {
  const match = html.match(
    /<script id="draft-photo-options" type="application\/json">([\s\S]*?)<\/script>/i
  );

  if (!match?.[1]) {
    return [];
  }

  try {
    const parsed = JSON.parse(match[1]) as EmbeddedPhotoOptions;

    if (parsed.kind !== 'photo-options' || !Array.isArray(parsed.options)) {
      return [];
    }

    return parsed.options
      .map((option, index) => ({
        id: option.id || `photos-${index + 1}`,
        displayMode: option.displayMode,
        source: option.source || 'mixed',
        photos: (option.photos ?? []).filter(
          (photo): photo is PhotoItem =>
            Boolean(photo?.id) &&
            Boolean(photo?.imageUrl) &&
            Boolean(photo?.thumbUrl) &&
            Boolean(photo?.alt)
        ),
      }))
      .filter((option) => option.photos.length >= 5);
  } catch (error) {
    console.error('Could not parse embedded photo options', error);
    return [];
  }
}

function parseEmbeddedUiOptions(html: string): UiOption[] {
  const match = html.match(
    /<script id="draft-ui-options" type="application\/json">([\s\S]*?)<\/script>/i
  );

  if (!match?.[1]) {
    return [];
  }

  try {
    const parsed = JSON.parse(match[1]) as EmbeddedUiOptions;

    if (parsed.kind !== 'ui-options' || !Array.isArray(parsed.options)) {
      return [];
    }

    return parsed.options.filter(
      (option): option is UiOption =>
        Boolean(option?.id) &&
        Boolean(option?.label) &&
        Boolean(option?.headline) &&
        Boolean(option?.supportingText) &&
        Boolean(option?.accent) &&
        Boolean(option?.background)
    );
  } catch (error) {
    console.error('Could not parse embedded UI options', error);
    return [];
  }
}

function getContrastColor(hex: string) {
  const normalized = hex.replace('#', '');
  const r = parseInt(normalized.slice(0, 2), 16);
  const g = parseInt(normalized.slice(2, 4), 16);
  const b = parseInt(normalized.slice(4, 6), 16);
  const luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
  return luminance > 0.62 ? '#111111' : '#F5F0E8';
}

function hexToRgb(hex: string) {
  const normalized = hex.replace('#', '');
  return {
    r: parseInt(normalized.slice(0, 2), 16),
    g: parseInt(normalized.slice(2, 4), 16),
    b: parseInt(normalized.slice(4, 6), 16),
  };
}

function rgbToHex(r: number, g: number, b: number) {
  return `#${[r, g, b]
    .map((value) => Math.max(0, Math.min(255, Math.round(value))).toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase()}`;
}

function rgbToHsl(r: number, g: number, b: number) {
  const red = r / 255;
  const green = g / 255;
  const blue = b / 255;
  const max = Math.max(red, green, blue);
  const min = Math.min(red, green, blue);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

    switch (max) {
      case red:
        h = (green - blue) / d + (green < blue ? 6 : 0);
        break;
      case green:
        h = (blue - red) / d + 2;
        break;
      default:
        h = (red - green) / d + 4;
        break;
    }

    h /= 6;
  }

  return { h, s, l };
}

function hueToRgb(p: number, q: number, t: number) {
  let temp = t;
  if (temp < 0) temp += 1;
  if (temp > 1) temp -= 1;
  if (temp < 1 / 6) return p + (q - p) * 6 * temp;
  if (temp < 1 / 2) return q;
  if (temp < 2 / 3) return p + (q - p) * (2 / 3 - temp) * 6;
  return p;
}

function hslToRgb(h: number, s: number, l: number) {
  if (s === 0) {
    const gray = l * 255;
    return { r: gray, g: gray, b: gray };
  }

  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;

  return {
    r: hueToRgb(p, q, h + 1 / 3) * 255,
    g: hueToRgb(p, q, h) * 255,
    b: hueToRgb(p, q, h - 1 / 3) * 255,
  };
}

function shiftColor(hex: string, hueShift: number, saturationShift: number, lightnessShift: number) {
  const { r, g, b } = hexToRgb(hex);
  const { h, s, l } = rgbToHsl(r, g, b);
  const shiftedHue = (h + hueShift + 1) % 1;
  const shiftedSaturation = Math.max(0, Math.min(1, s + saturationShift));
  const shiftedLightness = Math.max(0.08, Math.min(0.9, l + lightnessShift));
  const shifted = hslToRgb(shiftedHue, shiftedSaturation, shiftedLightness);
  return rgbToHex(shifted.r, shifted.g, shifted.b);
}

function buildPaletteOptions(swatches: PaletteSwatch[]): PaletteOption[] {
  if (swatches.length < 8) {
    return [];
  }

  const base = swatches.slice(0, 8);
  const editable = base.slice(0, 6);
  const fixed = base.slice(6);

  const warm = editable.map((swatch, index) => ({
    ...swatch,
    hex: shiftColor(
      swatch.hex,
      0.06 + index * 0.005,
      0.08,
      index === 0 ? -0.02 : 0.03
    ),
  }));

  const fresh = editable.map((swatch, index) => ({
    ...swatch,
    hex: shiftColor(
      swatch.hex,
      -0.11 + index * 0.004,
      -0.02,
      index % 2 === 0 ? 0.09 : 0.04
    ),
  }));

  return [
    { id: 'palette-1', swatches: [...base] },
    { id: 'palette-2', swatches: [...warm, ...fixed] },
    { id: 'palette-3', swatches: [...fresh, ...fixed] },
  ];
}

function PaletteSwatchCard({
  swatch,
  width,
  height,
}: {
  swatch: PaletteSwatch;
  width: number;
  height: number;
}) {
  const textColor = getContrastColor(swatch.hex);

  return (
    <View
      style={[
        styles.paletteSwatch,
        {
          width,
          height,
          backgroundColor: swatch.hex,
        },
      ]}
    >
      <View style={styles.paletteSwatchTextWrap}>
        <Text style={[styles.paletteSwatchName, { color: textColor }]} numberOfLines={2}>
          {swatch.name}
        </Text>
        <Text style={[styles.paletteSwatchHex, { color: textColor }]}>{swatch.hex}</Text>
      </View>
    </View>
  );
}

function PhotoTile({
  photo,
  width,
  height,
  highlighted = false,
}: {
  photo: PhotoItem;
  width: number;
  height: number;
  highlighted?: boolean;
}) {
  return (
    <View style={[styles.photoTile, highlighted && styles.photoTileHighlighted, { width, height }]}>
      <ExpoImage
        source={photo.imageUrl}
        style={styles.photoImage}
        contentFit="cover"
        transition={150}
      />
      <View style={styles.photoOverlay} />
      <View style={styles.photoMeta}>
        <Text style={styles.photoAuthor} numberOfLines={2}>
          {getPhotoLabel(photo)}
        </Text>
      </View>
    </View>
  );
}

function getPhotoLabel(photo: PhotoItem) {
  const raw = (photo.alt || photo.author || '')
    .replace(/[-_]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (!raw) {
    return 'Inspiration';
  }

  const genericPhrases = [
    'pexels inspiration image',
    'unsplash inspiration image',
    'gemini generated inspiration image',
  ];
  const lowered = raw.toLowerCase();

  if (genericPhrases.includes(lowered)) {
    return 'Inspiration';
  }

  const cleaned = raw
    .replace(/\b(photo|image|editorial|moodboard|generated|inspiration)\b/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const words = (cleaned || raw).split(' ').filter(Boolean).slice(0, 2);
  return words.length > 0
    ? words.map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
    : 'Inspiration';
}

function BottomNavPill({ onMicPress }: { onMicPress: () => void }) {
  return (
    <View style={styles.photoNavWrap}>
      <View style={styles.photoNavPill}>
        <TouchableOpacity
          onPress={onMicPress}
          style={styles.photoNavIcon}
          activeOpacity={0.8}
          hitSlop={10}
        >
          <Feather name="mic" size={22} color={C.cream} />
        </TouchableOpacity>
        <View style={styles.photoNavIcon}>
          <Feather name="bar-chart-2" size={22} color={C.cream} />
        </View>
      </View>
    </View>
  );
}

type MoodPhoto = {
  id: string;
  /** Remote URL (string) or bundled asset module id from `require()` */
  source: string | number;
  alt: string;
};

type ArenaChannel = {
  id: string;
  title: string;
  thumbUrl: string;
};

function extractMoodKeywords(transcript: string): string {
  return transcript
    .replace(
      /\b(a|an|the|and|or|but|in|on|at|to|for|of|with|i|me|my|we|please|help|show|make|create|build|give|find|generate|design|get|need|want|can|you|some|us|this|that|images?|photos?|imagery|moodboard|references?)\b/gi,
      ' '
    )
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .split(' ')
    .filter((w) => w.length > 2)
    .slice(0, 3)
    .join(' ');
}

function useMoodImages(transcript: string) {
  const [pexelsPhotos, setPexelsPhotos] = useState<MoodPhoto[]>([]);
  const [arenaChannels, setArenaChannels] = useState<ArenaChannel[]>([]);

  useEffect(() => {
    if (!transcript.trim()) return;
    const keywords = extractMoodKeywords(transcript);
    if (!keywords) return;
    let cancelled = false;

    if (PEXELS_API_KEY) {
      fetch(
        `https://api.pexels.com/v1/search?query=${encodeURIComponent(keywords)}&per_page=6&orientation=portrait`,
        { headers: { Authorization: PEXELS_API_KEY } }
      )
        .then((r) => r.json())
        .then(
          (data: {
            photos?: Array<{
              id?: number;
              alt?: string;
              src?: { medium?: string; large?: string };
            }>;
          }) => {
            if (cancelled) return;
            const photos = (data.photos ?? [])
              .map((p): MoodPhoto | null => {
                const url = p.src?.medium || p.src?.large;
                if (!p.id || !url) return null;
                return { id: `pm-${p.id}`, source: url, alt: p.alt || '' };
              })
              .filter((p): p is MoodPhoto => p !== null)
              .filter((p) =>
                photoPassesImageContentSensor({
                  alt: p.alt,
                  imageUrl: typeof p.source === 'string' ? p.source : '',
                  transcript: transcript.trim(),
                })
              );
            setPexelsPhotos(photos);
          }
        )
        .catch(() => {});
    }

    fetch(`https://api.are.na/v2/search/channels?q=${encodeURIComponent(keywords)}&per=4`)
      .then((r) => r.json())
      .then(
        (data: {
          channels?: Array<{
            id?: number;
            title?: string;
            image?: {
              display?: { url?: string };
              square?: { url?: string };
              thumb?: { url?: string };
            };
          }>;
        }) => {
          if (cancelled) return;
          const channels = (data.channels ?? [])
            .map((c) => {
              const thumbUrl =
                c.image?.display?.url || c.image?.square?.url || c.image?.thumb?.url;
              if (!c.id || !c.title || !thumbUrl) return null;
              return { id: `arena-${c.id}`, title: c.title, thumbUrl };
            })
            .filter((c): c is ArenaChannel => c !== null)
            .filter((c) =>
              photoPassesImageContentSensor({
                alt: c.title,
                imageUrl: c.thumbUrl,
                transcript: transcript.trim(),
              })
            );
          setArenaChannels(channels);
        }
      )
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, [transcript]);

  return { pexelsPhotos, arenaChannels };
}

function MoodImageRows({ transcript }: { transcript: string }) {
  const { pexelsPhotos, arenaChannels } = useMoodImages(transcript);

  const taggedPhotos = useMemo(
    () =>
      matchTaggedGallery(transcript).map((entry) => ({
        id: entry.id,
        source: entry.imageModule,
        alt: entry.alt,
      })),
    [transcript]
  );

  const moodPhotos = useMemo(() => {
    const seen = new Set<string>();
    const merged: MoodPhoto[] = [];
    for (const photo of [...taggedPhotos, ...pexelsPhotos]) {
      if (seen.has(photo.id)) continue;
      seen.add(photo.id);
      merged.push(photo);
    }
    return merged;
  }, [taggedPhotos, pexelsPhotos]);

  if (moodPhotos.length === 0 && arenaChannels.length === 0) {
    return null;
  }

  return (
    <View style={styles.moodSection}>
      {moodPhotos.length > 0 && (
        <View style={styles.moodGroup}>
          <Text style={styles.moodLabel}>Mood</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.moodScrollContent}
          >
            {moodPhotos.map((photo) => (
              <View key={photo.id} style={styles.moodPhotoTile}>
                <ExpoImage
                  source={photo.source}
                  style={styles.moodTileImage}
                  contentFit="cover"
                  transition={200}
                  accessibilityLabel={photo.alt}
                />
              </View>
            ))}
          </ScrollView>
        </View>
      )}
      {arenaChannels.length > 0 && (
        <View style={styles.moodGroup}>
          <Text style={styles.moodLabel}>References</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.moodScrollContent}
          >
            {arenaChannels.map((channel) => (
              <View key={channel.id} style={styles.moodChannelTile}>
                <ExpoImage
                  source={channel.thumbUrl}
                  style={styles.moodTileImage}
                  contentFit="cover"
                  transition={200}
                />
                <View style={styles.moodChannelOverlay} />
                <Text style={styles.moodChannelTitle} numberOfLines={2}>
                  {channel.title}
                </Text>
              </View>
            ))}
          </ScrollView>
        </View>
      )}
    </View>
  );
}

function NativeUiOptionCard({ option }: { option: UiOption }) {
  return (
    <View
      style={[
        styles.nativeUiCard,
        {
          backgroundColor: option.background,
          borderColor: option.direction === 'bold' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)',
        },
      ]}
    >
      <View style={styles.nativeUiCardHeader}>
        <View>
          <Text style={[styles.nativeUiProduct, { color: option.text }]}>{option.productName}</Text>
        </View>
        <View style={[styles.nativeUiStatusChip, { backgroundColor: option.mutedSurface }]}>
          <Text style={[styles.nativeUiStatusText, { color: option.text }]}>Concept</Text>
        </View>
      </View>

      {option.direction === 'editorial' ? (
        <>
          <View style={[styles.nativeUiHeroSplit, { backgroundColor: option.surface }]}>
            <View style={styles.nativeUiSplitCopy}>
              <Text style={[styles.nativeUiHeadline, { color: option.text }]}>{option.headline}</Text>
              <Text style={[styles.nativeUiSupport, { color: option.mutedText }]}>
                {option.supportingText}
              </Text>
            </View>
            <View style={[styles.nativeUiPreviewTall, { backgroundColor: option.accent }]} />
          </View>
          <View style={styles.nativeUiDualRow}>
            <View style={[styles.nativeUiSmallCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPill, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiMiniBlock, { backgroundColor: option.accent }]} />
            </View>
            <View style={[styles.nativeUiSmallCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPillWide, { backgroundColor: option.mutedSurface }]} />
              <View style={styles.nativeUiMiniRow}>
                <View style={[styles.nativeUiMiniTile, { backgroundColor: option.mutedSurface }]} />
                <View style={[styles.nativeUiMiniTile, { backgroundColor: option.mutedSurface, opacity: 0.72 }]} />
              </View>
            </View>
          </View>
          <View style={[styles.nativeUiFooterCard, { backgroundColor: option.surface }]}>
            <Text style={[styles.nativeUiFooterHeadline, { color: option.text }]}>{option.primaryCta}</Text>
            <View style={styles.nativeUiFooterRow}>
              <View style={[styles.nativeUiFooterTile, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiFooterTile, { backgroundColor: option.mutedSurface, opacity: 0.82 }]} />
              <View style={[styles.nativeUiFooterTile, { backgroundColor: option.accent, opacity: 0.92 }]} />
            </View>
          </View>
        </>
      ) : option.direction === 'minimal' ? (
        <>
          <View style={[styles.nativeUiCenteredHero, { backgroundColor: option.surface }]}>
            <Text style={[styles.nativeUiHeadlineCenter, { color: option.text }]}>{option.headline}</Text>
            <Text style={[styles.nativeUiSupportCenter, { color: option.mutedText }]}>
              {option.supportingText}
            </Text>
            <View style={styles.nativeUiCtaRow}>
              <View style={[styles.nativeUiPrimaryCta, { backgroundColor: option.accent }]}>
                <Text style={styles.nativeUiPrimaryCtaText}>{option.primaryCta}</Text>
              </View>
              <View style={[styles.nativeUiSecondaryCta, { borderColor: option.mutedSurface }]}>
                <Text style={[styles.nativeUiSecondaryCtaText, { color: option.text }]}>
                  {option.secondaryCta}
                </Text>
              </View>
            </View>
          </View>
          <View style={styles.nativeUiTripleRow}>
            <View style={[styles.nativeUiColumnCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPill, { backgroundColor: option.accent, opacity: 0.22 }]} />
              <View style={[styles.nativeUiColumnBlock, { backgroundColor: option.mutedSurface }]} />
            </View>
            <View style={[styles.nativeUiColumnCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPill, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiColumnBlock, { backgroundColor: option.accent, opacity: 0.9 }]} />
            </View>
            <View style={[styles.nativeUiColumnCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPill, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiColumnBlock, { backgroundColor: option.mutedSurface, opacity: 0.78 }]} />
            </View>
          </View>
          <View style={[styles.nativeUiFooterCard, { backgroundColor: option.surface }]}>
            <View style={styles.nativeUiFooterRow}>
              <View style={[styles.nativeUiFooterWide, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiFooterShort, { backgroundColor: option.accent, opacity: 0.18 }]} />
            </View>
            <View style={[styles.nativeUiLine, { backgroundColor: option.mutedSurface }]} />
            <View style={[styles.nativeUiLineShort, { backgroundColor: option.mutedSurface, opacity: 0.72 }]} />
          </View>
        </>
      ) : (
        <>
          <View style={styles.nativeUiBoldTopRow}>
            <View style={[styles.nativeUiBoldPanelLarge, { backgroundColor: option.surface }]}>
              <Text style={[styles.nativeUiHeadline, { color: option.text }]}>{option.headline}</Text>
              <View style={[styles.nativeUiAccentPill, { backgroundColor: option.accent }]} />
            </View>
            <View style={[styles.nativeUiBoldPanelTall, { backgroundColor: option.accent }]}>
              <View style={[styles.nativeUiMiniDot, { backgroundColor: option.surface }]} />
            </View>
          </View>
          <View style={[styles.nativeUiBoldBanner, { backgroundColor: option.surface }]}>
            <Text style={[styles.nativeUiSupport, { color: option.mutedText }]}>{option.supportingText}</Text>
            <View style={styles.nativeUiMiniRow}>
              <View style={[styles.nativeUiMiniTile, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiMiniTile, { backgroundColor: option.mutedSurface, opacity: 0.75 }]} />
              <View style={[styles.nativeUiMiniTile, { backgroundColor: option.mutedSurface, opacity: 0.58 }]} />
            </View>
          </View>
          <View style={styles.nativeUiDualRow}>
            <View style={[styles.nativeUiSmallCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPillWide, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiColumnBlock, { backgroundColor: option.accent, opacity: 0.92 }]} />
            </View>
            <View style={[styles.nativeUiSmallCard, { backgroundColor: option.surface }]}>
              <View style={[styles.nativeUiMiniPill, { backgroundColor: option.mutedSurface }]} />
              <View style={[styles.nativeUiColumnBlock, { backgroundColor: option.mutedSurface }]} />
            </View>
          </View>
          <View style={styles.nativeUiCtaRow}>
            <View style={[styles.nativeUiPrimaryCta, { backgroundColor: option.accent }]}>
              <Text style={styles.nativeUiPrimaryCtaText}>{option.primaryCta}</Text>
            </View>
            <View style={[styles.nativeUiSecondaryCta, { borderColor: option.mutedSurface }]}>
              <Text style={[styles.nativeUiSecondaryCtaText, { color: option.text }]}>{option.secondaryCta}</Text>
            </View>
          </View>
        </>
      )}
    </View>
  );
}

export default function OutputScreen() {
  const [activePaletteIndex, setActivePaletteIndex] = useState(0);
  const [sessionReady, setSessionReady] = useState(false);
  const { width, height } = useWindowDimensions();

  useEffect(() => {
    let cancelled = false;

    SessionStore.hydrate().finally(() => {
      if (!cancelled) {
        setSessionReady(true);
      }
    });

    return () => {
      cancelled = true;
    };
  }, []);

  const artifactHtml = sessionReady ? SessionStore.getArtifact() : '';
  const transcript = sessionReady ? SessionStore.getTranscript() : '';
  const renderedHtml = normalizeArtifactHtml(artifactHtml);
  const uiOptions = useMemo(() => parseEmbeddedUiOptions(artifactHtml), [artifactHtml]);
  const canRenderNativeUi = uiOptions.length === 3;
  const isPaletteArtifact =
    !canRenderNativeUi &&
    (/color palette/i.test(artifactHtml) || /\bpalette\b/i.test(transcript));
  const isPhotoArtifact =
    !canRenderNativeUi &&
    (/<script id="draft-photo-options"/i.test(artifactHtml) ||
      /(photos|imagery|art direction|moodboard|reference images?)/i.test(transcript));
  const injectedJavaScript = getWebViewInjectionScript(isPaletteArtifact);
  const paletteSwatches = useMemo(() => parsePaletteSwatches(artifactHtml), [artifactHtml]);
  const embeddedPaletteOptions = useMemo(
    () => parseEmbeddedPaletteOptions(artifactHtml),
    [artifactHtml]
  );
  const photoOptions = useMemo(() => parseEmbeddedPhotoOptions(artifactHtml), [artifactHtml]);
  const paletteOptions = useMemo(
    () =>
      embeddedPaletteOptions.length > 0
        ? embeddedPaletteOptions
        : buildPaletteOptions(paletteSwatches),
    [embeddedPaletteOptions, paletteSwatches]
  );
  const canRenderNativePalette = isPaletteArtifact && paletteOptions.length === 3;
  const canRenderNativePhotos = isPhotoArtifact && photoOptions.length > 0;

  console.log('[OutputScreen] artifactHtml length:', artifactHtml?.length ?? 0);
  console.log('[OutputScreen] artifactHtml preview:', artifactHtml?.slice(0, 200));

  const handleNew = () => {
    SessionStore.clear();
    router.replace('/(tabs)');
  };

  const handleApprove = () => {
    SessionStore.clear();
    router.replace('/(tabs)');
  };

  if (!sessionReady) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.empty}>
          <Text style={styles.emptyText}>Restoring your draft...</Text>
          <Text style={styles.emptySubtext}>Hang tight while we recover the latest session.</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!artifactHtml || artifactHtml.trim().length === 0) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.empty}>
          <Text style={styles.emptyText}>No artifact to display.</Text>
          <Text style={styles.emptySubtext}>The response may have been empty or malformed.</Text>
          <TouchableOpacity onPress={handleNew} style={styles.newButtonSmall}>
            <Text style={styles.newButtonSmallText}>Try again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  if (canRenderNativePalette) {
    const gutter = 16;
    const gap = 8;
    const contentWidth = width - gutter * 2;
    const largeWidth = contentWidth;
    const leftMediumWidth = Math.floor((contentWidth - gap) * 0.66);
    const rightMediumWidth = contentWidth - gap - leftMediumWidth;
    const smallWidth = Math.floor((contentWidth - gap * 2) / 3);
    const bottomWidth = Math.floor((contentWidth - gap) / 2);

    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.nativePaletteScreen}>
          <View style={styles.nativePaletteTopBar}>
            <TouchableOpacity onPress={handleNew} style={styles.backButton} hitSlop={12}>
              <Feather name="arrow-left" size={18} color={C.cream} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.moodOuterScroll} showsVerticalScrollIndicator={false} bounces={false}>
            <ScrollView
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              decelerationRate="fast"
              snapToInterval={width}
              snapToAlignment="start"
              disableIntervalMomentum
              directionalLockEnabled
              bounces={false}
              onScroll={(event) => {
                const nextIndex = Math.round(
                  event.nativeEvent.contentOffset.x / Math.max(width, 1)
                );
                setActivePaletteIndex(nextIndex);
              }}
              scrollEventThrottle={16}
              contentContainerStyle={styles.palettePagerContent}
            >
              {paletteOptions.map((option) => (
                <View key={option.id} style={[styles.palettePage, { width }]}>
                  <View style={styles.paletteHeading}>
                    <Text style={styles.paletteTitle}>Draft</Text>
                    <Text style={styles.paletteSubtitle}>Color Palette</Text>
                  </View>

                  <View style={styles.paletteRows}>
                    <PaletteSwatchCard swatch={option.swatches[0]} width={largeWidth} height={146} />

                    <View style={styles.paletteRow}>
                      <PaletteSwatchCard
                        swatch={option.swatches[1]}
                        width={leftMediumWidth}
                        height={138}
                      />
                      <PaletteSwatchCard
                        swatch={option.swatches[2]}
                        width={rightMediumWidth}
                        height={138}
                      />
                    </View>

                    <View style={styles.paletteRow}>
                      <PaletteSwatchCard
                        swatch={option.swatches[3]}
                        width={smallWidth}
                        height={106}
                      />
                      <PaletteSwatchCard
                        swatch={option.swatches[4]}
                        width={smallWidth}
                        height={106}
                      />
                      <PaletteSwatchCard
                        swatch={option.swatches[5]}
                        width={smallWidth}
                        height={106}
                      />
                    </View>

                    <View style={styles.paletteRow}>
                      <PaletteSwatchCard
                        swatch={option.swatches[6]}
                        width={bottomWidth}
                        height={132}
                      />
                      <PaletteSwatchCard
                        swatch={option.swatches[7]}
                        width={bottomWidth}
                        height={132}
                      />
                    </View>
                  </View>
                </View>
              ))}
            </ScrollView>

            <View style={styles.paginationDots}>
              {paletteOptions.map((option, index) => (
                <View
                  key={option.id}
                  style={[
                    styles.paginationDot,
                    index === activePaletteIndex && styles.paginationDotActive,
                  ]}
                />
              ))}
            </View>
            <MoodImageRows transcript={transcript} />
          </ScrollView>

          <BottomNavPill onMicPress={handleNew} />
        </View>
      </SafeAreaView>
    );
  }

  if (canRenderNativeUi) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.nativePhotoScreen}>
          <View style={styles.nativePhotoTopBar}>
            <View style={styles.photoHeadingWrap}>
              <Text style={styles.photoScreenTitle}>Draft</Text>
              <Text style={styles.photoScreenSubtitle}>UI</Text>
            </View>

            <View style={styles.photoActions}>
              <TouchableOpacity onPress={handleNew} style={styles.photoActionButton} hitSlop={12}>
                <Feather name="x" size={18} color={C.cream} />
              </TouchableOpacity>
              <TouchableOpacity onPress={handleApprove} style={styles.photoActionButton} hitSlop={12}>
                <Feather name="check" size={18} color={C.cream} />
              </TouchableOpacity>
            </View>
          </View>

          <ScrollView style={styles.moodOuterScroll} showsVerticalScrollIndicator={false} bounces={false}>
            <ScrollView
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              decelerationRate="fast"
              snapToInterval={width}
              snapToAlignment="start"
              disableIntervalMomentum
              directionalLockEnabled
              bounces={false}
              onScroll={(event) => {
                const nextIndex = Math.round(
                  event.nativeEvent.contentOffset.x / Math.max(width, 1)
                );
                setActivePaletteIndex(nextIndex);
              }}
              scrollEventThrottle={16}
            >
              {uiOptions.map((option) => (
                <View key={option.id} style={[styles.photoPage, { width }]}>
                  <NativeUiOptionCard option={option} />
                </View>
              ))}
            </ScrollView>

            <View style={styles.photoPaginationDots}>
              {uiOptions.map((option, index) => (
                <View
                  key={option.id}
                  style={[
                    styles.photoPaginationDot,
                    index === activePaletteIndex && styles.photoPaginationDotActive,
                  ]}
                />
              ))}
            </View>
            <MoodImageRows transcript={transcript} />
          </ScrollView>

          <BottomNavPill onMicPress={handleNew} />
        </View>
      </SafeAreaView>
    );
  }

  if (canRenderNativePhotos) {
    const gutter = 18;
    const gap = 10;
    const contentWidth = width - gutter * 2;
    const heroWidth = contentWidth;
    const smallWidth = Math.floor((contentWidth - gap) / 2);
    const tripleWidth = Math.floor((contentWidth - gap * 2) / 3);
    const availablePhotoHeight = Math.max(520, height - 250);
    const heroHeight = Math.min(300, Math.max(236, availablePhotoHeight * 0.38));
    const smallHeight = Math.min(172, Math.max(136, availablePhotoHeight * 0.24));
    const bottomRowHeight = Math.min(190, Math.max(140, availablePhotoHeight * 0.27));

    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.nativePhotoScreen}>
          <View style={styles.nativePhotoTopBar}>
            <View style={styles.photoHeadingWrap}>
              <Text style={styles.photoScreenTitle}>Draft</Text>
              <Text style={styles.photoScreenSubtitle}>
                {photoOptions[0]?.displayMode === 'moodboard' ? 'Moodboard' : 'Image Gathering'}
              </Text>
            </View>

            <View style={styles.photoActions}>
              <TouchableOpacity onPress={handleNew} style={styles.photoActionButton} hitSlop={12}>
                <Feather name="x" size={18} color={C.cream} />
              </TouchableOpacity>
              <TouchableOpacity onPress={handleApprove} style={styles.photoActionButton} hitSlop={12}>
                <Feather name="check" size={18} color={C.cream} />
              </TouchableOpacity>
            </View>
          </View>

          <ScrollView style={styles.moodOuterScroll} showsVerticalScrollIndicator={false} bounces={false}>
            <ScrollView
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              decelerationRate="fast"
              snapToInterval={width}
              snapToAlignment="start"
              disableIntervalMomentum
              directionalLockEnabled
              bounces={false}
              onScroll={(event) => {
                const nextIndex = Math.round(
                  event.nativeEvent.contentOffset.x / Math.max(width, 1)
                );
                setActivePaletteIndex(nextIndex);
              }}
              scrollEventThrottle={16}
              contentContainerStyle={styles.photoPagerContent}
            >
              {photoOptions.map((option, optionIndex) => (
                <View key={option.id} style={[styles.photoPage, { width }]}>
                  <View style={styles.photoRows}>
                    <PhotoTile photo={option.photos[0]} width={heroWidth} height={heroHeight} />

                    <View style={styles.photoRow}>
                      <PhotoTile photo={option.photos[1]} width={smallWidth} height={smallHeight} />
                      <PhotoTile photo={option.photos[2]} width={smallWidth} height={smallHeight} />
                    </View>

                    <View style={styles.photoRow}>
                      <PhotoTile
                        photo={option.photos[3]}
                        width={tripleWidth}
                        height={bottomRowHeight}
                        highlighted={optionIndex === 0}
                      />
                      <PhotoTile photo={option.photos[4]} width={tripleWidth} height={bottomRowHeight} />
                      {option.photos[5] ? (
                        <PhotoTile photo={option.photos[5]} width={tripleWidth} height={bottomRowHeight} />
                      ) : (
                        <View
                          style={[
                            styles.photoTile,
                            { width: tripleWidth, height: bottomRowHeight, backgroundColor: '#1C1C1C' },
                          ]}
                        />
                      )}
                    </View>
                  </View>
                </View>
              ))}
            </ScrollView>

            <View style={styles.photoPaginationDots}>
              {photoOptions.map((option, index) => (
                <View
                  key={option.id}
                  style={[
                    styles.photoPaginationDot,
                    index === activePaletteIndex && styles.photoPaginationDotActive,
                  ]}
                />
              ))}
            </View>
            <MoodImageRows transcript={transcript} />
          </ScrollView>

          <BottomNavPill onMicPress={handleNew} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.fullscreenWebView}>
        <WebView
          style={styles.embeddedWebView}
          source={{ html: renderedHtml, baseUrl: '' }}
          originWhitelist={['*']}
          javaScriptEnabled={true}
          domStorageEnabled={true}
          scrollEnabled
          bounces={false}
          injectedJavaScript={injectedJavaScript}
          onError={(e) => console.error('[WebView error]', e.nativeEvent)}
          onHttpError={(e) => console.error('[WebView HTTP error]', e.nativeEvent)}
        />
      </View>

      <BottomNavPill onMicPress={handleNew} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  fullscreenWebView: {
    flex: 1,
    backgroundColor: C.bg,
  },
  embeddedWebView: {
    flex: 1,
    backgroundColor: '#000000',
  },
  nativePaletteScreen: {
    flex: 1,
    backgroundColor: '#000000',
  },
  nativePaletteTopBar: {
    paddingTop: Platform.OS === 'ios' ? 8 : 16,
    paddingBottom: 8,
    paddingHorizontal: 16,
  },
  backButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.06)',
  },
  nativePaletteContent: {
    flex: 1,
    justifyContent: 'flex-start',
  },
  paletteHeading: {
    marginBottom: 16,
  },
  palettePagerContent: {
    alignItems: 'stretch',
  },
  palettePage: {
    paddingHorizontal: 16,
  },
  paletteTitle: {
    color: '#FFFFFF',
    fontSize: 26,
    fontWeight: '700',
    lineHeight: 31,
  },
  paletteSubtitle: {
    color: '#7A7A7A',
    fontSize: 16,
    marginTop: 2,
  },
  paletteRows: {
    gap: 8,
  },
  paginationDots: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingTop: 14,
  },
  paginationDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: 'rgba(255,255,255,0.18)',
  },
  paginationDotActive: {
    width: 22,
    backgroundColor: 'rgba(255,255,255,0.62)',
  },
  paletteRow: {
    flexDirection: 'row',
    gap: 8,
  },
  paletteSwatch: {
    borderRadius: 25,
    overflow: 'hidden',
    justifyContent: 'flex-end',
    padding: 14,
  },
  paletteSwatchTextWrap: {
    gap: 2,
  },
  paletteSwatchName: {
    fontSize: 13,
    fontWeight: '700',
    lineHeight: 16,
  },
  paletteSwatchHex: {
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 15,
  },
  photoTile: {
    borderRadius: 21,
    overflow: 'hidden',
    backgroundColor: '#1C1C1C',
  },
  photoTileHighlighted: {
    borderWidth: 2,
    borderColor: '#7C4DFF',
  },
  photoOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.24)',
  },
  photoMeta: {
    position: 'absolute',
    left: 12,
    right: 12,
    bottom: 12,
    gap: 2,
  },
  photoSourceLabel: {
    color: 'rgba(255,255,255,0.78)',
    fontSize: 10,
    fontWeight: '600',
    letterSpacing: 0.4,
    textTransform: 'uppercase',
  },
  photoAuthor: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
    lineHeight: 17,
  },
  photoImage: {
    width: '100%',
    height: '100%',
  },
  nativePhotoScreen: {
    flex: 1,
    backgroundColor: '#000000',
  },
  nativePhotoTopBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingTop: Platform.OS === 'ios' ? 2 : 12,
    paddingHorizontal: 18,
    paddingBottom: 8,
  },
  photoHeadingWrap: {
    gap: 0,
  },
  photoScreenTitle: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '700',
    lineHeight: 32,
  },
  photoScreenSubtitle: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: '300',
    lineHeight: 28,
  },
  photoActions: {
    flexDirection: 'row',
    gap: 10,
    paddingTop: 8,
  },
  photoActionButton: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.16)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  nativePhotoContent: {
    flex: 1,
    justifyContent: 'flex-start',
  },
  photoPagerContent: {
    alignItems: 'stretch',
  },
  photoPage: {
    paddingHorizontal: 18,
    justifyContent: 'flex-start',
  },
  photoRows: {
    gap: 10,
  },
  photoRow: {
    flexDirection: 'row',
    gap: 10,
  },
  nativeUiCard: {
    height: 590,
    borderRadius: 34,
    padding: 18,
    borderWidth: 1,
    gap: 12,
    overflow: 'hidden',
  },
  nativeUiCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  nativeUiProduct: {
    fontSize: 27,
    lineHeight: 31,
    fontWeight: '700',
    maxWidth: '78%',
  },
  nativeUiStatusChip: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
  },
  nativeUiStatusText: {
    fontSize: 12,
    fontWeight: '600',
  },
  nativeUiHeroSplit: {
    flexDirection: 'row',
    gap: 12,
    borderRadius: 28,
    padding: 18,
    minHeight: 190,
  },
  nativeUiSplitCopy: {
    flex: 1.2,
    justifyContent: 'space-between',
  },
  nativeUiPreviewTall: {
    width: 96,
    borderRadius: 24,
  },
  nativeUiHeadline: {
    fontSize: 28,
    lineHeight: 30,
    fontWeight: '700',
  },
  nativeUiSupport: {
    fontSize: 14,
    lineHeight: 20,
    fontWeight: '500',
  },
  nativeUiDualRow: {
    flexDirection: 'row',
    gap: 12,
  },
  nativeUiSmallCard: {
    flex: 1,
    minHeight: 116,
    borderRadius: 24,
    padding: 16,
    justifyContent: 'space-between',
  },
  nativeUiMiniPill: {
    width: 34,
    height: 12,
    borderRadius: 999,
  },
  nativeUiMiniPillWide: {
    width: 58,
    height: 10,
    borderRadius: 999,
  },
  nativeUiMiniBlock: {
    height: 52,
    borderRadius: 18,
  },
  nativeUiMiniRow: {
    flexDirection: 'row',
    gap: 8,
  },
  nativeUiMiniTile: {
    flex: 1,
    height: 44,
    borderRadius: 16,
  },
  nativeUiFooterCard: {
    flex: 1,
    borderRadius: 28,
    padding: 18,
    justifyContent: 'space-between',
  },
  nativeUiFooterHeadline: {
    fontSize: 16,
    lineHeight: 20,
    fontWeight: '700',
  },
  nativeUiFooterRow: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
  },
  nativeUiFooterTile: {
    flex: 1,
    height: 76,
    borderRadius: 18,
  },
  nativeUiCenteredHero: {
    borderRadius: 28,
    padding: 24,
    minHeight: 224,
    alignItems: 'center',
    justifyContent: 'center',
  },
  nativeUiHeadlineCenter: {
    fontSize: 30,
    lineHeight: 33,
    fontWeight: '700',
    textAlign: 'center',
  },
  nativeUiSupportCenter: {
    marginTop: 12,
    fontSize: 14,
    lineHeight: 20,
    fontWeight: '500',
    textAlign: 'center',
    maxWidth: '90%',
  },
  nativeUiCtaRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 16,
  },
  nativeUiPrimaryCta: {
    height: 42,
    borderRadius: 21,
    paddingHorizontal: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  nativeUiPrimaryCtaText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  nativeUiSecondaryCta: {
    height: 42,
    borderRadius: 21,
    paddingHorizontal: 18,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  nativeUiSecondaryCtaText: {
    fontSize: 13,
    fontWeight: '600',
  },
  nativeUiTripleRow: {
    flexDirection: 'row',
    gap: 10,
  },
  nativeUiColumnCard: {
    flex: 1,
    height: 146,
    borderRadius: 22,
    padding: 14,
    justifyContent: 'space-between',
  },
  nativeUiColumnBlock: {
    height: 82,
    borderRadius: 18,
  },
  nativeUiFooterWide: {
    flex: 1,
    height: 44,
    borderRadius: 14,
  },
  nativeUiFooterShort: {
    width: 86,
    height: 34,
    borderRadius: 999,
  },
  nativeUiLine: {
    width: '82%',
    height: 12,
    borderRadius: 999,
  },
  nativeUiLineShort: {
    width: '56%',
    height: 12,
    borderRadius: 999,
  },
  nativeUiBoldTopRow: {
    flexDirection: 'row',
    gap: 12,
  },
  nativeUiBoldPanelLarge: {
    flex: 1.2,
    minHeight: 188,
    borderRadius: 28,
    padding: 18,
    justifyContent: 'space-between',
  },
  nativeUiBoldPanelTall: {
    width: 96,
    minHeight: 188,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'flex-start',
    paddingTop: 16,
  },
  nativeUiAccentPill: {
    width: 74,
    height: 14,
    borderRadius: 999,
  },
  nativeUiMiniDot: {
    width: 18,
    height: 18,
    borderRadius: 9,
  },
  nativeUiBoldBanner: {
    borderRadius: 24,
    padding: 18,
    gap: 12,
  },
  photoPaginationDots: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingTop: 16,
    paddingBottom: 6,
  },
  photoPaginationDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  photoPaginationDotActive: {
    width: 22,
    backgroundColor: 'rgba(255,255,255,0.62)',
  },
  photoNavWrap: {
    paddingHorizontal: 18,
    paddingTop: 12,
    paddingBottom: Platform.OS === 'ios' ? 10 : 16,
    alignItems: 'center',
  },
  photoNavPill: {
    width: '100%',
    maxWidth: 168,
    height: 54,
    borderRadius: 27,
    backgroundColor: '#111111',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    paddingHorizontal: 12,
    shadowColor: '#000000',
    shadowOpacity: 0.3,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 8,
  },
  photoNavIcon: {
    width: 52,
    height: 42,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptySubtext: {
    color: C.muted,
    fontSize: 13,
    textAlign: 'center',
    paddingHorizontal: 32,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
  },
  emptyText: {
    color: C.muted,
    fontSize: 16,
  },
  newButtonSmall: {
    paddingHorizontal: 20,
    paddingVertical: 10,
  },
  newButtonSmallText: {
    color: C.amber,
    fontSize: 15,
  },
  moodOuterScroll: {
    flex: 1,
  },
  moodSection: {
    paddingTop: 20,
    paddingBottom: 24,
  },
  moodGroup: {
    marginBottom: 14,
  },
  moodLabel: {
    color: 'rgba(255,255,255,0.35)',
    fontSize: 10,
    fontWeight: '600',
    letterSpacing: 1,
    textTransform: 'uppercase',
    paddingHorizontal: 18,
    marginBottom: 10,
  },
  moodScrollContent: {
    paddingHorizontal: 18,
    gap: 8,
  },
  moodPhotoTile: {
    width: 90,
    height: 118,
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: '#1A1A1A',
  },
  moodChannelTile: {
    width: 130,
    height: 80,
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: '#1A1A1A',
  },
  moodTileImage: {
    width: '100%',
    height: '100%',
  },
  moodChannelOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.45)',
  },
  moodChannelTitle: {
    position: 'absolute',
    bottom: 7,
    left: 8,
    right: 8,
    color: '#F5F0E8',
    fontSize: 9,
    fontWeight: '600',
    lineHeight: 12,
  },
});
