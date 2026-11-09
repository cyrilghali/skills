# Worked examples

## Elixir

```elixir
# Retries because sometimes the provider fails
defp charge_with_retry(order) do
  Retry.run(times: 3, fn -> Provider.charge(order) end)
end
```

Findings:
- **Problem-first**: "sometimes ... fails" names no mechanism. If the provider's docs are in hand and say a 200 can precede settlement, rewrite: `# A 200 can precede settlement; retry confirms the charge landed.` If they are not, say the reason is missing and ask the author what failure the retry covers.

```elixir
@moduledoc """
This module handles user accounts. It has functions to create, update,
and delete a user.
"""
```

Findings:
- **Unguessable-only**: restates the module's public function names, which the reader already sees. Delete, or replace with the one fact the signatures don't carry (e.g. soft-delete semantics, uniqueness scope).

```elixir
# We chose to soft-delete here instead of hard-delete because the team
# decided we need the audit trail (see PR #4021)
def delete_user(user), do: Repo.update(user, deleted_at: DateTime.utc_now())
```

Findings:
- **Contract, not discussion**: drop the "we chose / team decided / see PR" framing. Rewrite: `# Soft-delete: deleted_at is set, row stays for the audit trail.`

## TypeScript / JSDoc

```typescript
// increments the counter by one
count += 1;
```

Finding: **unguessable-only**, delete.

```typescript
/**
 * @param items - the items
 * @returns the total
 */
function sumPrices(items: LineItem[]): number {
  return items.reduce((sum, i) => sum + i.price * (1 - i.discount), 0);
}
```

Findings:
- **Accuracy**: `@returns the total` omits that discounts are applied; a reader trusting the doc would miss it. Rewrite: `/** Sum of item prices after each item's discount. */` (drop the no-op `@param` restating the signature).

```typescript
// Stripe rejects idempotency keys longer than 255 characters.
const MAX_KEY_LEN = 255;
```

Keep as-is: one line, states a provider limit the code cannot show.

```ts
// TODO: drop this polyfill once we require Node 20
import "core-js/actual/array/to-sorted";
```

If `package.json` already pins `engines` to `>=20`: **rot marker** — the condition already holds. Flag the polyfill for removal, don't just relabel the comment.

## Stale-outside-diff check

A diff renames the config field `maxRetries` to `retryLimit`. Grep the repo for `maxRetries` and read each hit to see whether it sits in a comment of any syntax:

```sh
grep -rn "maxRetries" .
```

A hit like `// raise maxRetries in config.ts for slow tenants` in an unrelated module is now **accuracy**: the name it points to no longer exists. Rewrite to the new name or delete if the pointer is redundant.
