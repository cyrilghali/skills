from datetime import date

from calendar_utils import is_weekend


def test_saturday_is_weekend():
    assert is_weekend(date(2024, 6, 1))


def test_sunday_is_weekend():
    assert is_weekend(date(2024, 6, 2))


def test_monday_is_not_weekend():
    assert not is_weekend(date(2024, 6, 3))


def test_friday_is_not_weekend():
    assert not is_weekend(date(2024, 6, 7))
