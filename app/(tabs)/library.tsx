import React from 'react';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Image as ExpoImage } from 'expo-image';
import {
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppBottomNav } from '@/components/app-bottom-nav';
import { libraryBoards, type LibraryBoard } from '@/data/library';

const C = {
  bg: '#000000',
  text: '#FFFFFF',
  muted: 'rgba(255, 255, 255, 0.82)',
  folder: '#4A4A4A',
  folderDark: '#151515',
  border: 'rgba(255, 255, 255, 0.08)',
};

function SoftSpatialPreviewGrid() {
  return (
    <View style={styles.previewGrid}>
      <View style={[styles.previewTile, styles.previewSlotHero]}>
        <View style={[styles.uiPreviewCanvas, styles.uiPreviewCanvasFullBleed]}>
          <View style={styles.uiPreviewAvatarRow}>
            <View style={[styles.uiPreviewAvatar, { backgroundColor: '#7E5C44' }]}>
              <Text style={styles.uiPreviewAvatarText}>M.R</Text>
            </View>
            <View style={[styles.uiPreviewAvatar, { backgroundColor: '#F7A62C' }]}>
              <Text style={styles.uiPreviewAvatarText}>A.B</Text>
            </View>
            <View style={[styles.uiPreviewAvatar, { backgroundColor: '#8043DB' }]}>
              <Text style={styles.uiPreviewAvatarText}>N.H</Text>
            </View>
            <View style={[styles.uiPreviewAvatar, { backgroundColor: '#90C4BC' }]}>
              <Text style={styles.uiPreviewAvatarText}>S.B</Text>
            </View>
            <View style={[styles.uiPreviewAvatar, { backgroundColor: '#BB6B5A' }]}>
              <Text style={styles.uiPreviewAvatarText}>I.V</Text>
            </View>
          </View>
        </View>
      </View>

      <View style={styles.previewMiddleRow}>
        <View style={[styles.previewTile, styles.previewSlotWide]}>
          <View style={[styles.uiPreviewCanvas, styles.uiPreviewCanvasFullBleed]}>
            <View style={styles.uiPreviewCircleGrid}>
              <View style={styles.uiPreviewCircleRow}>
                <View style={[styles.uiPreviewCircle, { backgroundColor: '#7E5C44' }]}>
                  <Text style={styles.uiPreviewCircleText}>M.R</Text>
                </View>
                <View style={[styles.uiPreviewCircle, { backgroundColor: '#F7A62C' }]}>
                  <Text style={styles.uiPreviewCircleText}>A.B</Text>
                </View>
                <View style={[styles.uiPreviewCircle, { backgroundColor: '#8043DB' }]}>
                  <Text style={styles.uiPreviewCircleText}>N.H</Text>
                </View>
              </View>
              <View style={styles.uiPreviewCircleRowBottom}>
                <View style={[styles.uiPreviewCircle, { backgroundColor: '#90C4BC' }]}>
                  <Text style={styles.uiPreviewCircleText}>S.B</Text>
                </View>
                <View style={[styles.uiPreviewCircle, { backgroundColor: '#BB6B5A' }]}>
                  <Text style={styles.uiPreviewCircleText}>I.V</Text>
                </View>
              </View>
            </View>
          </View>
        </View>

        <View style={[styles.previewTile, styles.previewSlotNarrow]}>
          <View style={[styles.uiPreviewCanvas, styles.uiPreviewCanvasFullBleed]}>
            <View style={styles.uiPreviewCircleCluster}>
              <View style={[styles.uiPreviewClusterCircle, styles.uiPreviewClusterCircleTop, { backgroundColor: '#95B173' }]}>
                <Text style={styles.uiPreviewClusterText}>M.R</Text>
              </View>
              <View style={[styles.uiPreviewClusterCircle, styles.uiPreviewClusterCircleMedium, styles.uiPreviewClusterCircleOne, { backgroundColor: '#D4D8DC' }]}>
                <Text style={styles.uiPreviewClusterTextDark}>A.B</Text>
              </View>
              <View style={[styles.uiPreviewClusterCircle, styles.uiPreviewClusterCircleMedium, styles.uiPreviewClusterCircleTwo, { backgroundColor: '#A9C8E6' }]}>
                <Text style={styles.uiPreviewClusterText}>N.H</Text>
              </View>
              <View style={[styles.uiPreviewClusterCircle, styles.uiPreviewClusterCircleMedium, styles.uiPreviewClusterCircleThree, { backgroundColor: '#9A7A64' }]}>
                <Text style={styles.uiPreviewClusterText}>S.B</Text>
              </View>
              <View style={[styles.uiPreviewClusterCircle, styles.uiPreviewClusterCircleMedium, styles.uiPreviewClusterCircleFour, { backgroundColor: '#F6F3EC', borderWidth: 1, borderColor: '#DFDCD5' }]}>
                <Text style={styles.uiPreviewClusterTextDark}>I.V</Text>
              </View>
            </View>
          </View>
        </View>
      </View>

      <View style={[styles.previewTile, styles.previewSlotBottom]}>
        <View style={[styles.uiPreviewCanvas, styles.uiPreviewCanvasFullBleed]}>
          <View style={styles.uiPreviewSelectionFrame}>
            <View style={styles.uiPreviewSelectionSequence}>
              <View style={[styles.uiPreviewSequenceDot, styles.uiPreviewSequenceDotLarge, { backgroundColor: '#7E5C44' }]}>
                <Text style={styles.uiPreviewSequenceText}>M.R</Text>
              </View>
              <View style={[styles.uiPreviewSequenceDot, styles.uiPreviewSequenceDotSmall, { backgroundColor: '#F7A62C' }]}>
                <Text style={styles.uiPreviewSequenceTextSmall}>A.B</Text>
              </View>
              <View style={[styles.uiPreviewSequenceDot, styles.uiPreviewSequenceDotLarge, { backgroundColor: '#8043DB' }]}>
                <Text style={styles.uiPreviewSequenceText}>N.H</Text>
              </View>
              <View style={[styles.uiPreviewSequenceDot, styles.uiPreviewSequenceDotSmall, { backgroundColor: '#90C4BC' }]}>
                <Text style={styles.uiPreviewSequenceTextSmall}>S.B</Text>
              </View>
              <View style={[styles.uiPreviewSequenceDot, styles.uiPreviewSequenceDotLarge, { backgroundColor: '#BB6B5A' }]}>
                <Text style={styles.uiPreviewSequenceText}>I.V</Text>
              </View>
            </View>
          </View>
        </View>
      </View>
    </View>
  );
}

function BoardPreview({ board }: { board: LibraryBoard }) {
  if (board.id === 'ui-controls-board') {
    return <SoftSpatialPreviewGrid />;
  }

  const previewTiles = Array.from({ length: 4 }, (_, index) => board.items[index]);

  return (
    <View style={styles.previewGrid}>
      {[previewTiles[0]].map((item, index) => (
        <View
          key={item?.id ?? `placeholder-${index}`}
          style={[
            styles.previewTile,
            styles.previewSlotHero,
            item?.kind === 'palette' && {
              backgroundColor: item.previewColor,
              borderColor: item.secondaryColor,
            },
          ]}>
          {item ? (
            item.kind === 'image' && item.imageUrl ? (
              <>
                <ExpoImage
                  source={item.thumbUrl || item.imageUrl}
                  style={styles.previewPhotoImage}
                  contentFit="cover"
                  transition={120}
                />
                <View style={styles.previewPhotoOverlay} />
              </>
            ) : (
              <View style={styles.palettePreviewContent} />
            )
          ) : (
            <View style={styles.previewPlaceholder} />
          )}
        </View>
      ))}

      <View style={styles.previewMiddleRow}>
        {[previewTiles[1], previewTiles[2]].map((item, index) => (
          <View
            key={item?.id ?? `placeholder-middle-${index}`}
            style={[
              styles.previewTile,
              index === 0 ? styles.previewSlotWide : styles.previewSlotNarrow,
              item?.kind === 'palette' && {
                backgroundColor: item.previewColor,
                borderColor: item.secondaryColor,
              },
            ]}>
            {item ? (
              item.kind === 'image' && item.imageUrl ? (
                <>
                  <ExpoImage
                    source={item.thumbUrl || item.imageUrl}
                    style={styles.previewPhotoImage}
                    contentFit="cover"
                    transition={120}
                  />
                  <View style={styles.previewPhotoOverlay} />
                </>
              ) : (
                <View style={styles.palettePreviewContent} />
              )
            ) : (
              <View style={styles.previewPlaceholder} />
            )}
          </View>
        ))}
      </View>

      <View
        style={[
          styles.previewTile,
          styles.previewSlotBottom,
          previewTiles[3]?.kind === 'palette' && {
            backgroundColor: previewTiles[3].previewColor,
            borderColor: previewTiles[3].secondaryColor,
          },
        ]}>
        {previewTiles[3] ? (
          previewTiles[3].kind === 'image' && previewTiles[3].imageUrl ? (
            <>
              <ExpoImage
                source={previewTiles[3].thumbUrl || previewTiles[3].imageUrl}
                style={styles.previewPhotoImage}
                contentFit="cover"
                transition={120}
              />
              <View style={styles.previewPhotoOverlay} />
            </>
          ) : (
            <View style={styles.palettePreviewContent} />
          )
        ) : (
          <View style={styles.previewPlaceholder} />
        )}
      </View>
    </View>
  );
}

function BoardCard({ board }: { board: LibraryBoard }) {
  return (
    <Pressable
      style={styles.boardCard}
      onPress={() => router.push(`/library/${board.id}` as never)}
      delayPressIn={90}
    >
      <View style={styles.boardHeader}>
        <Text numberOfLines={1} style={styles.boardTitle}>{board.promptTitle}</Text>
        <Text style={styles.boardCount}>{board.itemCount} items</Text>
      </View>
      <BoardPreview board={board} />
    </Pressable>
  );
}

export default function LibraryScreen() {
  const insets = useSafeAreaInsets();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.shell}>
        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={[
            styles.scrollContent,
            { paddingBottom: 128 + Math.max(insets.bottom, 10) },
          ]}
          showsVerticalScrollIndicator={false}
          alwaysBounceVertical
          bounces
          scrollEnabled
          canCancelContentTouches
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.headerRow}>
            <Text style={styles.pageTitle}>Library</Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Open settings"
              onPress={() => router.push('/settings')}
              style={styles.settingsButton}
              hitSlop={10}
            >
              <Feather name="settings" size={18} color={C.text} />
            </Pressable>
          </View>

          <View style={styles.boardsGrid}>
            {libraryBoards.map((board) => (
              <BoardCard key={board.id} board={board} />
            ))}
          </View>
        </ScrollView>
      </View>
      <AppBottomNav />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  shell: {
    flex: 1,
    paddingHorizontal: 22,
    paddingTop: 14,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingTop: 34,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 26,
  },
  pageTitle: {
    fontSize: 34,
    lineHeight: 40,
    fontWeight: '700',
    color: C.text,
  },
  settingsButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.12)',
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  boardsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    columnGap: 22,
    rowGap: 10,
  },
  boardCard: {
    width: '46.6%',
    gap: 12,
  },
  boardHeader: {
    gap: 2,
    minHeight: 40,
  },
  boardTitle: {
    fontSize: 17,
    lineHeight: 21,
    fontWeight: '700',
    color: C.text,
  },
  boardCount: {
    fontSize: 13,
    lineHeight: 17,
    color: C.muted,
  },
  previewGrid: {
    width: '100%',
    aspectRatio: 0.64,
    gap: 6,
  },
  previewMiddleRow: {
    flexDirection: 'row',
    gap: 6,
    width: '100%',
    height: '29%',
    alignItems: 'stretch',
  },
  previewSlotHero: {
    width: '100%',
    height: '37%',
  },
  previewSlotWide: {
    width: '57%',
  },
  previewSlotNarrow: {
    width: '40%',
  },
  previewSlotBottom: {
    width: '100%',
    height: '18%',
  },
  previewTile: {
    borderRadius: 14,
    backgroundColor: C.folderDark,
    borderWidth: 1,
    borderColor: C.border,
    overflow: 'hidden',
    padding: 10,
  },
  uiPreviewCanvas: {
    flex: 1,
    borderRadius: 10,
    backgroundColor: '#F8F6F0',
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
  },
  uiPreviewCanvasFullBleed: {
    margin: -10,
    borderRadius: 13,
  },
  uiPreviewAvatarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 0,
  },
  uiPreviewAvatar: {
    width: 20,
    height: 20,
    borderRadius: 10,
    marginLeft: -5,
    borderWidth: 1.5,
    borderColor: '#F8F6F0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  uiPreviewAvatarText: {
    color: '#FFFFFF',
    fontSize: 6,
    lineHeight: 7,
    fontWeight: '700',
  },
  uiPreviewCircleGrid: {
    width: 86,
    gap: 8,
  },
  uiPreviewCircleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  uiPreviewCircleRowBottom: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 18,
  },
  uiPreviewCircle: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  uiPreviewCircleText: {
    color: '#FFFFFF',
    fontSize: 4,
    lineHeight: 5,
    fontWeight: '700',
  },
  uiPreviewLogoRow: {
    position: 'absolute',
    top: 8,
    left: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  uiPreviewLogoDotLarge: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#111111',
  },
  uiPreviewLogoDotSmall: {
    width: 3,
    height: 3,
    borderRadius: 1.5,
    backgroundColor: '#111111',
    marginTop: 1,
  },
  uiPreviewSquare: {
    position: 'absolute',
    borderRadius: 8,
  },
  uiPreviewSquareSage: {
    width: 18,
    height: 18,
    backgroundColor: '#95B173',
    top: 22,
    left: 8,
  },
  uiPreviewSquareRed: {
    width: 14,
    height: 14,
    backgroundColor: '#C52A1F',
    top: 26,
    right: 8,
  },
  uiPreviewSquareAmber: {
    width: 18,
    height: 18,
    backgroundColor: '#E8B660',
    bottom: 12,
    left: 8,
  },
  uiPreviewSquareDark: {
    width: 14,
    height: 14,
    backgroundColor: '#121212',
    bottom: 12,
    right: 8,
  },
  uiPreviewCircleCluster: {
    width: 68,
    height: 68,
    alignItems: 'center',
    justifyContent: 'center',
  },
  uiPreviewClusterCircle: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  uiPreviewClusterCircleTop: {
    width: 20,
    height: 20,
    borderRadius: 10,
    top: 4,
    left: 24,
  },
  uiPreviewClusterCircleMedium: {
    width: 20,
    height: 20,
    borderRadius: 10,
  },
  uiPreviewClusterCircleOne: {
    left: 44,
    top: 18,
  },
  uiPreviewClusterCircleTwo: {
    left: 33,
    top: 40,
  },
  uiPreviewClusterCircleThree: {
    left: 11,
    top: 40,
  },
  uiPreviewClusterCircleFour: {
    left: 0,
    top: 18,
  },
  uiPreviewClusterText: {
    color: '#FFFFFF',
    fontSize: 4,
    lineHeight: 5,
    fontWeight: '700',
  },
  uiPreviewClusterTextDark: {
    color: '#555555',
    fontSize: 4,
    lineHeight: 5,
    fontWeight: '700',
  },
  uiPreviewSelectionFrame: {
    flex: 1,
    width: '100%',
    borderRadius: 12,
    backgroundColor: '#F6F4EE',
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
  },
  uiPreviewSelectionSequence: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  uiPreviewSequenceDot: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  uiPreviewSequenceDotLarge: {
    width: 18,
    height: 18,
    borderRadius: 9,
  },
  uiPreviewSequenceDotSmall: {
    width: 14,
    height: 14,
    borderRadius: 7,
  },
  uiPreviewSequenceText: {
    color: '#FFFFFF',
    fontSize: 4,
    lineHeight: 5,
    fontWeight: '700',
  },
  uiPreviewSequenceTextSmall: {
    color: '#FFFFFF',
    fontSize: 3,
    lineHeight: 4,
    fontWeight: '700',
  },
  previewPlaceholder: {
    flex: 1,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
  },
  previewPhotoImage: {
    ...StyleSheet.absoluteFillObject,
  },
  previewPhotoOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.08)',
  },
  tileKind: {
    fontSize: 10,
    lineHeight: 12,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
    color: '#FFFFFF',
    opacity: 0.8,
  },
  tileLabel: {
    fontSize: 12,
    lineHeight: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  palettePreviewContent: {
    flex: 1,
  },
});
