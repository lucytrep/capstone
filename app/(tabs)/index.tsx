import React, { useCallback, useEffect, useRef, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Haptics from 'expo-haptics';
import {
  KeyboardAvoidingView,
  SafeAreaView,
  Platform,
  Pressable,
  StyleSheet,
  type TextInput as RNTextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { router } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Voice, {
  SpeechErrorEvent,
  SpeechResultsEvent,
  SpeechStartEvent,
} from '@react-native-voice/voice';
import {
  AppText as Text,
  AppTextInput as TextInput,
  getSFProRoundedFontFamily,
} from '@/components/app-typography';
import { AppBottomNav } from '@/components/app-bottom-nav';
import { DictationRippleBackground } from '@/components/dictation-ripple-background';
import { OnboardingSwipeIntro } from '@/components/onboarding-swipe-intro';
import { SessionStore } from '@/store/session';

const C = {
  white: '#FFFFFF',
};

const ONBOARDING_KEY = 'draft.onboarding.seen';

/** Web dev reload behavior differs; iOS/Android persist “seen” across tab visits and remounts. */
const onboardingPersistsAcrossReload =
  Platform.OS === 'ios' || Platform.OS === 'android';

export default function HomeScreen() {
  const [text, setText] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [voiceAvailable, setVoiceAvailable] = useState<boolean | null>(null);
  const [voiceError, setVoiceError] = useState('');
  const [showTypedFallback, setShowTypedFallback] = useState(false);
  const [onboardingReady, setOnboardingReady] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [pressActive, setPressActive] = useState(false);
  const isNavigatingRef = useRef(false);
  const holdActiveRef = useRef(false);
  const transcriptRef = useRef('');
  const inputRef = useRef<RNTextInput | null>(null);
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
    };

    Voice.onSpeechEnd = () => {
      setIsListening(false);
      const captured = transcriptRef.current.trim();
      if (captured) {
        triggerGenerate(captured);
      }
    };

    Voice.onSpeechResults = (e: SpeechResultsEvent) => {
      const result = e.value?.[0]?.trim();
      if (!result) return;
      transcriptRef.current = result;
      setText(result);
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
      setPressActive(false);
      setVoiceError(message);
      setShowTypedFallback(true);
    };
  }, [triggerGenerate]);

  const checkVoiceAvailability = useCallback(async () => {
    try {
      const available = await Voice.isAvailable();
      setVoiceAvailable(Boolean(available));
      if (!available) {
        setShowTypedFallback(true);
      }
    } catch {
      setVoiceAvailable(false);
      setShowTypedFallback(true);
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
      holdActiveRef.current = false;
      transcriptRef.current = '';
      setText('');
      setIsListening(false);
      setPressActive(false);
      setVoiceError('');
      resetVoiceEngine().catch((error) => {
        console.error('Voice reset failed on focus:', error);
      });

      return () => {
        Voice.cancel().catch(() => undefined);
        Voice.stop().catch(() => undefined);
      };
    }, [resetVoiceEngine])
  );

  useEffect(() => {
    if (!onboardingPersistsAcrossReload) {
      setShowOnboarding(true);
      setOnboardingReady(true);
      return;
    }
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

  const handleHoldStart = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (showOnboarding) {
      return;
    }

    if (voiceAvailable === false) {
      setShowTypedFallback(true);
      inputRef.current?.focus();
      return;
    }

    if (holdActiveRef.current) {
      return;
    }
    holdActiveRef.current = true;

    try {
      setVoiceError('');
      await resetVoiceEngine();
      transcriptRef.current = text.trim();
      await Voice.start('en-US');
    } catch (error) {
      console.error('Voice start error:', error);
      holdActiveRef.current = false;
      setPressActive(false);
      setIsListening(false);
      setVoiceError('Could not start voice recognition.');
      setShowTypedFallback(true);
      inputRef.current?.focus();
    }
  };

  const handleHoldEnd = async () => {
    setPressActive(false);
    if (!holdActiveRef.current) {
      return;
    }
    holdActiveRef.current = false;

    try {
      await Voice.stop();
    } catch (error) {
      console.error('Voice stop error:', error);
    }
  };

  const completeOnboarding = async () => {
    setShowOnboarding(false);
    if (!onboardingPersistsAcrossReload) {
      return;
    }
    try {
      await AsyncStorage.setItem(ONBOARDING_KEY, 'true');
    } catch (error) {
      console.error('Failed to persist onboarding state:', error);
    }
  };

  const centerMainText =
    text.trim().length > 0
      ? text.trim()
      : pressActive || isListening
        ? 'Listening....'
        : 'Press and hold\nto dictate';

  const centerIsPlaceholder = !text.trim() && !pressActive && !isListening;

  return (
    <View style={styles.container}>
      <DictationRippleBackground listening={pressActive || isListening} />
      <SafeAreaView style={styles.safeArea}>
        <KeyboardAvoidingView
          style={styles.inner}
          behavior={Platform.OS === 'ios' && showTypedFallback ? 'padding' : undefined}
        >
          <View
            style={[
              styles.content,
              {
                paddingTop: Math.max(insets.top, 18) + 8,
                paddingBottom: 120 + Math.max(insets.bottom, 10),
              },
            ]}
          >
            <Text style={styles.draftTitle}>Draft</Text>

            <View style={styles.dictationTopFlex} />

            <View style={styles.glowWrap}>
              <Pressable
                style={styles.glowPressable}
                onPressIn={() => {
                  if (showOnboarding) {
                    return;
                  }
                  if (voiceAvailable === false) {
                    setShowTypedFallback(true);
                    inputRef.current?.focus();
                    return;
                  }
                  setPressActive(true);
                  handleHoldStart().catch((error) => {
                    console.error('Hold start failed:', error);
                    setPressActive(false);
                  });
                }}
                onPressOut={() => {
                  handleHoldEnd().catch((error) => {
                    console.error('Hold end failed:', error);
                  });
                }}
                accessibilityRole="button"
                accessibilityLabel="Dictation"
                accessibilityHint="Press and hold to speak your prompt"
              />
            </View>

            <View style={styles.dictationBottomFlex} />

            <View style={styles.instructionColumn}>
              <Text
                style={[
                  styles.centerText,
                  centerIsPlaceholder ? styles.centerPlaceholder : styles.centerListeningSlot,
                ]}
              >
                {centerMainText}
              </Text>

              {voiceError ? <Text style={styles.errorText}>{voiceError}</Text> : null}

              <TextInput
                ref={inputRef}
                style={showTypedFallback ? styles.fallbackInput : styles.hiddenInput}
                value={text}
                onChangeText={setText}
                placeholder={
                  showTypedFallback ? 'Type a prompt to test in Simulator' : 'Press and hold to dictate'
                }
                placeholderTextColor={showTypedFallback ? 'rgba(255, 255, 255, 0.5)' : 'transparent'}
                multiline
                autoCorrect
                autoCapitalize="sentences"
              />

              {showTypedFallback ? (
                <View style={styles.fallbackComposer}>
                  <TouchableOpacity
                    onPress={() => {
                      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                      triggerGenerate(text);
                    }}
                    style={[
                      styles.fallbackGenerateButton,
                      !text.trim() && styles.fallbackGenerateButtonDisabled,
                    ]}
                    disabled={!text.trim()}
                    activeOpacity={0.85}
                  >
                    <Text style={styles.fallbackGenerateButtonText}>Generate from text</Text>
                  </TouchableOpacity>
                </View>
              ) : null}
            </View>
          </View>
        </KeyboardAvoidingView>
        <AppBottomNav variant="default" />
      </SafeAreaView>
      {onboardingReady && showOnboarding ? (
        <OnboardingSwipeIntro
          bottomInset={insets.bottom}
          onComplete={() => {
            completeOnboarding();
          }}
        />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  safeArea: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  inner: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  content: {
    flex: 1,
    paddingHorizontal: 28,
  },
  draftTitle: {
    fontSize: 40,
    lineHeight: 46,
    fontFamily: getSFProRoundedFontFamily('700'),
    color: C.white,
    textAlign: 'center',
  },
  dictationTopFlex: {
    flex: 1.1,
    minHeight: 0,
  },
  dictationBottomFlex: {
    flex: 1.35,
    minHeight: 0,
  },
  instructionColumn: {
    alignItems: 'center',
    width: '100%',
    // ~3rem @ 16px — lift copy away from bottom nav
    marginBottom: 48,
  },
  glowWrap: {
    width: 320,
    height: 320,
    alignItems: 'center',
    justifyContent: 'center',
  },
  glowPressable: {
    width: 280,
    height: 280,
    borderRadius: 140,
  },
  centerText: {
    fontSize: 18,
    lineHeight: 24,
    fontFamily: getSFProRoundedFontFamily('400'),
    color: C.white,
    textAlign: 'center',
    paddingHorizontal: 12,
    maxWidth: '92%',
    minHeight: 56,
  },
  centerPlaceholder: {
    fontSize: 20,
    fontFamily: getSFProRoundedFontFamily('500'),
    opacity: 0.95,
  },
  centerListeningSlot: {
    fontSize: 20,
    lineHeight: 26,
    fontFamily: getSFProRoundedFontFamily('500'),
  },
  errorText: {
    marginTop: 4,
    fontSize: 14,
    lineHeight: 19,
    fontFamily: getSFProRoundedFontFamily('500'),
    color: 'rgba(255, 200, 200, 0.95)',
    textAlign: 'center',
    paddingHorizontal: 12,
  },
  hiddenInput: {
    position: 'absolute',
    opacity: 0,
    width: 1,
    height: 1,
  },
  fallbackInput: {
    marginTop: 8,
    width: '100%',
    minHeight: 120,
    borderRadius: 22,
    paddingHorizontal: 18,
    paddingVertical: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.09)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.16)',
    color: C.white,
    fontSize: 16,
    lineHeight: 22,
    fontFamily: getSFProRoundedFontFamily('400'),
    textAlignVertical: 'top',
  },
  fallbackComposer: {
    alignItems: 'center',
    paddingTop: 12,
    width: '100%',
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
    color: '#2A0620',
    fontSize: 15,
    fontFamily: getSFProRoundedFontFamily('700'),
  },
});
