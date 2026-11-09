def normalize(q: str) -> str:
    """Trim and lowercase a search query; collapse inner whitespace."""
    return " ".join(q.split()).lower()
