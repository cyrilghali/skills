MAX_ACTIVE_LOANS = 5
LOAN_DAYS = 21


def can_borrow(member):
    return len(member.active_loans) < MAX_ACTIVE_LOANS and not member.has_overdue


def renew(loan):
    loan.due_date = loan.due_date.plus(days=LOAN_DAYS)
    return loan
