// In-memory store for passing large data (HTML) between screens
// without hitting URL param limits.

let transcript = '';
let artifactHtml = '';

export const SessionStore = {
  setTranscript: (t: string) => {
    transcript = t;
  },
  getTranscript: () => transcript,

  setArtifact: (html: string) => {
    artifactHtml = html;
  },
  getArtifact: () => artifactHtml,

  clear: () => {
    transcript = '';
    artifactHtml = '';
  },
};
