# Retry policy (current)

Updated after the March incident review.

- After a failure, the runner waits 2^attempt seconds before the next attempt, plus a random jitter of 0 to 10 seconds. `attempt` counts from 1, so the first retry waits about 2 seconds.
- The jitter exists so that jobs that failed together, for example during a database outage, do not all retry in the same second.
- The runner gives up after 12 attempts. The default is 12; it was 20 until the March review lowered it, because the last eight retries of a broken job only added load.
- A job that fails its last attempt moves to the `discarded` state. Discarded jobs are kept for 7 days, then deleted.
- A job can set its own limit with `max_attempts`; most jobs keep the default.
