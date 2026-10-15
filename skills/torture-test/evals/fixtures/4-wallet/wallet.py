from typing import Protocol


class WalletDB(Protocol):
    def get_wallet(self, wallet_id: str) -> dict: ...
    def update_wallet(self, wallet_id: str, balance_cents: int) -> None: ...
    def record_transaction(self, wallet_id: str, delta_cents: int) -> None: ...


class InsufficientFundsError(Exception):
    pass


def debit_wallet(db: WalletDB, wallet_id: str, amount_cents: int) -> dict:
    """
    Debit amount_cents from the wallet. Returns the updated balance.
    Raises InsufficientFundsError if the wallet has insufficient funds.
    Raises ValueError if amount_cents is not positive.
    """
    if amount_cents <= 0:
        raise ValueError(f"amount_cents must be positive, got {amount_cents}")

    wallet = db.get_wallet(wallet_id)
    if wallet["balance_cents"] < amount_cents:
        raise InsufficientFundsError(
            f"Insufficient funds: balance={wallet['balance_cents']}, "
            f"requested={amount_cents}"
        )

    new_balance = wallet["balance_cents"] - amount_cents
    db.update_wallet(wallet_id, new_balance)
    db.record_transaction(wallet_id, -amount_cents)

    return {"wallet_id": wallet_id, "balance_cents": new_balance}
