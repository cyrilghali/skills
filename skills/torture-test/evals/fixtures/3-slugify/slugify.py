import re
import unicodedata


def slugify(text: str) -> str:
    """
    Convert arbitrary text to a URL-safe slug.

    Normalizes unicode to NFKD, strips non-ASCII bytes, lowercases,
    collapses whitespace and hyphens into a single hyphen, and trims
    leading/trailing hyphens.
    """
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    return text.strip("-")
