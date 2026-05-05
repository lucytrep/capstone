import Foundation

struct MockArtifactGenerator: ArtifactGenerating {
    func generateArtifact(from prompt: String) async throws -> GeneratedArtifact {
        try await Task.sleep(for: .seconds(2))

        let escapedPrompt = prompt
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let html = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
          <style>
            :root {
              --bg: #0e0d0c;
              --card: #171513;
              --line: rgba(255,255,255,0.08);
              --text: #f6f1ea;
              --muted: #b0a59a;
              --accent: #e8a87c;
            }

            * { box-sizing: border-box; }
            body {
              margin: 0;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
              background:
                radial-gradient(circle at top left, rgba(232,168,124,0.18), transparent 30%),
                linear-gradient(180deg, #12110f 0%, var(--bg) 100%);
              color: var(--text);
              min-height: 100vh;
              padding: 24px;
            }

            .shell {
              max-width: 920px;
              margin: 0 auto;
              display: grid;
              gap: 18px;
            }

            .hero, .grid-card {
              background: var(--card);
              border: 1px solid var(--line);
              border-radius: 28px;
            }

            .hero {
              padding: 28px;
            }

            .eyebrow {
              color: var(--accent);
              letter-spacing: 0.14em;
              font-size: 12px;
              text-transform: uppercase;
            }

            h1 {
              margin: 14px 0 10px;
              font-size: clamp(34px, 6vw, 62px);
              line-height: 0.95;
            }

            p {
              margin: 0;
              color: var(--muted);
              line-height: 1.5;
              font-size: 17px;
            }

            .grid {
              display: grid;
              grid-template-columns: repeat(2, minmax(0, 1fr));
              gap: 18px;
            }

            .grid-card {
              min-height: 180px;
              padding: 22px;
            }

            .swatches {
              display: flex;
              gap: 10px;
              margin-top: 18px;
            }

            .swatch {
              width: 56px;
              height: 56px;
              border-radius: 18px;
              border: 1px solid rgba(255,255,255,0.08);
            }

            .cta-row {
              display: flex;
              gap: 12px;
              margin-top: 20px;
            }

            .cta {
              border-radius: 999px;
              padding: 12px 18px;
              font-weight: 600;
              font-size: 14px;
            }

            .cta.primary {
              background: var(--accent);
              color: #1f1814;
            }

            .cta.secondary {
              border: 1px solid var(--line);
              color: var(--text);
            }

            @media (max-width: 720px) {
              body { padding: 16px; }
              .grid { grid-template-columns: 1fr; }
            }
          </style>
        </head>
        <body>
          <div class="shell">
            <section class="hero">
              <div class="eyebrow">Draft Native Mock</div>
              <h1>Artifact for “\(escapedPrompt)”</h1>
              <p>This is a placeholder HTML artifact rendered inside `WKWebView` so we can preserve parity with the current Expo output flow while we rebuild the service layer safely.</p>
              <div class="cta-row">
                <div class="cta primary">Primary CTA</div>
                <div class="cta secondary">Secondary CTA</div>
              </div>
            </section>
            <section class="grid">
              <article class="grid-card">
                <div class="eyebrow">Palette</div>
                <h2>Warm editorial tones</h2>
                <div class="swatches">
                  <div class="swatch" style="background:#e8a87c"></div>
                  <div class="swatch" style="background:#f4e6d5"></div>
                  <div class="swatch" style="background:#6d5f56"></div>
                  <div class="swatch" style="background:#2c2622"></div>
                </div>
              </article>
              <article class="grid-card">
                <div class="eyebrow">Direction</div>
                <h2>Native rebuild path</h2>
                <p>Next we can replace this mock generator with a real API client and port the output controls from the React Native app.</p>
              </article>
            </section>
          </div>
        </body>
        </html>
        """

        return GeneratedArtifact(html: html)
    }
}
