import { Tabs } from 'expo-router';

// Single-screen app — tabs are hidden, this group just holds the HomeScreen.
export default function TabLayout() {
  return (
    <Tabs screenOptions={{ headerShown: false, tabBarStyle: { display: 'none' } }}>
      <Tabs.Screen name="index" />
    </Tabs>
  );
}
