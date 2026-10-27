# pacer — maintainer notes for the docs rewrite

pacer is an open-source Python library that limits how often code may do something, such as calling an API. These notes collect everything the current README, the issue tracker and the code say, so the new docs can be planned from one place.

## Using it

Install with `pip install pacer`. It needs Python 3.9 or later and has no runtime dependencies.

The main object is `Limiter(rate, per)`. `Limiter(10, per=1.0)` allows 10 calls per second.

Use it as a decorator (`@limiter`) or as a context manager (`with limiter:`). Both block until a call is allowed.

`limiter.try_acquire()` does not block. It returns True if the call is allowed now and False otherwise.

An async version, `AsyncLimiter`, has the same arguments and is used with `async with`.

By default a limiter allows a burst: after a quiet period, up to `rate` calls can go through at once. Pass `burst=1` to spread calls evenly instead.

A limiter is safe to share between threads in one process.

A limiter is not shared between processes. To share a limit between processes or machines, pass `backend=RedisBackend(url)`.

With the Redis backend, every limiter that uses the same `key` shares one limit.

If Redis cannot be reached, the limiter raises `BackendUnavailable` by default. Pass `on_backend_error="allow"` to let calls through instead.

`limiter.stats()` returns the number of calls allowed and the total time spent waiting since the limiter was created.

## How it works

The in-memory limiter uses a token bucket: tokens are added at `rate / per` per second up to a cap of `rate`, and each call takes one token.

Time is read from `time.monotonic()`, so a change to the system clock does not open or close the limit.

The Redis backend runs the whole check-and-take step as one Lua script, so two clients can never take the same token.

Redis keys expire after `2 * per` seconds without use, so idle limiters do not leave keys behind.

The thread lock is held only while the token count is updated, never while a caller sleeps.

## Contributing

Tests run with `pytest`. Tests that need Redis are marked `redis` and are skipped when no Redis is running on localhost:6379.

Timing tests use a fake clock passed to the limiter, never real sleeps.

Every pull request adds a line to `CHANGELOG.md` under "Unreleased".

A release is cut by pushing a version tag; CI builds the package and publishes it.

The public API is everything listed in `pacer.__all__`. Anything else may change without notice.

## Stale statements to clean up

- The README still shows `RateLimiter(calls=10, period=1)`. That class was deprecated two releases ago and removed in the current release. `Limiter(10, per=1.0)` replaces it.
- An old issue answer says the limiter is "safe across processes by default". That is false: only the Redis backend shares a limit between processes.
