AUTHOR = 'Michael J. Flynn'
SITENAME = "Michael J. Flynn's blog "
SITEURL = "https://michaeljflynn.net"

PATH = "content"

TIMEZONE = 'America/Los_Angeles'

DEFAULT_LANG = 'en'

THEME = "themes/elegant"

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

LANDING_PAGE_TITLE= "Landing page title"

# TWITTER_USERNAME= "michaeljaflynn"

# Blogroll
LINKS = (
    ("Pelican", "https://getpelican.com/"),
    ("Python.org", "https://www.python.org/"),
    ("Jinja2", "https://palletsprojects.com/p/jinja/"),
    ("You can modify those links in your config file", "#"),
)

# Social widget
SOCIAL = (
    ("You can add links in your config file", "#"),
    ("Another social link", "#"),
)

DEFAULT_PAGINATION = 10

# Uncomment following line if you want document-relative URLs when developing
# RELATIVE_URLS = True

PLUGINS = ["pelican_katex", "tipue_search"]

SITE_LICENSE = "Content licensed under CC BY 4.0"
DIRECT_TEMPLATES = ('index', 'categories', 'authors', 'archives', 'search')
