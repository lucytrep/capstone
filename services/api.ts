import { ANTHROPIC_API_KEY } from '@/config/keys';

const CLAUDE_MODEL = 'claude-sonnet-4-6';

const SYSTEM_PROMPT = `You are a design artifact generator. The user will describe a design idea. You must ALWAYS respond with only valid HTML and CSS - never text, never questions, never explanations. Generate the appropriate artifact type based on what they describe: UI screens, branding/color palettes, user journey maps, deck layouts, notes, code snippets, or animations. Always return a complete, beautiful, self-contained HTML document with embedded CSS. Never ask for clarification. Just build it. Start your response directly with <!DOCTYPE html> and nothing else.`;

/**
 * Send a text transcript to Claude and get back a self-contained HTML design artifact.
 */
export async function generateArtifact(transcript: string): Promise<string> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: transcript }],
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Claude API error (${response.status}): ${error}`);
  }

  const data = await response.json();
  const text: string = data.content[0].text;

  console.log('[Claude raw response]', text);

  // 1. Strip opening fence (```html or ``` with optional whitespace/newline)
  // 2. Strip closing fence
  // 3. Drop any remaining text before the first < so the document always
  //    starts with <!DOCTYPE, <html, or <div — never prose.
  let cleaned = text
    .replace(/^```html\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();

  const firstTag = cleaned.indexOf('<');
  if (firstTag > 0) {
    cleaned = cleaned.slice(firstTag);
  }

  console.log('[Claude cleaned HTML — first 300 chars]', cleaned.slice(0, 300));

  return cleaned;
}
