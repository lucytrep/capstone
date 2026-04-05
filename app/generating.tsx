import React, { useEffect } from 'react';
import { StyleSheet, View, Text, SafeAreaView } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
  Easing,
} from 'react-native-reanimated';
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

  useEffect(() => {
    const transcript = SessionStore.getTranscript();
    if (!transcript) {
      router.replace('/(tabs)');
      return;
    }

    let cancelled = false;

    const run = async () => {
      try {
        const html = await generateArtifact(transcript);
        if (cancelled) return;
        SessionStore.setArtifact(html);
        router.replace('/output');
      } catch (err) {
        if (cancelled) return;
        console.error('Generation error:', err);
        router.replace('/(tabs)');
      }
    };

    run();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.body}>
        <View style={styles.animationArea}>
          <Animated.View style={[styles.glow, glowStyle]} />
          <View style={styles.dotsRow}>
            <BreathingDot delay={0} />
            <BreathingDot delay={200} />
            <BreathingDot delay={400} />
          </View>
        </View>

        <View style={styles.textArea}>
          <Text style={styles.label}>Generating your artifact</Text>
          <Text style={styles.sublabel}>Thinking about your idea…</Text>
        </View>
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
  },
});
