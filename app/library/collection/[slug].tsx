import React from 'react';
import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router, useLocalSearchParams } from 'expo-router';
import { Image as ExpoImage } from 'expo-image';
import {
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { AppText as Text } from '@/components/app-typography';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { getBoardById, getCollectionById } from '@/data/library';

const C = {
  bg: '#111111',
  card: '#171614',
  border: '#272320',
  text: '#FFF8FC',
  muted: '#8A817A',
};

export default function CollectionDetailScreen() {
  const insets = useSafeAreaInsets();
  const { slug } = useLocalSearchParams<{ slug: string }>();
  const collection = slug ? getCollectionById(slug) : undefined;
  const boards =
    collection?.boardIds
      .map((boardId) => getBoardById(boardId))
      .filter((board): board is NonNullable<typeof board> => Boolean(board)) ?? [];
  const individualItems = boards.flatMap((board) =>
    board.items
      .filter((item) => item.kind === 'image' && item.imageUrl)
      .map((item) => ({
        ...item,
        boardId: board.id,
      }))
  );
  const isIndividualCollection = collection?.id === 'individual';

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.shell}>
        <Pressable style={styles.backButton} onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.back(); }}>
          <Feather name="arrow-left" size={18} color={C.text} />
          <Text style={styles.backLabel}>Back</Text>
        </Pressable>

        {!collection ? (
          <View style={styles.emptyState}>
            <Text style={styles.title}>Collection not found</Text>
          </View>
        ) : (
          <ScrollView
            style={styles.scrollView}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={[
              styles.scrollContent,
              { paddingBottom: 32 + Math.max(insets.bottom, 10) },
            ]}
            alwaysBounceVertical
            bounces
            scrollEnabled
          >
            <Text style={styles.title}>{collection.title}</Text>
            <Text style={styles.subtitle}>{collection.description}</Text>

            {isIndividualCollection ? (
              <View>
                {individualItems.length > 0 ? (
                  <Pressable
                    style={styles.heroTile}
                    onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push(`/library/${individualItems[0].boardId}` as never); }}
                  >
                    <ExpoImage
                      source={individualItems[0].thumbUrl || individualItems[0].imageUrl}
                      style={styles.albumImage}
                      contentFit="cover"
                      transition={120}
                    />
                  </Pressable>
                ) : null}

                {individualItems.length > 1 ? (
                  <View style={styles.heroRowTwo}>
                    {individualItems.slice(1, 3).map((item) => (
                      <Pressable
                        key={item.id}
                        style={styles.heroRowTile}
                        onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push(`/library/${item.boardId}` as never); }}
                      >
                        <ExpoImage
                          source={item.thumbUrl || item.imageUrl}
                          style={styles.albumImage}
                          contentFit="cover"
                          transition={120}
                        />
                      </Pressable>
                    ))}
                  </View>
                ) : null}

                <View style={styles.albumGrid}>
                  {individualItems.slice(3).map((item, index) => (
                    <Pressable
                      key={item.id}
                      style={[
                        styles.albumTile,
                        index % 5 === 0 && styles.albumTileTall,
                      ]}
                      onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push(`/library/${item.boardId}` as never); }}
                    >
                      <ExpoImage
                        source={item.thumbUrl || item.imageUrl}
                        style={styles.albumImage}
                        contentFit="cover"
                        transition={120}
                      />
                    </Pressable>
                  ))}
                </View>
              </View>
            ) : (
              boards.map((board) =>
                board ? (
                  <Pressable
                    key={board.id}
                    style={styles.boardCard}
                    onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push(`/library/${board.id}` as never); }}
                  >
                    <View>
                      <Text style={styles.boardTitle}>{board.promptTitle}</Text>
                      <Text style={styles.boardMeta}>
                        {board.itemCount} items • {board.updatedAtLabel}
                      </Text>
                    </View>
                    <Feather name="chevron-right" size={18} color={C.muted} />
                  </Pressable>
                ) : null
              )
            )}
          </ScrollView>
        )}
      </View>
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
    paddingHorizontal: 20,
    paddingTop: 6,
  },
  scrollView: {
    flex: 1,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 8,
    marginBottom: 20,
  },
  backLabel: {
    color: C.text,
    fontSize: 15,
    lineHeight: 19,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scrollContent: {
  },
  title: {
    fontSize: 32,
    lineHeight: 36,
    fontWeight: '700',
    color: C.text,
  },
  subtitle: {
    marginTop: 12,
    marginBottom: 24,
    fontSize: 15,
    lineHeight: 22,
    color: C.muted,
  },
  heroTile: {
    width: '100%',
    aspectRatio: 1.4,
    borderRadius: 22,
    overflow: 'hidden',
    backgroundColor: C.card,
    marginBottom: 10,
  },
  heroRowTwo: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 10,
  },
  heroRowTile: {
    flex: 1,
    aspectRatio: 0.9,
    borderRadius: 22,
    overflow: 'hidden',
    backgroundColor: C.card,
  },
  albumGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    columnGap: 10,
    rowGap: 10,
    paddingBottom: 24,
  },
  albumTile: {
    width: '48.5%',
    aspectRatio: 0.82,
    borderRadius: 22,
    overflow: 'hidden',
    backgroundColor: C.card,
  },
  albumTileTall: {
    aspectRatio: 0.68,
  },
  albumImage: {
    width: '100%',
    height: '100%',
  },
  boardCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderRadius: 24,
    backgroundColor: C.card,
    borderWidth: 1,
    borderColor: C.border,
    padding: 18,
    marginBottom: 12,
  },
  boardTitle: {
    fontSize: 18,
    lineHeight: 22,
    fontWeight: '700',
    color: C.text,
  },
  boardMeta: {
    marginTop: 6,
    fontSize: 14,
    lineHeight: 18,
    color: C.muted,
  },
});
