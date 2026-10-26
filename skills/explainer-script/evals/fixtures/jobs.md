# Job retries

Source of truth for how the job runner retries a failed job.

- `lib/runner/retry.ex:14` — after a failure, the next attempt waits `2^attempt` seconds, where `attempt` counts from 1.
- `lib/runner/retry.ex:15` — a random jitter of 0 to 30 seconds is added to that wait, so jobs that failed together do not all retry in the same second.
- `lib/runner/retry.ex:22` — `max_attempts` is 20.
- `lib/runner/retry.ex:27` — after the last attempt fails, the job's state becomes `discarded`: it stays in the table for inspection but never runs again on its own.
- `lib/runner/admin.ex:41` — an engineer can re-queue a discarded job from the admin page; its attempt count starts again at 1.
