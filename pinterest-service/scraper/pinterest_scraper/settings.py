import os

BOT_NAME = 'pinterest_scraper'

SPIDER_MODULES = ['pinterest_scraper.spiders']
NEWSPIDER_MODULE = 'pinterest_scraper.spiders'

ROBOTSTXT_OBEY = False

SCRAPEOPS_API_KEY = os.environ.get('SCRAPEOPS_API_KEY', '')
SCRAPEOPS_PROXY_ENABLED = True
SCRAPEOPS_MONITOR_ENABLED = False  # disable to reduce noise in service mode

CONCURRENT_REQUESTS = 1
DOWNLOAD_DELAY = 1

DEFAULT_REQUEST_HEADERS = {
   'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
   'Accept-Language': 'en',
   'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

DOWNLOADER_MIDDLEWARES = {
    'scrapeops_scrapy_proxy_sdk.scrapeops_scrapy_proxy_sdk.ScrapeOpsScrapyProxySdk': 725,
}

ITEM_PIPELINES = {
   'pinterest_scraper.pipelines.PinterestScrapyPipeline': 300,
}

AUTOTHROTTLE_ENABLED = True
AUTOTHROTTLE_START_DELAY = 1
AUTOTHROTTLE_MAX_DELAY = 30
AUTOTHROTTLE_TARGET_CONCURRENCY = 1.0

REQUEST_FINGERPRINTER_IMPLEMENTATION = '2.7'
TWISTED_REACTOR = 'twisted.internet.asyncioreactor.AsyncioSelectorReactor'
