import React from 'react';
import { Feather } from '@expo/vector-icons';
import { router, usePathname } from 'expo-router';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { IconSymbol } from '@/components/ui/icon-symbol';

const C = {
  nav: '#0D0D0D',
  navBorder: 'rgba(255, 255, 255, 0.14)',
  navShadow: 'rgba(0, 0, 0, 0.48)',
  homeNav: 'rgba(255, 244, 250, 0.12)',
  homeNavBorder: 'rgba(255, 255, 255, 0.42)',
  homeNavShadow: 'rgba(95, 38, 74, 0.26)',
  homeNavGlow: 'rgba(255, 255, 255, 0.16)',
  homeNavShine: 'rgba(255, 255, 255, 0.34)',
  icon: 'rgba(255, 248, 252, 0.86)',
};

type AppTab = {
  key: 'home' | 'library';
  icon: React.ComponentProps<typeof Feather>['name'];
  sfIcon?: React.ComponentProps<typeof IconSymbol>['name'];
  href: string;
};

const TABS: AppTab[] = [
  { key: 'home', icon: 'mic', href: '/' },
  { key: 'library', icon: 'book-open', sfIcon: 'books.vertical.fill', href: '/library' },
];

type AppBottomNavProps = {
  variant?: 'default' | 'home';
};

export function AppBottomNav({ variant = 'default' }: AppBottomNavProps) {
  const pathname = usePathname();
  const { width: windowWidth } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const navWidth = Math.min(windowWidth - 40, 220);
  const isHome = variant === 'home';

  return (
    <View
      pointerEvents="box-none"
      style={[
        styles.bottomNav,
        isHome && styles.bottomNavHome,
        {
          width: navWidth,
          bottom: Math.max(insets.bottom, 10),
        },
      ]}
    >
      {isHome ? <View pointerEvents="none" style={styles.homeGlassOverlay} /> : null}
      {TABS.map((tab) => {
        const isActive =
          (tab.href === '/' && pathname === '/') ||
          (tab.href !== '/' && pathname.startsWith(tab.href));

        return (
          <Pressable
            key={tab.key}
            style={styles.navIcon}
            onPress={() => {
              if (!isActive) {
                router.replace(tab.href as never);
              }
            }}
          >
            {tab.sfIcon ? (
              <IconSymbol name={tab.sfIcon} size={28} color={C.icon} weight="regular" />
            ) : (
              <Feather name={tab.icon} size={24} color={C.icon} />
            )}
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bottomNav: {
    position: 'absolute',
    alignSelf: 'center',
    height: 80,
    borderRadius: 40,
    backgroundColor: C.nav,
    borderWidth: 1,
    borderColor: C.navBorder,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    paddingHorizontal: 14,
    boxShadow: `0 10px 24px ${C.navShadow}`,
  },
  bottomNavHome: {
    backgroundColor: C.homeNav,
    borderColor: C.homeNavBorder,
    boxShadow: `0 14px 28px ${C.homeNavShadow}`,
  },
  homeGlassOverlay: {
    position: 'absolute',
    top: 2,
    left: 2,
    right: 2,
    bottom: 2,
    borderRadius: 38,
    backgroundColor: C.homeNavGlow,
    borderTopWidth: 1,
    borderTopColor: C.homeNavShine,
    borderLeftWidth: 1,
    borderLeftColor: 'rgba(255, 255, 255, 0.14)',
    borderRightWidth: 1,
    borderRightColor: 'rgba(255, 255, 255, 0.08)',
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
  },
  navIcon: {
    width: 62,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 28,
  },
});
