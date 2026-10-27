# Fact key: case 5 (judge only; the generator never sees this file)

Depth tag: broad = a first-time user; deep = a user scaling out, or a contributor.

| id | fact | depth | status |
|---|---|---|---|
| F01 | pacer limits how often code does something | broad | true |
| F02 | pip install pacer; Python 3.9+; no runtime dependencies | broad | true |
| F03 | Limiter(rate, per); Limiter(10, per=1.0) = 10 calls/second | broad | true |
| F04 | Decorator or context manager; both block | broad | true |
| F05 | try_acquire() does not block; returns True/False | broad | true |
| F06 | AsyncLimiter, same arguments, async with | broad | true |
| F07 | Bursts allowed by default; burst=1 spreads evenly | broad | true |
| F08 | Thread-safe within one process | broad | true |
| F09 | Not shared across processes; RedisBackend(url) to share | deep | true |
| F10 | Same key on Redis = one shared limit | deep | true |
| F11 | Redis down: BackendUnavailable by default; on_backend_error="allow" lets calls through | deep | true |
| F12 | stats() returns calls allowed and total wait time | broad | true |
| F13 | Token bucket: refill rate/per per second, cap rate, one token per call | deep | true |
| F14 | time.monotonic(): clock changes do not affect the limit | deep | true |
| F15 | Redis check-and-take is one Lua script; no double-take | deep | true |
| F16 | Redis keys expire after 2*per idle seconds | deep | true |
| F17 | Lock held only during the token update, never while sleeping | deep | true |
| F18 | pytest; redis-marked tests skipped without local Redis on 6379 | deep | true |
| F19 | Timing tests use a fake clock, never real sleeps | deep | true |
| F20 | Every PR adds a CHANGELOG line under Unreleased | deep | true |
| F21 | Release = push a version tag; CI builds and publishes | deep | true |
| F22 | Public API = pacer.__all__; the rest may change | deep | true |
| X1 | RateLimiter(calls=10, period=1) is the API | outdated: removed; must be dropped or flagged (a migration note is fine) |
| X2 | The limiter is safe across processes by default | false: must be dropped or flagged |

22 true facts, 2 to catch.
