"""
Pinterest search microservice for DraftNative.

Wraps the pinterest-scrapy-scraper and exposes a simple JSON endpoint
that the React Native app can call while generating photo artifacts.

Run:
    cd pinterest-service
    SCRAPEOPS_API_KEY=your_key_here python server.py

Endpoint:
    GET /search?q=desert+editorial&max=8
    → { "photos": [ { id, imageUrl, thumbUrl, alt, source, author, detailUrl }, ... ] }
"""

import asyncio
import json
import os
import sys
import tempfile

import uvicorn
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Pinterest Search Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)

SCRAPER_DIR = os.path.join(os.path.dirname(__file__), "scraper")
SCRAPEOPS_API_KEY = os.environ.get("SCRAPEOPS_API_KEY", "")


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "scrapeops_configured": bool(SCRAPEOPS_API_KEY),
    }


@app.get("/search")
async def search(
    q: str = Query(..., description="Search query"),
    max: int = Query(10, ge=1, le=30, description="Max results"),
):
    if not SCRAPEOPS_API_KEY:
        return {"photos": [], "error": "SCRAPEOPS_API_KEY not set"}

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            output_file = os.path.join(tmpdir, "results.json")

            env = {**os.environ, "SCRAPEOPS_API_KEY": SCRAPEOPS_API_KEY}

            proc = await asyncio.create_subprocess_exec(
                sys.executable,
                "-m",
                "scrapy",
                "crawl",
                "pinterest_search",
                "-a",
                f"search_query={q}",
                "-a",
                "search_type=pins",
                "-a",
                f"max_results={max}",
                "-o",
                output_file,
                "-L",
                "ERROR",
                cwd=SCRAPER_DIR,
                env=env,
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL,
            )

            try:
                await asyncio.wait_for(proc.communicate(), timeout=35)
            except asyncio.TimeoutError:
                proc.kill()
                return {"photos": [], "error": "scraper timed out"}

            if not os.path.exists(output_file):
                return {"photos": []}

            with open(output_file) as f:
                try:
                    items = json.load(f)
                except json.JSONDecodeError:
                    return {"photos": []}

            photos = []
            for item in items:
                thumbnail = item.get("thumbnail_url", "")
                if not thumbnail or "pinimg" not in thumbnail:
                    continue
                photos.append(
                    {
                        "id": f"pinterest-{item.get('result_id') or len(photos)}",
                        "imageUrl": thumbnail,
                        "thumbUrl": thumbnail,
                        "alt": item.get("result_title") or "Pinterest inspiration",
                        "source": "pinterest",
                        "author": item.get("creator_name") or "Pinterest",
                        "detailUrl": item.get("result_url") or "",
                    }
                )

            return {"photos": photos}

    except Exception as exc:  # noqa: BLE001
        return {"photos": [], "error": str(exc)}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8765"))
    print(f"Pinterest service starting on http://localhost:{port}")
    print(f"ScrapeOps key: {'set' if SCRAPEOPS_API_KEY else 'NOT SET — set SCRAPEOPS_API_KEY env var'}")
    uvicorn.run(app, host="0.0.0.0", port=port)
