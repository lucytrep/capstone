import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  Alert,
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
import { SessionStore } from '@/store/session';

const C = {
  cardBase: '#E277B8',
  cardActive: '#B74989',
  white: '#FFF8FC',
  softWhite: 'rgba(255, 248, 252, 0.74)',
  nav: 'rgba(255, 240, 248, 0.22)',
  navBorder: 'rgba(255, 240, 248, 0.32)',
  ring: 'rgba(255, 248, 252, 0.22)',
};

export default function HomeScreen() {
  const [text, setText] = useState('');
  const [focused, setFocused] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [voiceAvailable, setVoiceAvailable] = useState<boolean | null>(null);
  const [voiceStatus, setVoiceStatus] = useState('Speak clearly and pause when finished');
  const [voiceError, setVoiceError] = useState('');
  const pulse = useRef(new Animated.Value(1)).current;
  const isNavigatingRef = useRef(false);
  const transcriptRef = useRef('');
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
    };
  }, [triggerGenerate]);

  const checkVoiceAvailability = useCallback(async () => {
    try {
      const available = await Voice.isAvailable();
      setVoiceAvailable(Boolean(available));
    } catch {
      setVoiceAvailable(false);
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
    if (voiceAvailable === false) {
      Alert.alert('Voice unavailable', 'Speech recognition is not available on this device yet.');
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
    }
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
                  paddingBottom: Math.max(insets.bottom, 12) + 12,
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
            style={styles.hiddenInput}
            value={text}
            onChangeText={setText}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            placeholder="Tap to dictate"
            placeholderTextColor="transparent"
            multiline
            autoCorrect
            autoCapitalize="sentences"
          />

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

          <View style={styles.bottomNav}>
            <TouchableOpacity style={styles.navIcon}>
              <Feather name="mic" size={22} color={C.white} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.navIcon}>
              <Feather name="bar-chart-2" size={22} color={C.white} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.navIcon}>
              <Feather name="user" size={22} color={C.white} />
            </TouchableOpacity>
          </View>
            </View>
          </KeyboardAvoidingView>
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
    paddingTop: 102,
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
  bottomNav: {
    marginTop: 'auto',
    height: 58,
    borderRadius: 29,
    backgroundColor: C.nav,
    borderWidth: 1,
    borderColor: C.navBorder,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
  },
  navIcon: {
    width: 52,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
