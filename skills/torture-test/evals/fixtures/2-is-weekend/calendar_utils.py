from datetime import date


def is_weekend(day: date) -> bool:
    """Saturday and Sunday are weekend days."""
    return day.weekday() >= 5
