import React, { useCallback, useEffect, useRef, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  Animated,
  KeyboardAvoidingView,
  Platform,
  SafeAreaView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  ImageBackground,
} from 'react-native';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Voice, {
  SpeechErrorEvent,
  SpeechResultsEvent,
  SpeechStartEvent,
} from '@react-native-voice/voice';
import { AppBottomNav } from '@/components/app-bottom-nav';
import { SessionStore } from '@/store/session';

const C = {
  cardBase: '#E277B8',
  cardActive: '#B74989',
  white: '#FFF8FC',
  softWhite: 'rgba(255, 248, 252, 0.74)',
  softWhiteStrong: 'rgba(255, 248, 252, 0.9)',
  nav: 'rgba(255, 240, 248, 0.22)',
  navBorder: 'rgba(255, 240, 248, 0.32)',
  ring: 'rgba(255, 248, 252, 0.22)',
};

const ONBOARDING_KEY = 'draft.onboarding.seen';

export default function HomeScreen() {
  const [text, setText] = useState('');
  const [focused, setFocused] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [voiceAvailable, setVoiceAvailable] = useState<boolean | null>(null);
  const [voiceStatus, setVoiceStatus] = useState('Speak clearly and pause when finished');
  const [voiceError, setVoiceError] = useState('');
  const [showTypedFallback, setShowTypedFallback] = useState(false);
  const [onboardingReady, setOnboardingReady] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [onboardingStep, setOnboardingStep] = useState(0);
  const pulse = useRef(new Animated.Value(1)).current;
  const isNavigatingRef = useRef(false);
  const transcriptRef = useRef('');
  const inputRef = useRef<TextInput | null>(null);
  const insets = useSafeAreaInsets();

  const triggerGenerate = useCallback((value: string) => {
    const cleaned = value.trim();
    if (!cleaned || isNavigatingRef.current) return;
    isNavigatingRef.current = true;
    SessionStore.setTranscript(cleaned);
    SessionStore.setArtifact('');
    router.push('/generating');
  }, []);

  const bindVoiceListeners = useCallback(() => {
    Voice.onSpeechStart = (_e: SpeechStartEvent) => {
      setIsListening(true);
      setVoiceError('');
      setVoiceStatus('Listening...');
    };

    Voice.onSpeechEnd = () => {
      setIsListening(false);
      const captured = transcriptRef.current.trim();
      if (captured) {
        setVoiceStatus('Voice recording captured. Generating...');
        triggerGenerate(captured);
        return;
      }
      setVoiceStatus((current) =>
        current === 'Listening...' ? 'Voice capture finished.' : current
      );
    };

    Voice.onSpeechResults = (e: SpeechResultsEvent) => {
      const result = e.value?.[0]?.trim();
      if (!result) return;
      transcriptRef.current = result;
      setText(result);
      setVoiceStatus('Voice recording captured.');
    };

    Voice.onSpeechPartialResults = (e: SpeechResultsEvent) => {
      const partial = e.value?.[0]?.trim();
      if (!partial) return;
      transcriptRef.current = partial;
      setText(partial);
    };

    Voice.onSpeechError = (e: SpeechErrorEvent) => {
      const message = e.error?.message || 'Voice recognition failed.';
      transcriptRef.current = '';
      setIsListening(false);
      setVoiceError(message);
      setVoiceStatus('Voice capture failed. Try again.');
      setShowTypedFallback(true);
    };
  }, [triggerGenerate]);

  const checkVoiceAvailability = useCallback(async () => {
    try {
      const available = await Voice.isAvailable();
      setVoiceAvailable(Boolean(available));
      if (!available) {
        setShowTypedFallback(true);
        setVoiceStatus('Voice is unavailable here. Type a prompt to test instead.');
      }
    } catch {
      setVoiceAvailable(false);
      setShowTypedFallback(true);
      setVoiceStatus('Voice is unavailable here. Type a prompt to test instead.');
    }
  }, []);

  const resetVoiceEngine = useCallback(async () => {
    try {
      await Voice.cancel();
    } catch {}

    try {
      await Voice.stop();
    } catch {}

    try {
      await Voice.destroy();
    } catch {}

    Voice.removeAllListeners();
    bindVoiceListeners();
    await checkVoiceAvailability();
  }, [bindVoiceListeners, checkVoiceAvailability]);

  useFocusEffect(
    useCallback(() => {
      isNavigatingRef.current = false;
      transcriptRef.current = '';
      setText('');
      setFocused(false);
      setIsListening(false);
      setVoiceError('');
      setVoiceStatus('Speak clearly and pause when finished');
      pulse.stopAnimation();
      pulse.setValue(1);
      resetVoiceEngine().catch((error) => {
        console.error('Voice reset failed on focus:', error);
      });

      return () => {
        Voice.cancel().catch(() => undefined);
        Voice.stop().catch(() => undefined);
      };
    }, [pulse, resetVoiceEngine])
  );

  useEffect(() => {
    AsyncStorage.getItem(ONBOARDING_KEY)
      .then((value) => {
        setShowOnboarding(value !== 'true');
      })
      .finally(() => {
        setOnboardingReady(true);
      });
  }, []);

  useEffect(() => {
    resetVoiceEngine().catch((error) => {
      console.error('Initial voice reset failed:', error);
    });

    return () => {
      Voice.destroy().then(Voice.removeAllListeners).catch(() => {
        Voice.removeAllListeners();
      });
    };
  }, [resetVoiceEngine]);

  useEffect(() => {
    if (!isListening) {
      pulse.stopAnimation();
      pulse.setValue(1);
      return;
    }

    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          toValue: 1.08,
          duration: 900,
          useNativeDriver: true,
        }),
        Animated.timing(pulse, {
          toValue: 1,
          duration: 900,
          useNativeDriver: true,
        }),
      ])
    );

    animation.start();
    return () => animation.stop();
  }, [isListening, pulse]);

  const handleMicPress = async () => {
    if (showOnboarding) {
      return;
    }

    if (voiceAvailable === false) {
      setShowTypedFallback(true);
      setVoiceStatus('Voice is unavailable here. Type a prompt to test instead.');
      inputRef.current?.focus();
      return;
    }

    try {
      setVoiceError('');

      if (isListening) {
        await Voice.stop();
        return;
      }

      await resetVoiceEngine();
      transcriptRef.current = '';
      setText('');
      setVoiceStatus('Starting microphone...');
      await Voice.start('en-US');
    } catch (error) {
      console.error('Voice start/stop error:', error);
      setIsListening(false);
      setVoiceError('Could not start voice recognition.');
      setVoiceStatus('Voice capture failed. Try again.');
      setShowTypedFallback(true);
      inputRef.current?.focus();
    }
  };

  const completeOnboarding = async () => {
    setShowOnboarding(false);
    try {
      await AsyncStorage.setItem(ONBOARDING_KEY, 'true');
    } catch (error) {
      console.error('Failed to persist onboarding state:', error);
    }
  };

  const advanceOnboarding = () => {
    if (onboardingStep === 0) {
      setOnboardingStep(1);
      return;
    }

    completeOnboarding().catch(() => undefined);
  };

  const promptText =
    text.trim().length > 0
      ? text.trim()
      : focused
        ? ''
        : 'Tap to dictate';

  return (
    <View style={styles.container}>
      <ImageBackground
        source={require('../../assets/images/home-bg.jpg')}
        style={styles.backgroundImage}
        resizeMode="cover"
      >
        <SafeAreaView style={styles.safeArea}>
          <KeyboardAvoidingView
            style={styles.inner}
            behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          >
            <View
              style={[
                styles.card,
                isListening && styles.cardListening,
                {
                  paddingTop: Math.max(insets.top, 18) + 14,
                  paddingBottom: 128 + Math.max(insets.bottom, 10),
                },
              ]}
            >
              <Text style={styles.brand}>Draft</Text>

              <View style={styles.promptArea}>
                <Text style={[styles.promptText, !text.trim() && styles.promptPlaceholder]}>
                  {promptText}
                </Text>
                <Text style={styles.statusText}>{voiceStatus}</Text>
                {voiceError ? <Text style={styles.errorText}>{voiceError}</Text> : null}
              </View>

              <TextInput
                ref={inputRef}
                style={showTypedFallback ? styles.fallbackInput : styles.hiddenInput}
                value={text}
                onChangeText={setText}
                onFocus={() => setFocused(true)}
                onBlur={() => setFocused(false)}
                placeholder={showTypedFallback ? 'Type a prompt to test in Simulator' : 'Tap to dictate'}
                placeholderTextColor={showTypedFallback ? 'rgba(255, 248, 252, 0.56)' : 'transparent'}
                multiline
                autoCorrect
                autoCapitalize="sentences"
              />

              {showTypedFallback ? (
                <View style={styles.fallbackComposer}>
                  <TouchableOpacity
                    onPress={() => triggerGenerate(text)}
                    style={[styles.fallbackGenerateButton, !text.trim() && styles.fallbackGenerateButtonDisabled]}
                    disabled={!text.trim()}
                    activeOpacity={0.85}
                  >
                    <Text style={styles.fallbackGenerateButtonText}>Generate from text</Text>
                  </TouchableOpacity>
                </View>
              ) : null}

              <View style={styles.micArea}>
                <Animated.View style={[styles.micRing, { transform: [{ scale: pulse }] }]}>
                  <TouchableOpacity
                    style={[styles.micButton, isListening && styles.micButtonActive]}
                    onPress={handleMicPress}
                    activeOpacity={0.85}
                  >
                    <Feather name="mic" size={30} color={C.white} />
                  </TouchableOpacity>
                </Animated.View>
                <Text style={styles.recordingText}>
                  {isListening ? 'Tap the mic again to stop' : 'Tap the mic to begin'}
                </Text>
              </View>
            </View>
          </KeyboardAvoidingView>
          <AppBottomNav variant="home" />
          {onboardingReady && showOnboarding ? (
            <View style={styles.onboardingOverlay}>
              <View style={styles.onboardingCard}>
                <Text style={styles.onboardingEyebrow}>
                  {onboardingStep === 0 ? 'Welcome to Draft' : 'How it works'}
                </Text>
                <Text style={styles.onboardingTitle}>
                  {onboardingStep === 0
                    ? 'Speak the direction you want to explore'
                    : 'We turn your prompt into visual directions you can compare'}
                </Text>
                <Text style={styles.onboardingBody}>
                  {onboardingStep === 0
                    ? 'Describe a moodboard, palette, UI direction, or photo concept, then tap the mic to start generating.'
                    : 'Use the library to review boards, open details, and compare multiple routes before choosing what to keep.'}
                </Text>

                <View style={styles.onboardingDots}>
                  {[0, 1].map((index) => (
                    <View
                      key={`onboarding-dot-${index}`}
                      style={[
                        styles.onboardingDot,
                        onboardingStep === index && styles.onboardingDotActive,
                      ]}
                    />
                  ))}
                </View>

                <View style={styles.onboardingActions}>
                  <TouchableOpacity onPress={() => completeOnboarding()} style={styles.onboardingSecondary}>
                    <Text style={styles.onboardingSecondaryText}>Skip</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={advanceOnboarding} style={styles.onboardingPrimary}>
                    <Text style={styles.onboardingPrimaryText}>
                      {onboardingStep === 0 ? 'Next' : 'Got it'}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          ) : null}
        </SafeAreaView>
      </ImageBackground>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4B2D6',
  },
  backgroundImage: {
    flex: 1,
  },
  safeArea: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  inner: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  card: {
    flex: 1,
    paddingHorizontal: 28,
    paddingTop: 32,
    paddingBottom: 12,
    backgroundColor: 'transparent',
    overflow: 'hidden',
  },
  cardListening: {
    backgroundColor: 'rgba(126, 34, 88, 0.14)',
  },
  brand: {
    fontSize: 28,
    lineHeight: 32,
    fontWeight: '700',
    color: C.white,
  },
  promptArea: {
    paddingTop: 32,
    paddingBottom: 18,
    minHeight: 190,
    alignItems: 'center',
  },
  promptText: {
    fontSize: 17,
    lineHeight: 21,
    fontWeight: '400',
    color: C.white,
    textAlign: 'center',
    maxWidth: '84%',
  },
  promptPlaceholder: {
    opacity: 0.96,
  },
  statusText: {
    marginTop: 12,
    fontSize: 14,
    lineHeight: 19,
    color: C.softWhite,
    textAlign: 'center',
  },
  errorText: {
    marginTop: 8,
    fontSize: 14,
    lineHeight: 19,
    color: '#FFE2E8',
    textAlign: 'center',
  },
  hiddenInput: {
    position: 'absolute',
    opacity: 0,
    width: 1,
    height: 1,
  },
  fallbackInput: {
    minHeight: 120,
    borderRadius: 22,
    paddingHorizontal: 18,
    paddingVertical: 16,
    backgroundColor: 'rgba(255, 248, 252, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255, 248, 252, 0.16)',
    color: C.white,
    fontSize: 16,
    lineHeight: 22,
    textAlignVertical: 'top',
  },
  fallbackComposer: {
    alignItems: 'center',
    paddingTop: 16,
  },
  fallbackGenerateButton: {
    borderRadius: 18,
    paddingVertical: 13,
    paddingHorizontal: 18,
    minWidth: 168,
    alignItems: 'center',
    backgroundColor: C.white,
  },
  fallbackGenerateButtonDisabled: {
    opacity: 0.45,
  },
  fallbackGenerateButtonText: {
    color: '#8A2960',
    fontSize: 15,
    fontWeight: '700',
  },
  micArea: {
    alignItems: 'center',
    paddingTop: 34,
  },
  micRing: {
    width: 104,
    height: 104,
    borderRadius: 52,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: C.ring,
    borderWidth: 1,
    borderColor: 'rgba(255, 248, 252, 0.2)',
  },
  micButton: {
    width: 76,
    height: 76,
    borderRadius: 38,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 248, 252, 0.08)',
  },
  micButtonActive: {
    backgroundColor: 'rgba(255, 248, 252, 0.16)',
  },
  recordingText: {
    marginTop: 42,
    fontSize: 15,
    color: C.softWhite,
  },
  onboardingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(28, 6, 21, 0.42)',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  onboardingCard: {
    width: '100%',
    borderRadius: 28,
    paddingHorizontal: 22,
    paddingVertical: 24,
    backgroundColor: 'rgba(131, 54, 95, 0.92)',
    borderWidth: 1,
    borderColor: 'rgba(255, 248, 252, 0.16)',
    gap: 12,
  },
  onboardingEyebrow: {
    fontSize: 13,
    lineHeight: 16,
    fontWeight: '600',
    color: C.softWhiteStrong,
  },
  onboardingTitle: {
    fontSize: 24,
    lineHeight: 29,
    fontWeight: '700',
    color: C.white,
  },
  onboardingBody: {
    fontSize: 15,
    lineHeight: 22,
    color: C.softWhiteStrong,
  },
  onboardingDots: {
    flexDirection: 'row',
    gap: 8,
    paddingTop: 4,
  },
  onboardingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(255, 248, 252, 0.32)',
  },
  onboardingDotActive: {
    width: 18,
    backgroundColor: C.white,
  },
  onboardingActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 12,
    paddingTop: 8,
  },
  onboardingSecondary: {
    paddingVertical: 10,
    paddingHorizontal: 6,
  },
  onboardingSecondaryText: {
    color: C.softWhiteStrong,
    fontSize: 15,
    fontWeight: '600',
  },
  onboardingPrimary: {
    borderRadius: 18,
    paddingVertical: 12,
    paddingHorizontal: 18,
    backgroundColor: C.white,
  },
  onboardingPrimaryText: {
    color: '#7E2255',
    fontSize: 15,
    fontWeight: '700',
  },
});
