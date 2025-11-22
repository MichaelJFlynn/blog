AUTHOR = 'Michael J. Flynn'
SITENAME = "Michael J. Flynn's blog "


PATH = "content"

TIMEZONE = 'America/Los_Angeles'

DEFAULT_LANG = 'en'

THEME = "themes/elegant"

SITEURL = "https://michaeljflynn.net"
RELATIVE_URLS = True

FEED_MAX_ITEMS = 15
FEED_ALL_ATOM = "feeds/all.atom.xml"
CATEGORY_FEED_ATOM = "feeds/{slug}.atom.xml"

# Feed generation is usually not desired when developing
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

LANDING_PAGE_TITLE= "Landing page title"

# TWITTER_USERNAME= "michaeljaflynn"


# Social widget
SOCIAL = (
    ("Twitter", "https://x.com/MichaelJAFlynn"),
    ("Github", "https://github.com/MichaelJFlynn"),
    ("RSS", "https://michaeljflynn.net/feeds/all.atom.xml"),
    ("Linkedin", "https://www.linkedin.com/in/michael-flynn-5b04881a6/")
)

DEFAULT_PAGINATION = 10

# Uncomment following line if you want document-relative URLs when developing
# RELATIVE_URLS = True

PLUGINS = ["pelican_katex", "tipue_search", "share_post"]
SHARE_LINKS = [ ('hacker-news', "Hacker News"), ('reddit', 'Reddit'), ('mastodon', 'Mastodon'), ('twitter', 'Twitter'), ('bluesky', 'BlueSky'), ('linkedin', 'Linkedin'), ('facebook', 'Facebook'), ('email', 'Email')]


SITE_LICENSE = "Content licensed under CC BY 4.0"
DIRECT_TEMPLATES = ('index', 'categories', 'authors', 'archives', 'tags', 'search')



