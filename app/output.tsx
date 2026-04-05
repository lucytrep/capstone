import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  SafeAreaView,
  Alert,
  Platform,
} from 'react-native';
import { WebView } from 'react-native-webview';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { SessionStore } from '@/store/session';

const C = {
  bg: '#111111',
  bgCard: '#171614',
  amber: '#E8A87C',
  cream: '#F5F0E8',
  muted: '#6B6259',
  border: '#272320',
  savedGreen: '#7EC8A8',
};

const ARTIFACTS_KEY = 'thought_catcher_artifacts';

type Artifact = {
  id: string;
  transcript: string;
  html: string;
  createdAt: string;
};

export default function OutputScreen() {
  const [saved, setSaved] = useState(false);
  const [saving, setSaving] = useState(false);

  const html = SessionStore.getArtifact();
  const transcript = SessionStore.getTranscript();

  const handleSave = async () => {
    if (saving || saved) return;
    setSaving(true);

    try {
      const artifact: Artifact = {
        id: `artifact_${Date.now()}`,
        transcript,
        html,
        createdAt: new Date().toISOString(),
      };

      const raw = await AsyncStorage.getItem(ARTIFACTS_KEY);
      const existing: Artifact[] = raw ? JSON.parse(raw) : [];
      existing.unshift(artifact);
      await AsyncStorage.setItem(ARTIFACTS_KEY, JSON.stringify(existing));

      setSaved(true);
    } catch (err) {
      console.error('Save failed:', err);
      Alert.alert('Save failed', 'Could not save the artifact. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handleNew = () => {
    SessionStore.clear();
    router.replace('/(tabs)');
  };

  if (!html) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.empty}>
          <Text style={styles.emptyText}>Nothing to show.</Text>
          <TouchableOpacity onPress={handleNew} style={styles.newButtonSmall}>
            <Text style={styles.newButtonSmallText}>Go back</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={handleNew} style={styles.headerButton} hitSlop={12}>
          <Feather name="arrow-left" size={20} color={C.muted} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Artifact</Text>
        <View style={styles.headerButton} />
      </View>

      {/* Transcript pill */}
      {transcript ? (
        <View style={styles.transcriptBar}>
          <Feather name="mic" size={11} color={C.muted} />
          <Text style={styles.transcriptText} numberOfLines={1}>
            {transcript}
          </Text>
        </View>
      ) : null}

      {/* WebView */}
      <WebView
        style={styles.webview}
        source={{ html, baseUrl: '' }}
        originWhitelist={['*']}
        scrollEnabled
        backgroundColor="#ffffff"
        onError={(e) => console.error('[WebView error]', e.nativeEvent)}
        onHttpError={(e) => console.error('[WebView HTTP error]', e.nativeEvent)}
      />

      {/* Save button */}
      <View style={styles.footer}>
        <TouchableOpacity
          style={[
            styles.saveButton,
            saved && styles.saveButtonSaved,
            saving && styles.saveButtonSaving,
          ]}
          onPress={handleSave}
          disabled={saved || saving}
          activeOpacity={0.8}
        >
          <Feather
            name={saved ? 'check' : 'bookmark'}
            size={16}
            color={saved ? C.savedGreen : C.bg}
          />
          <Text style={[styles.saveButtonText, saved && styles.saveButtonTextSaved]}>
            {saving ? 'Saving…' : saved ? 'Saved' : 'Save to Library'}
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: C.border,
  },
  headerButton: {
    width: 32,
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: C.cream,
    letterSpacing: 0.2,
  },
  transcriptBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: C.border,
  },
  transcriptText: {
    flex: 1,
    fontSize: 12,
    color: C.muted,
    fontStyle: 'italic',
  },
  webview: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  footer: {
    padding: 20,
    paddingBottom: Platform.OS === 'ios' ? 12 : 20,
    borderTopWidth: 1,
    borderTopColor: C.border,
  },
  saveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: C.amber,
    borderRadius: 14,
    paddingVertical: 16,
  },
  saveButtonSaved: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: C.savedGreen,
  },
  saveButtonSaving: {
    opacity: 0.6,
  },
  saveButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: C.bg,
    letterSpacing: 0.2,
  },
  saveButtonTextSaved: {
    color: C.savedGreen,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
  },
  emptyText: {
    color: C.muted,
    fontSize: 16,
  },
  newButtonSmall: {
    paddingHorizontal: 20,
    paddingVertical: 10,
  },
  newButtonSmallText: {
    color: C.amber,
    fontSize: 15,
  },
});
