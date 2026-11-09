from unittest.mock import MagicMock, call
import pytest
from wallet import debit_wallet, InsufficientFundsError


def make_db(balance_cents: int) -> MagicMock:
    db = MagicMock()
    db.get_wallet.return_value = {"balance_cents": balance_cents}
    return db


def test_debit_reduces_balance():
    db = make_db(10_000)
    result = debit_wallet(db, "w1", 3_000)
    assert result["balance_cents"] == 7_000
    db.update_wallet.assert_called_once_with("w1", 7_000)


def test_debit_exact_amount_empties_wallet():
    db = make_db(5_000)
    result = debit_wallet(db, "w1", 5_000)
    assert result["balance_cents"] == 0


def test_debit_insufficient_funds_raises():
    db = make_db(1_000)
    with pytest.raises(InsufficientFundsError):
        debit_wallet(db, "w1", 2_000)


def test_debit_zero_amount_raises():
    db = make_db(10_000)
    with pytest.raises(ValueError):
        debit_wallet(db, "w1", 0)


def test_debit_negative_amount_raises():
    db = make_db(10_000)
    with pytest.raises(ValueError):
        debit_wallet(db, "w1", -500)
