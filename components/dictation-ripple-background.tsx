import React, { useEffect } from 'react';
import { StyleSheet, useWindowDimensions, View, type ViewStyle } from 'react-native';
import Animated, {
  type AnimatedStyle,
  Easing,
  interpolateColor,
  useAnimatedStyle,
  useFrameCallback,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';

/** Matches dictation screen background so the ring reads as hollow. */
const SCREEN_BG = '#000000';

/** Resting cycle: orange → teal → #EFEFEF → teal → orange (matches Swift). */
const IDLE_CYCLE_COLORS = ['#FF9C40', '#BCDAC2', '#EFEFEF', '#BCDAC2', '#FF9C40'] as const;
const IDLE_CYCLE_STOPS = [0, 0.25, 0.5, 0.75, 1] as const;
const IDLE_CYCLE_SPEED = 0.082;

/** Press / listen — teal shell for hollow ring + soft aura. */
const TEAL = 'rgba(188, 218, 194, 0.5)';
const TEAL_SOFT = 'rgba(188, 218, 194, 0.42)';
const TEAL_DEEP = 'rgba(130, 168, 148, 0.38)';

type DictationRippleBackgroundProps = {
  /** Finger down or voice session active — drives crossfade + ripples. */
  listening: boolean;
};

/** Smoothstep for gentler low-end of press blend (worklet). */
function presence(b: number) {
  'worklet';
  const x = b <= 0 ? 0 : b >= 1 ? 1 : b;
  return x * x * (3 - 2 * x);
}

/** 0…1 phase for resting color loop (worklet). */
function idleCycleU(tSec: number, speed: number, offset: number) {
  'worklet';
  const v = tSec * speed + offset;
  return v - Math.floor(v);
}

type HollowRingProps = {
  cx: number;
  cy: number;
  outerW: number;
  outerH: number;
  innerW: number;
  innerH: number;
  wrapperStyle: AnimatedStyle<ViewStyle>;
  glowStyle: AnimatedStyle<ViewStyle>;
};

function HollowGlowRing({ cx, cy, outerW, outerH, innerW, innerH, wrapperStyle, glowStyle }: HollowRingProps) {
  return (
    <Animated.View
      style={[
        {
          position: 'absolute',
          left: cx - outerW / 2,
          top: cy - outerH / 2,
          width: outerW,
          height: outerH,
        },
        wrapperStyle,
      ]}
    >
      <Animated.View
        style={[
          {
            width: outerW,
            height: outerH,
            borderRadius: 99999,
          },
          glowStyle,
        ]}
      />
      <View
        style={{
          position: 'absolute',
          left: (outerW - innerW) / 2,
          top: (outerH - innerH) / 2,
          width: innerW,
          height: innerH,
          borderRadius: 99999,
          backgroundColor: SCREEN_BG,
        }}
      />
    </Animated.View>
  );
}

/**
 * Full-screen dictation halo: tall hollow ring (soft torus) at rest — matches Figma
 * dictation frame; cycles orange → teal → #EFEFEF → teal → orange. Listening adds a
 * teal hollow ring + wide soft aura. Reanimated runs colors and motion on the UI thread.
 */
export function DictationRippleBackground({ listening }: DictationRippleBackgroundProps) {
  const { width: W, height: H } = useWindowDimensions();
  const layoutW = useSharedValue(W);
  const layoutH = useSharedValue(H);

  useEffect(() => {
    layoutW.value = W;
    layoutH.value = H;
  }, [W, H, layoutW, layoutH]);

  const cx = W / 2;
  const cy = H * 0.43 + 16;
  const short = Math.min(W, H);

  /** Vertically elongated ring (~Figma: tall soft torus). */
  const idleOuterW = short * 0.56;
  const idleOuterH = short * 1.26;
  const idleInnerW = idleOuterW * 0.48;
  const idleInnerH = idleOuterH * 0.63;

  const listenOuterW = short * 0.6;
  const listenOuterH = short * 1.32;
  const listenInnerW = listenOuterW * 0.47;
  const listenInnerH = listenOuterH * 0.62;

  const smoothBlend = useSharedValue(0);
  const timeSec = useSharedValue(0);
  const idleScale = useSharedValue(1);

  useEffect(() => {
    smoothBlend.value = withTiming(listening ? 1 : 0, {
      duration: listening ? 820 : 1050,
      easing: Easing.bezier(0.2, 0.05, 0.15, 1),
    });
  }, [listening, smoothBlend]);

  useEffect(() => {
    idleScale.value = withRepeat(
      withSequence(
        withTiming(1.03, { duration: 1800, easing: Easing.inOut(Easing.sin) }),
        withTiming(1, { duration: 1800, easing: Easing.inOut(Easing.sin) })
      ),
      -1,
      true
    );
  }, [idleScale]);

  useFrameCallback(({ timestamp }) => {
    'worklet';
    timeSec.value = timestamp / 1000;
  }, true);

  const idleWrapperStyle = useAnimatedStyle(() => {
    const b = smoothBlend.value;
    const vis = 1 - b * b;
    return {
      opacity: vis,
      transform: [{ scale: idleScale.value }],
    };
  });

  const idleGlowStyle = useAnimatedStyle(() => {
    const u = idleCycleU(timeSec.value, IDLE_CYCLE_SPEED, 0);
    const bg = interpolateColor(u, [...IDLE_CYCLE_STOPS], [...IDLE_CYCLE_COLORS]);
    const shadow = interpolateColor(u, [...IDLE_CYCLE_STOPS], [...IDLE_CYCLE_COLORS]);
    return {
      backgroundColor: bg,
      shadowColor: shadow,
      shadowOpacity: 0.72,
      shadowRadius: 96,
      shadowOffset: { width: 0, height: 0 },
    };
  });

  const listenAuraStyle = useAnimatedStyle(() => {
    const b = presence(smoothBlend.value);
    const bw = layoutW.value;
    const bh = layoutH.value;
    const pulse = 0.55 + 0.45 * (0.5 + 0.5 * Math.sin(timeSec.value * 0.88));
    return {
      opacity: 0.16 * b * pulse,
      width: bw * 0.88,
      height: bh * 0.5,
      left: cx - (bw * 0.88) / 2,
      top: cy - (bh * 0.5) / 2,
    };
  });

  const listenRingWrapperStyle = useAnimatedStyle(() => {
    const b = presence(smoothBlend.value);
    const t = timeSec.value;
    const osc = 0.5 + 0.5 * Math.sin(t * 1.92 + 0.12);
    const op = (0.38 + 0.42 * osc) * b;
    const sc = 0.9 + 0.12 * osc * b + (1 - b) * 0.04;
    return {
      opacity: op,
      transform: [{ scale: sc }],
    };
  });

  const listenGlowStyle = useAnimatedStyle(() => {
    return {
      backgroundColor: TEAL,
      shadowColor: '#BCDAC2',
      shadowOpacity: 0.55,
      shadowRadius: 88,
      shadowOffset: { width: 0, height: 0 },
    };
  });

  const listenBloomStyle = useAnimatedStyle(() => {
    const b = presence(smoothBlend.value);
    const t = timeSec.value;
    const osc = 0.5 + 0.5 * Math.sin(t * 1.45 + 0.9);
    const op = (0.08 + 0.14 * osc) * b;
    const sc = 1.06 + 0.06 * osc * b;
    return {
      opacity: op,
      transform: [{ scale: sc }],
      width: listenOuterW * 1.14,
      height: listenOuterH * 1.1,
      left: cx - (listenOuterW * 1.14) / 2,
      top: cy - (listenOuterH * 1.1) / 2,
    };
  });

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <Animated.View
        style={[
          styles.ellipseBase,
          listenAuraStyle,
          {
            borderRadius: 99999,
            backgroundColor: TEAL_DEEP,
          },
        ]}
      />

      <HollowGlowRing
        cx={cx}
        cy={cy}
        outerW={idleOuterW}
        outerH={idleOuterH}
        innerW={idleInnerW}
        innerH={idleInnerH}
        wrapperStyle={idleWrapperStyle}
        glowStyle={idleGlowStyle}
      />

      <Animated.View
        style={[
          styles.ellipseBase,
          listenBloomStyle,
          {
            borderRadius: 99999,
            backgroundColor: TEAL_SOFT,
            shadowColor: '#BCDAC2',
            shadowOpacity: 0.32,
            shadowRadius: 72,
            shadowOffset: { width: 0, height: 0 },
          },
        ]}
      />

      <HollowGlowRing
        cx={cx}
        cy={cy}
        outerW={listenOuterW}
        outerH={listenOuterH}
        innerW={listenInnerW}
        innerH={listenInnerH}
        wrapperStyle={listenRingWrapperStyle}
        glowStyle={listenGlowStyle}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  ellipseBase: {
    position: 'absolute',
    borderRadius: 99999,
    elevation: 0,
  },
});
