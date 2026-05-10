import React, { useMemo, useState } from 'react';
import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router, useLocalSearchParams } from 'expo-router';
import { Image as ExpoImage } from 'expo-image';
import {
  Modal,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  View,
  useWindowDimensions,
} from 'react-native';
import { AppText as Text } from '@/components/app-typography';
import { AppBottomNav } from '@/components/app-bottom-nav';
import { getBoardById, type LibraryItem } from '@/data/library';

const C = {
  bg: '#111111',
  cream: '#F5F0E8',
  text: '#FFF8FC',
  muted: '#8A817A',
};

function chunkItems(items: LibraryItem[], size: number) {
  const pages: LibraryItem[][] = [];

  for (let index = 0; index < items.length; index += size) {
    pages.push(items.slice(index, index + size));
  }

  return pages;
}

/** Same luminance threshold as native `textColor(for:)` swatch captions. */
function isLightPreviewHex(hex: string): boolean {
  const normalized = hex.trim().replace('#', '');
  if (normalized.length !== 6) return false;
  const r = parseInt(normalized.slice(0, 2), 16);
  const g = parseInt(normalized.slice(2, 4), 16);
  const b = parseInt(normalized.slice(4, 6), 16);
  if ([r, g, b].some((n) => Number.isNaN(n))) return false;
  const brightness = (r * 299 + g * 587 + b * 114) / 1000 / 255;
  return brightness > 0.72;
}

function BoardTile({
  item,
  width,
  height,
  showPaletteMeta = false,
  contentFit = 'cover',
  imageOverlay = true,
  onPress,
}: {
  item: LibraryItem;
  width: number;
  height: number;
  showPaletteMeta?: boolean;
  contentFit?: 'cover' | 'contain';
  imageOverlay?: boolean;
  onPress?: (() => void) | undefined;
}) {
  const paletteStyle =
    item.kind === 'palette'
      ? {
          backgroundColor: item.previewColor,
          borderColor: item.secondaryColor,
        }
      : null;
  const imageTileStyle =
    item.kind === 'image' && !showPaletteMeta
      ? {
          backgroundColor: '#F7F5EF',
          borderColor: 'rgba(255,255,255,0.2)',
        }
      : null;

  const tileContent = (
    <View style={[styles.tile, paletteStyle, imageTileStyle, { width, height }]}>
      {item.kind === 'image' && item.imageUrl ? (
        <>
          <ExpoImage
            source={item.imageUrl}
            style={styles.tileImage}
            contentFit={contentFit}
            transition={140}
          />
          {imageOverlay ? <View style={styles.tileOverlay} /> : null}
        </>
      ) : showPaletteMeta && item.kind === 'palette' ? (
        <View style={styles.paletteMeta}>
          <Text
            style={[
              styles.paletteSwatchHexOnly,
              isLightPreviewHex(item.previewColor) ? styles.paletteTextDark : null,
            ]}>
            {item.previewColor.toUpperCase()}
          </Text>
        </View>
      ) : null}
    </View>
  );

  if (item.kind === 'image' && item.imageUrl && onPress) {
    return (
      <Pressable onPress={onPress} hitSlop={4}>
        {tileContent}
      </Pressable>
    );
  }

  return tileContent;
}

export default function BoardDetailScreen() {
  const { slug } = useLocalSearchParams<{ slug: string }>();
  const { width, height } = useWindowDimensions();
  const [activeIndex, setActiveIndex] = useState(0);
  const [fullscreenIndex, setFullscreenIndex] = useState<number | null>(null);
  const board = slug ? getBoardById(slug) : undefined;

  const pages = useMemo(() => (board ? chunkItems(board.items, 5) : []), [board]);
  const isPaletteBoard = board?.items.every((item) => item.kind === 'palette') ?? false;
  const isUiBoard = board?.id === 'ui-controls-board';
  const isDesertBoard = board?.id === 'yellow-kitchen-refresh';
  const boardLabel = isPaletteBoard ? 'Color Palette' : isUiBoard ? 'UI' : isDesertBoard ? 'Mood Board' : 'Photos';
  const imageItems = useMemo(
    () =>
      (board?.items ?? []).filter(
        (item): item is LibraryItem & { kind: 'image'; imageUrl: string | number } =>
          item.kind === 'image' && item.imageUrl !== undefined && item.imageUrl !== null
      ),
    [board]
  );

  if (!board) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.emptyState}>
          <Text style={styles.emptyTitle}>Board not found</Text>
        </View>
      </SafeAreaView>
    );
  }

  const gutter = 18;
  const gap = 10;
  const contentWidth = width - gutter * 2;
  const heroWidth = contentWidth;
  const smallWidth = Math.floor((contentWidth - gap) / 2);
  const availableHeight = Math.max(520, height - 250);
  const heroHeight = Math.min(300, Math.max(236, availableHeight * 0.38));
  const smallHeight = Math.min(172, Math.max(136, availableHeight * 0.24));
  const uiHeroHeight = Math.min(260, Math.max(212, availableHeight * 0.33));
  const uiWideWidth = Math.floor((contentWidth - gap) * 0.64);
  const uiNarrowWidth = contentWidth - gap - uiWideWidth;
  const uiBottomLeftWidth = Math.floor((contentWidth - gap) * 0.52);
  const uiMidHeight = Math.min(214, Math.max(174, availableHeight * 0.24));
  const uiBottomHeight = Math.min(194, Math.max(156, availableHeight * 0.22));
  const openFullscreen = (item: LibraryItem) => {
    if (item.kind !== 'image' || !item.imageUrl) return;
    const index = imageItems.findIndex((imageItem) => imageItem.id === item.id);
    if (index >= 0) {
      setFullscreenIndex(index);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.screen}>
          <View style={styles.topBar}>
          <View style={styles.headingWrap}>
            <Text style={styles.title}>{board.promptTitle}</Text>
            <Text style={styles.subtitle}>{boardLabel}</Text>
          </View>

          <View style={styles.actionsWrap}>
            <TouchableOpacity onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.back(); }} style={styles.actionButton} hitSlop={12}>
              <Feather name="x" size={18} color={C.cream} />
            </TouchableOpacity>
            <TouchableOpacity onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium); router.back(); }} style={styles.actionButton} hitSlop={12}>
              <Feather name="check" size={18} color={C.cream} />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.content}>
          {isPaletteBoard ? (
            <View style={styles.palettePage}>
              <View style={styles.paletteRows}>
                {board.items[0] ? (
                  <BoardTile item={board.items[0]} width={heroWidth} height={146} showPaletteMeta />
                ) : null}

                <View style={styles.row}>
                  {board.items[1] ? (
                    <BoardTile
                      item={board.items[1]}
                      width={Math.floor((contentWidth - gap) * 0.66)}
                      height={138}
                      showPaletteMeta
                    />
                  ) : null}
                  {board.items[2] ? (
                    <BoardTile
                      item={board.items[2]}
                      width={contentWidth - gap - Math.floor((contentWidth - gap) * 0.66)}
                      height={138}
                      showPaletteMeta
                    />
                  ) : null}
                </View>

                <View style={styles.row}>
                  {board.items[3] ? (
                    <BoardTile item={board.items[3]} width={smallWidth} height={132} showPaletteMeta />
                  ) : null}
                  {board.items[4] ? (
                    <BoardTile item={board.items[4]} width={smallWidth} height={132} showPaletteMeta />
                  ) : null}
                </View>
              </View>
            </View>
          ) : isUiBoard ? (
            <View style={styles.uiBoardPage}>
              <View style={styles.uiBoardRows}>
                {board.items[0] ? (
                  <BoardTile
                    item={board.items[0]}
                    width={heroWidth}
                    height={uiHeroHeight}
                    onPress={() => openFullscreen(board.items[0])}
                  />
                ) : null}
                <View style={styles.row}>
                  {board.items[1] ? (
                    <BoardTile
                      item={board.items[1]}
                      width={uiWideWidth}
                      height={uiMidHeight}
                      onPress={() => openFullscreen(board.items[1])}
                    />
                  ) : null}
                  {board.items[2] ? (
                    <BoardTile
                      item={board.items[2]}
                      width={uiNarrowWidth}
                      height={uiMidHeight}
                      onPress={() => openFullscreen(board.items[2])}
                    />
                  ) : null}
                </View>
                <View style={styles.row}>
                  {board.items[3] ? (
                    <BoardTile
                      item={board.items[3]}
                      width={uiBottomLeftWidth}
                      height={uiBottomHeight}
                      onPress={() => openFullscreen(board.items[3])}
                    />
                  ) : null}
                  <View style={styles.uiBottomSpacer} />
                </View>
              </View>
            </View>
          ) : (
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
                setActiveIndex(nextIndex);
              }}
              scrollEventThrottle={16}
              contentContainerStyle={styles.pagerContent}
            >
              {pages.map((pageItems, index) => (
                <View key={`${board.id}-${index}`} style={[styles.page, { width }]}>
                  <View style={styles.rows}>
                    {pageItems[0] ? (
                      <BoardTile
                        item={pageItems[0]}
                        width={heroWidth}
                        height={heroHeight}
                        onPress={() => openFullscreen(pageItems[0])}
                      />
                    ) : null}

                    {(pageItems[1] || pageItems[2]) ? (
                      <View style={styles.row}>
                        {pageItems[1] ? (
                          <BoardTile
                            item={pageItems[1]}
                            width={smallWidth}
                            height={smallHeight}
                            onPress={() => openFullscreen(pageItems[1])}
                          />
                        ) : (
                          <View style={{ width: smallWidth }} />
                        )}
                        {pageItems[2] ? (
                          <BoardTile
                            item={pageItems[2]}
                            width={smallWidth}
                            height={smallHeight}
                            onPress={() => openFullscreen(pageItems[2])}
                          />
                        ) : (
                          <View style={{ width: smallWidth }} />
                        )}
                      </View>
                    ) : null}

                    {(pageItems[3] || pageItems[4]) ? (
                      <View style={styles.row}>
                        {pageItems[3] ? (
                          <BoardTile
                            item={pageItems[3]}
                            width={smallWidth}
                            height={smallHeight}
                            onPress={() => openFullscreen(pageItems[3])}
                          />
                        ) : (
                          <View style={{ width: smallWidth }} />
                        )}
                        {pageItems[4] ? (
                          <BoardTile
                            item={pageItems[4]}
                            width={smallWidth}
                            height={smallHeight}
                            onPress={() => openFullscreen(pageItems[4])}
                          />
                        ) : (
                          <View style={{ width: smallWidth }} />
                        )}
                      </View>
                    ) : null}
                  </View>
                </View>
              ))}
            </ScrollView>
          )}

          {!isPaletteBoard && !isUiBoard && pages.length > 1 ? (
            <View style={styles.paginationDots}>
              {pages.map((_, index) => (
                <View
                  key={`${board.id}-dot-${index}`}
                  style={[
                    styles.paginationDot,
                    index === activeIndex && styles.paginationDotActive,
                  ]}
                />
              ))}
            </View>
          ) : null}
        </View>
        <Modal
          animationType="fade"
          transparent
          visible={fullscreenIndex !== null}
          onRequestClose={() => setFullscreenIndex(null)}
        >
          <View style={styles.fullscreenBackdrop}>
            <View style={styles.fullscreenTopBar}>
              <View style={styles.fullscreenMeta}>
                <Text style={styles.fullscreenTitle}>{board.promptTitle}</Text>
                <Text style={styles.fullscreenCount}>
                  {fullscreenIndex !== null ? `${fullscreenIndex + 1} of ${imageItems.length}` : ''}
                </Text>
              </View>
              <TouchableOpacity
                onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); setFullscreenIndex(null); }}
                style={styles.fullscreenCloseButton}
                hitSlop={12}
              >
                <Feather name="x" size={20} color={C.cream} />
              </TouchableOpacity>
            </View>

            {fullscreenIndex !== null ? (
              <ScrollView
                key={`fullscreen-${fullscreenIndex}`}
                horizontal
                pagingEnabled
                showsHorizontalScrollIndicator={false}
                decelerationRate="fast"
                snapToInterval={width}
                snapToAlignment="start"
                contentOffset={{ x: width * fullscreenIndex, y: 0 }}
                onMomentumScrollEnd={(event) => {
                  const nextIndex = Math.round(
                    event.nativeEvent.contentOffset.x / Math.max(width, 1)
                  );
                  setFullscreenIndex(nextIndex);
                }}
                scrollEventThrottle={16}
              >
                {imageItems.map((item) => (
                  <View key={`fullscreen-${item.id}`} style={[styles.fullscreenPage, { width }]}>
                    <ExpoImage
                      source={item.imageUrl}
                      style={styles.fullscreenImage}
                      contentFit="contain"
                      transition={160}
                    />
                    {item.alt ? <Text style={styles.fullscreenCaption}>{item.alt}</Text> : null}
                  </View>
                ))}
              </ScrollView>
            ) : null}
          </View>
        </Modal>
        <AppBottomNav />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  screen: {
    flex: 1,
    backgroundColor: '#000000',
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyTitle: {
    color: C.text,
    fontSize: 24,
    fontWeight: '700',
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 12,
    paddingHorizontal: 18,
    paddingBottom: 16,
    gap: 12,
  },
  headingWrap: {
    flex: 1,
  },
  title: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '700',
    lineHeight: 32,
  },
  subtitle: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: '300',
    lineHeight: 28,
    marginTop: 1,
  },
  actionsWrap: {
    flexDirection: 'row',
    gap: 10,
    paddingTop: 8,
  },
  actionButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.16)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  content: {
    flex: 1,
    justifyContent: 'flex-start',
  },
  pagerContent: {
    alignItems: 'stretch',
  },
  page: {
    paddingHorizontal: 18,
    justifyContent: 'flex-start',
  },
  rows: {
    gap: 10,
  },
  palettePage: {
    paddingHorizontal: 18,
  },
  paletteRows: {
    gap: 8,
  },
  uiBoardPage: {
    paddingHorizontal: 18,
  },
  uiBoardRows: {
    gap: 8,
  },
  uiLiveTile: {
    borderRadius: 21,
    overflow: 'hidden',
    backgroundColor: '#F8F6F0',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.16)',
  },
  uiAvatarScene: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 20,
    backgroundColor: '#F8F6F0',
  },
  uiTooltip: {
    backgroundColor: '#38383C',
    borderRadius: 20,
    paddingHorizontal: 18,
    paddingVertical: 12,
    marginBottom: 8,
    marginLeft: -84,
  },
  uiTooltipText: {
    color: '#FFFFFF',
    fontSize: 15,
    lineHeight: 18,
    fontWeight: '500',
  },
  uiTooltipPointer: {
    position: 'absolute',
    bottom: -7,
    width: 0,
    height: 0,
    borderLeftWidth: 8,
    borderRightWidth: 8,
    borderTopWidth: 12,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    borderTopColor: '#38383C',
  },
  uiAvatarRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  uiAvatar: {
    width: 58,
    height: 58,
    borderRadius: 29,
    marginLeft: -8,
    borderWidth: 2,
    borderColor: '#F8F6F0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  uiAvatarSelected: {
    borderColor: '#FFFFFF',
    borderWidth: 3,
  },
  uiAvatarActiveText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
  },
  uiFloatingScene: {
    flex: 1,
    backgroundColor: '#F8F6F0',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 18,
  },
  uiFloatingCircleGridOnly: {
    width: 168,
    gap: 14,
  },
  uiFloatingCircleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  uiFloatingCircleRowBottom: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 24,
  },
  uiFloatingCircle: {
    width: 46,
    height: 46,
    borderRadius: 23,
    alignItems: 'center',
    justifyContent: 'center',
  },
  uiFloatingCircleBrown: {
    backgroundColor: '#7E5C44',
  },
  uiFloatingCircleOrange: {
    backgroundColor: '#F7A62C',
  },
  uiFloatingCirclePurple: {
    backgroundColor: '#8043DB',
  },
  uiFloatingCircleMint: {
    backgroundColor: '#90C4BC',
  },
  uiFloatingCircleClay: {
    backgroundColor: '#BB6B5A',
  },
  uiFloatingCircleText: {
    color: '#FFFFFF',
    fontSize: 13,
    lineHeight: 14,
    fontWeight: '700',
  },
  uiPickerSolidTile: {
    flex: 1,
    width: '100%',
    borderRadius: 22,
    backgroundColor: '#B5D9CA',
    justifyContent: 'flex-end',
    alignItems: 'flex-start',
    paddingLeft: 18,
    paddingBottom: 16,
    paddingRight: 14,
    paddingTop: 14,
  },
  uiPickerSolidLabel: {
    fontSize: 15,
    lineHeight: 19,
    fontWeight: '600',
    color: 'rgba(22, 38, 32, 0.9)',
  },
  uiSelectionScene: {
    flex: 1,
    backgroundColor: '#F8F6F0',
    padding: 12,
  },
  uiSelectionFrame: {
    flex: 1,
    borderRadius: 26,
    backgroundColor: '#F6F4EE',
    overflow: 'hidden',
    padding: 12,
  },
  uiSelectionTan: {
    width: 36,
    height: 36,
    backgroundColor: '#C4AE7D',
    top: 34,
    left: 14,
  },
  uiSelectionRed: {
    width: 42,
    height: 42,
    backgroundColor: '#D12C22',
    top: 48,
    right: 34,
  },
  uiSelectionYellow: {
    width: 40,
    height: 40,
    backgroundColor: '#E7C071',
    bottom: 34,
    left: 20,
  },
  uiSelectionBlue: {
    width: 28,
    height: 28,
    backgroundColor: '#BCD5EF',
    bottom: 32,
    right: 18,
  },
  uiSelectionTray: {
    position: 'absolute',
    alignSelf: 'center',
    top: '42%',
    paddingHorizontal: 0,
    paddingVertical: 0,
    alignItems: 'center',
    gap: 7,
  },
  uiSelectionSequence: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  uiSelectionSequenceDot: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  uiSelectionSequenceDotLarge: {
    width: 30,
    height: 30,
    borderRadius: 15,
  },
  uiSelectionSequenceDotSmall: {
    width: 22,
    height: 22,
    borderRadius: 11,
  },
  uiSelectionSequenceText: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  uiSelectionSequenceTextLarge: {
    fontSize: 8,
    lineHeight: 9,
  },
  uiSelectionSequenceTextSmall: {
    fontSize: 6,
    lineHeight: 7,
  },
  uiBottomSpacer: {
    flex: 1,
  },
  row: {
    flexDirection: 'row',
    gap: 10,
  },
  tile: {
    borderRadius: 21,
    overflow: 'hidden',
    backgroundColor: '#1C1C1C',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.16)',
  },
  tileImage: {
    width: '100%',
    height: '100%',
  },
  tileOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.08)',
  },
  paletteMeta: {
    flex: 1,
    justifyContent: 'flex-start',
    padding: 16,
    gap: 2,
  },
  paletteSwatchHexOnly: {
    color: '#FFFFFF',
    fontSize: 11,
    lineHeight: 14,
    fontWeight: '600',
    fontFamily: Platform.select({ ios: 'Menlo', android: 'monospace', default: 'monospace' }),
  },
  paletteTextDark: {
    color: '#111111',
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
  fullscreenBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.96)',
  },
  fullscreenTopBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingTop: 18,
    paddingHorizontal: 18,
    paddingBottom: 10,
    gap: 12,
  },
  fullscreenMeta: {
    flex: 1,
    gap: 4,
  },
  fullscreenTitle: {
    color: C.text,
    fontSize: 22,
    lineHeight: 26,
    fontWeight: '700',
  },
  fullscreenCount: {
    color: C.muted,
    fontSize: 14,
    lineHeight: 18,
  },
  fullscreenCloseButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  fullscreenPage: {
    flex: 1,
    paddingHorizontal: 18,
    paddingBottom: 54,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 14,
  },
  fullscreenImage: {
    width: '100%',
    height: '78%',
  },
  fullscreenCaption: {
    color: C.cream,
    fontSize: 14,
    lineHeight: 20,
    textAlign: 'center',
    opacity: 0.88,
  },
});
