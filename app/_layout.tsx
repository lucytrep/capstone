import { DarkTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';

export const unstable_settings = {
  anchor: '(tabs)',
};

export default function RootLayout() {
  return (
    <ThemeProvider value={DarkTheme}>
      <Stack>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="generating" options={{ headerShown: false, animation: 'fade' }} />
        <Stack.Screen name="output" options={{ headerShown: false, animation: 'slide_from_bottom' }} />
        <Stack.Screen name="settings" options={{ headerShown: false, animation: 'slide_from_right' }} />
        <Stack.Screen name="library/[slug]" options={{ headerShown: false, animation: 'slide_from_right' }} />
        <Stack.Screen
          name="library/collection/[slug]"
          options={{ headerShown: false, animation: 'slide_from_right' }}
        />
      </Stack>
      <StatusBar style="light" />
    </ThemeProvider>
  );
}
