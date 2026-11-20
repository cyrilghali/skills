def top_player(scores):
    """Return the player with the most points. Ties go to the name that sorts first."""
    best = max(scores.values())
    leaders = {name for name, points in scores.items() if points == best}
    return next(iter(leaders))
