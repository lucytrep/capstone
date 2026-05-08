import React, { useCallback, useEffect, useState } from 'react';
import { StyleSheet, View, SafeAreaView, TouchableOpacity } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { AppText as Text } from '@/components/app-typography';
import { router } from 'expo-router';
import { generateArtifact } from '@/services/api';
import { SessionStore } from '@/store/session';

const C = {
  bg: '#111111',
  amber: '#E8A87C',
  cream: '#F5F0E8',
  muted: '#6B6259',
};

function BreathingDot({ delay = 0 }: { delay?: number }) {
  const scale = useSharedValue(0.6);
  const opacity = useSharedValue(0.2);

  useEffect(() => {
    scale.value = withRepeat(
      withSequence(
        withTiming(0.6, { duration: delay }),
        withTiming(1, { duration: 700, easing: Easing.inOut(Easing.ease) }),
        withTiming(0.6, { duration: 700, easing: Easing.inOut(Easing.ease) }),
      ),
      -1,
      false,
    );
    opacity.value = withRepeat(
      withSequence(
        withTiming(0.2, { duration: delay }),
        withTiming(1, { duration: 700, easing: Easing.inOut(Easing.ease) }),
        withTiming(0.2, { duration: 700, easing: Easing.inOut(Easing.ease) }),
      ),
      -1,
      false,
    );
  }, []);

  const style = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  return <Animated.View style={[styles.dot, style]} />;
}

export default function GeneratingScreen() {
  const glowScale = useSharedValue(1);
  const glowOpacity = useSharedValue(0.12);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    glowScale.value = withRepeat(
      withSequence(
        withTiming(1.3, { duration: 2000, easing: Easing.inOut(Easing.ease) }),
        withTiming(1, { duration: 2000, easing: Easing.inOut(Easing.ease) }),
      ),
      -1,
      false,
    );
    glowOpacity.value = withRepeat(
      withSequence(
        withTiming(0.2, { duration: 2000, easing: Easing.inOut(Easing.ease) }),
        withTiming(0.06, { duration: 2000, easing: Easing.inOut(Easing.ease) }),
      ),
      -1,
      false,
    );
  }, []);

  const glowStyle = useAnimatedStyle(() => ({
    transform: [{ scale: glowScale.value }],
    opacity: glowOpacity.value,
  }));

  const handleBackHome = useCallback(() => {
    router.replace('/(tabs)');
  }, []);

    const runGeneration = useCallback(async (cancelledRef: { current: boolean }) => {
      setErrorMessage('');
      await SessionStore.hydrate();
      if (cancelledRef.current) return;

      const transcript = SessionStore.getTranscript();
      if (!transcript) {
        router.replace('/(tabs)');
        return;
      }

      try {
        const html = await generateArtifact(transcript);
        if (cancelledRef.current) return;
        SessionStore.setArtifact(html);
        router.replace('/output');
      } catch (err) {
        if (cancelledRef.current) return;
        console.error('Generation error:', err);
        setErrorMessage(
          err instanceof Error ? err.message : 'Something went wrong while generating.'
        );
      } finally {
        if (cancelledRef.current) return;
      }
    }, []);

  useEffect(() => {
    const cancelledRef = { current: false };

    runGeneration(cancelledRef);

    return () => {
      cancelledRef.current = true;
    };
  }, [runGeneration]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.body}>
        <View style={styles.animationArea}>
          <Animated.View style={[styles.glow, glowStyle]} />
          {errorMessage ? (
            <View style={styles.errorBadge}>
              <Text style={styles.errorBadgeText}>!</Text>
            </View>
          ) : (
            <View style={styles.dotsRow}>
              <BreathingDot delay={0} />
              <BreathingDot delay={200} />
              <BreathingDot delay={400} />
            </View>
          )}
        </View>

        <View style={styles.textArea}>
          <Text style={styles.label}>{errorMessage ? 'Generation failed' : 'Generating your artifact'}</Text>
          <Text style={styles.sublabel}>
            {errorMessage
              ? errorMessage
              : 'This could take a couple minutes…'}
          </Text>
        </View>

        {errorMessage ? (
          <View style={styles.actions}>
            <TouchableOpacity
              onPress={() => runGeneration({ current: false })}
              style={styles.primaryButton}
              activeOpacity={0.85}
            >
              <Text style={styles.primaryButtonText}>Try again</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={handleBackHome}
              style={styles.secondaryButton}
              activeOpacity={0.85}
            >
              <Text style={styles.secondaryButtonText}>Back home</Text>
            </TouchableOpacity>
          </View>
        ) : null}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  body: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 48,
  },
  animationArea: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 120,
    height: 120,
  },
  glow: {
    position: 'absolute',
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: C.amber,
  },
  errorBadge: {
    width: 68,
    height: 68,
    borderRadius: 34,
    backgroundColor: 'rgba(232, 168, 124, 0.16)',
    borderWidth: 1,
    borderColor: 'rgba(232, 168, 124, 0.32)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  errorBadgeText: {
    color: C.amber,
    fontSize: 30,
    lineHeight: 34,
    fontWeight: '700',
  },
  dotsRow: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
  },
  dot: {
    width: 9,
    height: 9,
    borderRadius: 5,
    backgroundColor: C.amber,
  },
  textArea: {
    alignItems: 'center',
    gap: 8,
  },
  label: {
    fontSize: 18,
    fontWeight: '500',
    color: C.cream,
    letterSpacing: 0.2,
  },
  sublabel: {
    fontSize: 14,
    color: C.muted,
    textAlign: 'center',
    paddingHorizontal: 28,
  },
  actions: {
    alignItems: 'center',
    gap: 12,
    width: '100%',
    paddingHorizontal: 28,
  },
  primaryButton: {
    minWidth: 164,
    borderRadius: 18,
    paddingVertical: 14,
    paddingHorizontal: 18,
    backgroundColor: C.amber,
    alignItems: 'center',
  },
  primaryButtonText: {
    color: '#1C1815',
    fontSize: 15,
    fontWeight: '700',
  },
  secondaryButton: {
    minWidth: 164,
    borderRadius: 18,
    paddingVertical: 14,
    paddingHorizontal: 18,
    borderWidth: 1,
    borderColor: 'rgba(245, 240, 232, 0.16)',
    backgroundColor: 'rgba(245, 240, 232, 0.05)',
    alignItems: 'center',
  },
  secondaryButtonText: {
    color: C.cream,
    fontSize: 15,
    fontWeight: '600',
  },
});
