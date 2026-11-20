PROPAGATION_SECONDS = 30


class Provider:
    """The remote service. A grant is saved at once but only honored after a delay."""

    def __init__(self, clock):
        self.clock = clock
        self.granted_at = {}

    def grant(self, customer, scope):
        self.granted_at[(customer, scope)] = self.clock.now

    def mint_token(self, customer, scope):
        at = self.granted_at.get((customer, scope))
        if at is None or self.clock.now - at < PROPAGATION_SECONDS:
            return None, "scope_not_granted"
        return "token-" + customer, None
