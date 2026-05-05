import React from 'react';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import {
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

const C = {
  bg: '#000000',
  panel: '#151515',
  border: 'rgba(255, 255, 255, 0.08)',
  text: '#FFF8FC',
  muted: 'rgba(255, 255, 255, 0.62)',
};

const GENERAL_ROWS = [
  { icon: 'bookmark', label: 'Saved' },
  { icon: 'sliders', label: 'Output' },
  { icon: 'shield', label: 'Privacy' },
];

export default function SettingsScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.topBar}>
          <Pressable onPress={() => router.back()} style={styles.iconButton} hitSlop={10}>
            <Feather name="chevron-left" size={20} color={C.text} />
          </Pressable>
          <Text style={styles.topBarTitle}>Settings</Text>
          <View style={styles.iconButtonPlaceholder} />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>General</Text>
          <View style={styles.settingsList}>
            {GENERAL_ROWS.map((row, index) => (
              <View
                key={row.label}
                style={[styles.settingsRow, index < GENERAL_ROWS.length - 1 && styles.rowDivider]}
              >
                <View style={styles.settingsIconWrap}>
                  <Feather name={row.icon as React.ComponentProps<typeof Feather>['name']} size={16} color={C.text} />
                </View>
                <Text style={styles.settingsLabel}>{row.label}</Text>
                <Feather name="chevron-right" size={16} color={C.muted} />
              </View>
            ))}
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Preferences</Text>
          <View style={styles.settingsList}>
            {['Notifications', 'Appearance'].map((label, index) => (
              <View
                key={label}
                style={[styles.settingsRow, index < 1 && styles.rowDivider]}
              >
                <Text style={styles.settingsLabel}>{label}</Text>
                <Feather name="chevron-right" size={16} color={C.muted} />
              </View>
            ))}
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: C.bg,
  },
  scrollView: {
    flex: 1,
  },
  content: {
    paddingHorizontal: 22,
    paddingTop: 18,
    paddingBottom: 42,
    gap: 22,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  topBarTitle: {
    fontSize: 16,
    lineHeight: 20,
    fontWeight: '600',
    color: C.text,
  },
  iconButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: C.border,
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconButtonPlaceholder: {
    width: 40,
    height: 40,
  },
  section: {
    gap: 12,
  },
  sectionTitle: {
    fontSize: 29,
    lineHeight: 34,
    fontWeight: '700',
    color: C.text,
  },
  settingsList: {
    borderRadius: 26,
    backgroundColor: C.panel,
    borderWidth: 1,
    borderColor: C.border,
    overflow: 'hidden',
  },
  settingsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 14,
    paddingHorizontal: 18,
    paddingVertical: 18,
  },
  rowDivider: {
    borderBottomWidth: 1,
    borderBottomColor: C.border,
  },
  settingsIconWrap: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: 'rgba(255, 255, 255, 0.06)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  settingsLabel: {
    flex: 1,
    fontSize: 17,
    lineHeight: 21,
    fontWeight: '600',
    color: C.text,
  },
});
