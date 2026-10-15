def add_tax(cents: int, rate_pct: int) -> int:
    """Return cents plus tax, rounded down to a whole cent."""
    return cents + cents * rate_pct // 100
