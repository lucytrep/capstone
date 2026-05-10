#!/usr/bin/env node

require('dotenv').config();

const query = process.argv[2];
const cookie = process.env.PINTEREST_SESSION_COOKIE ?? '';

if (!query) {
  console.error('Usage: node pinterest-scraper.js "<search query>"');
  console.error('  Set PINTEREST_SESSION_COOKIE in .env before running.');
  process.exit(1);
}

const params = new URLSearchParams({
  source_url: `/search/pins/?q=${encodeURIComponent(query)}`,
  data: JSON.stringify({
    options: {
      query,
      scope: 'pins',
      page_size: 8,
    },
    context: {},
  }),
});

const url = `https://www.pinterest.com/resource/BaseSearchResource/get/?${params}`;

async function run() {
  const csrfToken = cookie.match(/csrftoken=([^;]+)/)?.[1] ?? '';

  const headers = {
    'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    Accept: 'application/json, text/javascript, */*, q=0.01',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'X-Requested-With': 'XMLHttpRequest',
    'X-CSRFToken': csrfToken,
    'X-Pinterest-AppState': 'active',
    Referer: `https://www.pinterest.com/search/pins/?q=${encodeURIComponent(query)}`,
    Origin: 'https://www.pinterest.com',
  };

  if (cookie) {
    headers['Cookie'] = cookie;
  }

  const response = await fetch(url, { headers });

  if (!response.ok) {
    throw new Error(`Request failed: ${response.status} ${response.statusText}`);
  }

  const json = await response.json();
  const results = json?.resource_response?.data?.results ?? [];

  if (results.length === 0) {
    console.log('No results found.');
    return;
  }

  console.log(`Results for "${query}":\n`);
  results.slice(0, 5).forEach((pin, i) => {
    const url =
      pin?.images?.orig?.url ??
      pin?.images?.['736x']?.url ??
      pin?.images?.['474x']?.url ??
      null;
    const title = pin?.title || pin?.description || '(no title)';
    console.log(`${i + 1}. ${title}`);
    console.log(`   ${url ?? '(no image url found)'}`);
  });
}

run().catch((err) => {
  console.error('Error:', err.message);
  process.exit(1);
});
