// Read API keys from local Expo environment files so the repo can stay secret-free.
const readEnv = (value: string | undefined) => value?.trim() ?? '';

export const ANTHROPIC_API_KEY = readEnv(process.env.EXPO_PUBLIC_ANTHROPIC_API_KEY);
export const PEXELS_API_KEY = readEnv(process.env.EXPO_PUBLIC_PEXELS_API_KEY);
export const UNSPLASH_ACCESS_KEY = readEnv(process.env.EXPO_PUBLIC_UNSPLASH_ACCESS_KEY);
export const GEMINI_API_KEY = readEnv(process.env.EXPO_PUBLIC_GEMINI_API_KEY);
// URL of the local pinterest-service (e.g. http://localhost:8765 during dev)
export const PINTEREST_SERVICE_URL = readEnv(process.env.EXPO_PUBLIC_PINTEREST_SERVICE_URL);
export const COSMOS_API_KEY = readEnv(process.env.EXPO_PUBLIC_COSMOS_API_KEY);
