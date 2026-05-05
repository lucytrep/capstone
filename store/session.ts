import AsyncStorage from '@react-native-async-storage/async-storage';

const TRANSCRIPT_KEY = 'draft.session.transcript';
const ARTIFACT_KEY = 'draft.session.artifact';

let transcript = '';
let artifactHtml = '';
let hydrationPromise: Promise<void> | null = null;

async function hydrateFromStorage() {
  try {
    const [storedTranscript, storedArtifact] = await Promise.all([
      AsyncStorage.getItem(TRANSCRIPT_KEY),
      AsyncStorage.getItem(ARTIFACT_KEY),
    ]);

    transcript = storedTranscript ?? '';
    artifactHtml = storedArtifact ?? '';
  } catch (error) {
    console.error('Session hydration failed:', error);
  }
}

function ensureHydration() {
  if (!hydrationPromise) {
    hydrationPromise = hydrateFromStorage();
  }

  return hydrationPromise;
}

void ensureHydration();

export const SessionStore = {
  hydrate: () => ensureHydration(),

  setTranscript: (value: string) => {
    transcript = value;
    AsyncStorage.setItem(TRANSCRIPT_KEY, value).catch((error) => {
      console.error('Failed to persist transcript:', error);
    });
  },

  getTranscript: () => transcript,

  setArtifact: (html: string) => {
    artifactHtml = html;
    AsyncStorage.setItem(ARTIFACT_KEY, html).catch((error) => {
      console.error('Failed to persist artifact:', error);
    });
  },

  getArtifact: () => artifactHtml,

  clear: () => {
    transcript = '';
    artifactHtml = '';
    AsyncStorage.multiRemove([TRANSCRIPT_KEY, ARTIFACT_KEY]).catch((error) => {
      console.error('Failed to clear session:', error);
    });
  },
};
