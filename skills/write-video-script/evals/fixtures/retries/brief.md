# Brief: u03-retries — What happens when a job fails

- **Series goal:** a new engineer can follow a background job from enqueue to done, and knows where to look when one fails.
- **Audience — new engineer:** an engineer in their first week on the team. Already knows: what a background job is, from the earlier units.
- **Tier:** overview (1 of 2); stands alone: yes
- **The one idea:** a failed job is retried with longer and longer waits until it hits a limit, then it is set aside for a person to look at.
- **Length:** about 90 seconds
- **Prerequisites:** none

## Facts this unit must say

| id | fact | source |
|---|---|---|
| f09 | After a failure, the next attempt waits 2^attempt seconds, with attempt counting from 1. | source.md |
| f10 | A random jitter of 0 to 10 seconds is added so jobs that failed together do not retry in the same second. | source.md |
| f11 | The runner gives up after 20 attempts. | source.md |
| f12 | A job that fails its last attempt moves to the discarded state, is kept 7 days, then deleted. | source.md |
| f13 | A job can set its own limit with max_attempts. | source.md |

## Facts the viewer already has (recall in a clause, never re-teach)

| id | fact | taught in |
|---|---|---|
