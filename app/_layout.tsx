import { useEffect } from 'react';
import { DarkTheme, ThemeProvider } from '@react-navigation/native';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';

void SplashScreen.preventAutoHideAsync();

export const unstable_settings = {
  anchor: '(tabs)',
};

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    SFProBlack: require('@/assets/fonts/SF-Pro-Text-Black.otf'),
    SFProBold: require('@/assets/fonts/SF-Pro-Text-Bold.otf'),
    SFProHeavy: require('@/assets/fonts/SF-Pro-Text-Heavy.otf'),
    SFProLight: require('@/assets/fonts/SF-Pro-Text-Light.otf'),
    SFProMedium: require('@/assets/fonts/SF-Pro-Text-Medium.otf'),
    SFProRegular: require('@/assets/fonts/SF-Pro-Text-Regular.otf'),
    SFProSemibold: require('@/assets/fonts/SF-Pro-Text-Semibold.otf'),
    SFProThin: require('@/assets/fonts/SF-Pro-Text-Thin.otf'),
    SFProUltralight: require('@/assets/fonts/SF-Pro-Text-Ultralight.otf'),
  });

  useEffect(() => {
    if (fontsLoaded) {
      SplashScreen.hideAsync().catch(() => undefined);
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return null;
  }

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
