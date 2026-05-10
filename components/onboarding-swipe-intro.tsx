import React, { useMemo, useRef } from 'react';
import {
  Animated,
  PanResponder,
  StyleSheet,
  useWindowDimensions,
  View,
} from 'react-native';
import * as Haptics from 'expo-haptics';
import { LinearGradient } from 'expo-linear-gradient';
import { AppText as Text, getSFProRoundedFontFamily } from '@/components/app-typography';

const KNOB = 50;
const TRACK_H = 56;
const H_PAD = 24;
const INNER_PAD = 5;

type Props = {
  onComplete: () => void;
  bottomInset: number;
};

/**
 * Full-screen first-run onboarding: left-aligned copy + swipe-to-start pill (Figma).
 */
export function OnboardingSwipeIntro({ onComplete, bottomInset }: Props) {
  const { width: W, height: H } = useWindowDimensions();
  /** Large glow region behind copy — single orange ramp (no white band in the middle). */
  const glowDiameter = Math.min(W, H) * 0.88;
  const glowBleed = glowDiameter * 1.12;
  const glowLeft = W * 0.06 - (glowBleed - glowDiameter) / 2;
  const glowTop = H * 0.32 - (glowBleed - glowDiameter) / 2;
  const trackW = W - H_PAD * 2;
  const maxSlide = Math.max(0, trackW - KNOB - INNER_PAD * 2);

  const translateX = useRef(new Animated.Value(0)).current;
  const dragStart = useRef(0);

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: (_, g) => Math.abs(g.dx) > Math.abs(g.dy) && Math.abs(g.dx) > 2,
        onPanResponderGrant: () => {
          translateX.stopAnimation((v) => {
            dragStart.current = v;
          });
        },
        onPanResponderMove: (_, g) => {
          const nx = Math.min(Math.max(0, dragStart.current + g.dx), maxSlide);
          translateX.setValue(nx);
        },
        onPanResponderRelease: () => {
          translateX.stopAnimation((v) => {
            if (v > maxSlide * 0.52) {
              void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
              onComplete();
            } else {
              void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              Animated.spring(translateX, {
                toValue: 0,
                friction: 7,
                tension: 78,
                useNativeDriver: true,
              }).start();
            }
          });
        },
      }),
    [maxSlide, onComplete, translateX]
  );

  return (
    <View style={[StyleSheet.absoluteFill, { zIndex: 100 }]} accessibilityViewIsModal>
      <View style={[StyleSheet.absoluteFill, styles.backdrop]} />

      <LinearGradient
        pointerEvents="none"
        colors={[
          'rgba(255, 156, 64, 0.92)',
          'rgba(255, 148, 56, 0.78)',
          'rgba(240, 130, 48, 0.55)',
          'rgba(220, 110, 40, 0.32)',
          'rgba(180, 85, 30, 0.12)',
          'rgba(0, 0, 0, 0)',
        ]}
        locations={[0, 0.18, 0.38, 0.58, 0.78, 1]}
        start={{ x: 0.28, y: 0.32 }}
        end={{ x: 0.92, y: 0.92 }}
        style={[
          styles.glowGradient,
          {
            width: glowBleed,
            height: glowBleed,
            borderRadius: glowBleed / 2,
            left: glowLeft,
            top: glowTop,
          },
        ]}
      />

      <View style={[styles.content, { paddingBottom: Math.max(bottomInset, 28) + 8 }]}>
        <View style={styles.copyBlock}>
          <Text style={styles.welcomeSmall}>Welcome to</Text>
          <Text style={styles.headlineMedium}>Think it.</Text>
          <Text style={styles.headlineMedium}>Say it.</Text>
          <Text style={styles.headlineBold}>Draft it.</Text>
        </View>

        <View style={{ width: trackW, alignSelf: 'center' }}>
          <View style={[styles.track, { width: trackW, height: TRACK_H }]}>
            <View style={styles.startWrap} pointerEvents="none">
              <Text style={styles.startLabel}>Start</Text>
            </View>
            <View style={styles.chevronRow} pointerEvents="none">
              <Text style={styles.chevrons}>›››</Text>
            </View>
            <Animated.View
              style={[
                styles.knobWrap,
                {
                  transform: [{ translateX }],
                },
              ]}
              {...panResponder.panHandlers}
            >
              <View style={styles.knobCircle}>
                <Text style={styles.knobArrow}>→</Text>
              </View>
            </Animated.View>
          </View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    backgroundColor: '#000000',
  },
  glowGradient: {
    position: 'absolute',
  },
  content: {
    flex: 1,
    justifyContent: 'space-between',
    paddingTop: 72,
  },
  copyBlock: {
    paddingHorizontal: 28,
  },
  welcomeSmall: {
    fontSize: 17,
    lineHeight: 22,
    fontFamily: getSFProRoundedFontFamily('400'),
    color: 'rgba(255, 255, 255, 0.92)',
  },
  headlineMedium: {
    marginTop: 6,
    fontSize: 40,
    lineHeight: 46,
    fontFamily: getSFProRoundedFontFamily('500'),
    color: '#FFFFFF',
  },
  headlineBold: {
    marginTop: 2,
    fontSize: 40,
    lineHeight: 46,
    fontFamily: getSFProRoundedFontFamily('700'),
    color: '#FFFFFF',
  },
  track: {
    alignSelf: 'center',
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.14)',
    justifyContent: 'center',
  },
  startWrap: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
  },
  startLabel: {
    fontSize: 17,
    fontFamily: getSFProRoundedFontFamily('500'),
    color: 'rgba(255, 255, 255, 0.95)',
  },
  chevronRow: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'flex-end',
    paddingRight: 18,
  },
  chevrons: {
    fontSize: 18,
    fontFamily: getSFProRoundedFontFamily('500'),
    color: 'rgba(255, 255, 255, 0.88)',
  },
  knobWrap: {
    position: 'absolute',
    left: INNER_PAD,
    top: (TRACK_H - KNOB) / 2,
    width: KNOB,
    height: KNOB,
  },
  knobCircle: {
    width: KNOB,
    height: KNOB,
    borderRadius: KNOB / 2,
    backgroundColor: 'rgba(230, 230, 235, 1)',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOpacity: 0.28,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  knobArrow: {
    fontSize: 16,
    color: 'rgba(0, 0, 0, 0.82)',
    fontFamily: getSFProRoundedFontFamily('600'),
  },
});
