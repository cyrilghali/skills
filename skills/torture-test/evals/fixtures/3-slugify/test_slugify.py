import pytest
from slugify import slugify


def test_basic_phrase():
    assert slugify("Hello World") == "hello-world"


def test_empty_string():
    assert slugify("") == ""


def test_only_punctuation_returns_empty():
    assert slugify("!@#$%^&*()") == ""


def test_unicode_accents_stripped():
    assert slugify("café résumé Ñoño") == "cafe-resume-nono"


def test_emoji_stripped():
    assert slugify("hello 🌍 world") == "hello-world"


def test_null_like_characters():
    assert slugify("a\x00b") == "ab"


def test_multiple_spaces_collapsed():
    assert slugify("a   b   c") == "a-b-c"


def test_leading_trailing_separators_stripped():
    assert slugify("  --hello--  ") == "hello"


def test_numbers_preserved():
    assert slugify("item 42 version 3") == "item-42-version-3"


def test_already_a_slug():
    assert slugify("already-a-slug") == "already-a-slug"


def test_mixed_separators_collapsed():
    assert slugify("a - b -- c") == "a-b-c"
