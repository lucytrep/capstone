import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { SessionStore } from '@/store/session';

const C = {
  bg: '#111111',
  inputBg: '#1A1917',
  inputBorder: '#2E2925',
  inputBorderFocus: '#4A3E35',
  amber: '#E8A87C',
  cream: '#F5F0E8',
  muted: '#6B6259',
  buttonDisabled: '#2A2520',
};

export default function HomeScreen() {
  const [text, setText] = useState('');
  const [focused, setFocused] = useState(false);

  const canGenerate = text.trim().length > 0;

  const handleGenerate = () => {
    if (!canGenerate) return;
    SessionStore.setTranscript(text.trim());
    SessionStore.setArtifact('');
    router.push('/generating');
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        style={styles.inner}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <View style={styles.header}>
          <Text style={styles.appName}>Thought Catcher</Text>
          <Text style={styles.tagline}>Describe an idea, get a design artifact</Text>
        </View>

        <View style={styles.body}>
          <View style={[styles.inputWrapper, focused && styles.inputWrapperFocused]}>
            <TextInput
              style={styles.input}
              value={text}
              onChangeText={setText}
              onFocus={() => setFocused(true)}
              onBlur={() => setFocused(false)}
              placeholder="describe your idea..."
              placeholderTextColor={C.muted}
              multiline
              returnKeyType="default"
              autoCorrect
              autoCapitalize="sentences"
              textAlignVertical="top"
            />
          </View>

          <TouchableOpacity
            style={[styles.button, !canGenerate && styles.buttonDisabled]}
            onPress={handleGenerate}
            disabled={!canGenerate}
            activeOpacity={0.75}
          >
            <Feather name="zap" size={16} color={canGenerate ? C.bg : C.muted} />
            <Text style={[styles.buttonText, !canGenerate && styles.buttonTextDisabled]}>
              Generate
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.footer}>
          <Text style={styles.footerText}>Powered by Claude</Text>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  inner: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 28,
    paddingTop: 24,
    paddingBottom: 32,
    gap: 6,
  },
  appName: {
    fontSize: 22,
    fontWeight: '600',
    color: C.cream,
    letterSpacing: 0.3,
  },
  tagline: {
    fontSize: 14,
    color: C.muted,
  },
  body: {
    flex: 1,
    paddingHorizontal: 24,
    gap: 16,
  },
  inputWrapper: {
    borderWidth: 1.5,
    borderColor: C.inputBorder,
    borderRadius: 16,
    backgroundColor: C.inputBg,
    flex: 1,
    maxHeight: 280,
  },
  inputWrapperFocused: {
    borderColor: C.inputBorderFocus,
  },
  input: {
    flex: 1,
    padding: 18,
    fontSize: 17,
    color: C.cream,
    lineHeight: 26,
    minHeight: 120,
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: C.amber,
    borderRadius: 14,
    paddingVertical: 16,
  },
  buttonDisabled: {
    backgroundColor: C.buttonDisabled,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: C.bg,
    letterSpacing: 0.2,
  },
  buttonTextDisabled: {
    color: C.muted,
  },
  footer: {
    paddingBottom: 28,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: C.muted,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
});
