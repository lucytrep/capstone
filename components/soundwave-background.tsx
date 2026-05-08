import React, { useEffect, useMemo, useRef } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';

type SoundwaveBackgroundProps = {
  active?: boolean;
};

type WaveBar = {
  left: number;
  width: number;
  height: number;
};

const UPPER_BARS = [0.06, 0.08, 0.1, 0.14, 0.19, 0.25, 0.33, 0.42, 0.56, 0.72, 0.88, 0.78, 0.63, 0.48, 0.35, 0.22, 0.12, 0.08];
const LOWER_BARS = [0.82, 0.92, 0.98, 0.93, 0.86, 0.73, 0.58, 0.44, 0.3, 0.2, 0.14, 0.12, 0.15, 0.21, 0.29, 0.41, 0.56, 0.7, 0.82, 0.92];
const TRAILING_BARS = [0.14, 0.18, 0.24, 0.34, 0.5, 0.68, 0.84, 0.94, 0.86, 0.7, 0.52, 0.36];

function buildBars(values: number[], width: number, gap: number, leftStart: number, scale = 1): WaveBar[] {
  return values.map((value, index) => ({
    left: leftStart + index * gap,
    width,
    height: 28 + value * 220 * scale,
  }));
}

function WaveBand({
  bars,
  top,
  color,
  glowColor,
  opacity,
  xOffset,
  scale,
}: {
  bars: WaveBar[];
  top: number;
  color: string;
  glowColor: string;
  opacity: Animated.AnimatedInterpolation<string | number>;
  xOffset: Animated.AnimatedInterpolation<string | number>;
  scale: Animated.AnimatedInterpolation<string | number>;
}) {
  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.band,
        {
          top,
          opacity,
          transform: [{ translateX: xOffset }],
        },
      ]}
    >
      {bars.map((bar, index) => (
        <React.Fragment key={`${top}-${index}`}>
          <Animated.View
            style={[
              styles.barGlow,
              {
                left: bar.left - 4,
                width: bar.width + 8,
                height: bar.height + 16,
                backgroundColor: glowColor,
                transform: [{ scaleY: scale }],
              },
            ]}
          />
          <Animated.View
            style={[
              styles.bar,
              {
                left: bar.left,
                width: bar.width,
                height: bar.height,
                backgroundColor: color,
                transform: [{ scaleY: scale }],
              },
            ]}
          />
        </React.Fragment>
      ))}
    </Animated.View>
  );
}

export function SoundwaveBackground({ active = false }: SoundwaveBackgroundProps) {
  const drift = useRef(new Animated.Value(0)).current;
  const pulse = useRef(new Animated.Value(0)).current;

  const upperBars = useMemo(() => buildBars(UPPER_BARS, 12, 18, -24, 0.95), []);
  const lowerBars = useMemo(() => buildBars(LOWER_BARS, 14, 17, -16, 1.05), []);
  const trailingBars = useMemo(() => buildBars(TRAILING_BARS, 10, 20, 180, 0.7), []);

  useEffect(() => {
    const driftLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(drift, {
          toValue: 1,
          duration: active ? 2600 : 4200,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
        Animated.timing(drift, {
          toValue: 0,
          duration: active ? 2600 : 4200,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
      ])
    );

    const pulseLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          toValue: 1,
          duration: active ? 1800 : 3000,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulse, {
          toValue: 0,
          duration: active ? 1800 : 3000,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
      ])
    );

    driftLoop.start();
    pulseLoop.start();

    return () => {
      driftLoop.stop();
      pulseLoop.stop();
    };
  }, [active, drift, pulse]);

  const upperX = drift.interpolate({
    inputRange: [0, 1],
    outputRange: [-8, 16],
  });

  const lowerX = drift.interpolate({
    inputRange: [0, 1],
    outputRange: [14, -12],
  });

  const trailingX = drift.interpolate({
    inputRange: [0, 1],
    outputRange: [-14, 24],
  });

  const upperScale = pulse.interpolate({
    inputRange: [0, 0.5, 1],
    outputRange: [0.92, 1.04, 0.97],
  });

  const lowerScale = pulse.interpolate({
    inputRange: [0, 0.5, 1],
    outputRange: [0.95, 1.08, 0.98],
  });

  const trailingScale = pulse.interpolate({
    inputRange: [0, 0.5, 1],
    outputRange: [0.88, 1.02, 0.94],
  });

  const upperOpacity = pulse.interpolate({
    inputRange: [0, 0.5, 1],
    outputRange: [0.48, 0.76, 0.58],
  });

  const lowerOpacity = pulse.interpolate({
    inputRange: [0, 0.5, 1],
    outputRange: [0.58, 0.92, 0.7],
  });

  const trailingOpacity = pulse.interpolate({
    inputRange: [0, 0.5, 1],
    outputRange: [0.2, 0.42, 0.28],
  });

  return (
    <View pointerEvents="none" style={styles.container}>
      <WaveBand
        bars={upperBars}
        top={112}
        color="rgba(255, 248, 252, 0.88)"
        glowColor="rgba(255, 235, 244, 0.22)"
        opacity={upperOpacity}
        xOffset={upperX}
        scale={upperScale}
      />
      <WaveBand
        bars={lowerBars}
        top={308}
        color="rgba(255, 248, 252, 0.96)"
        glowColor="rgba(255, 235, 244, 0.24)"
        opacity={lowerOpacity}
        xOffset={lowerX}
        scale={lowerScale}
      />
      <WaveBand
        bars={trailingBars}
        top={244}
        color="rgba(255, 248, 252, 0.54)"
        glowColor="rgba(255, 235, 244, 0.16)"
        opacity={trailingOpacity}
        xOffset={trailingX}
        scale={trailingScale}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    overflow: 'hidden',
  },
  band: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 280,
  },
  bar: {
    position: 'absolute',
    bottom: 0,
    borderRadius: 999,
  },
  barGlow: {
    position: 'absolute',
    bottom: -8,
    borderRadius: 999,
  },
});
