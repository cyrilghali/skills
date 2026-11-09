from tax import add_tax


def test_add_tax():
    assert add_tax(1000, 20) == 1200


def test_rounds_up_documented_in_spec():
    assert add_tax(105, 10) == 116
