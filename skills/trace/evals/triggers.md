# trace trigger queries

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | what happens when an employee clicks "mark as done" on a checklist task? trace it front to back | yes | no |
| 2 | /trace admin deletes a workspace | yes | no |
| 3 | walk me through the calls when a user resets their password, from the button to the database | yes | no |
| 4 | when an admin turns on auto-archiving in the dashboard, what happens in the backend step by step? | yes | no |
| 5 | trace what happens when someone reports a spam email from the mail plugin | yes | no |
| 6 | follow the request when someone submits the signup form all the way to the rows it writes | yes | no |
| 7 | the user saved their address but the reminder still shows. what happens when they submit it? give me the call chain | yes | yes |
| 8 | show me the call graph from the portal save button to the database for the profile update | yes | yes |
| 9 | what does the backend do, hop by hop, when a customer cancels their subscription? | yes | yes |
| 10 | trace an invite: admin clicks invite, then what, until the email goes out | yes | yes |
| 11 | how does the notifications subsystem work overall? | no | no |
| 12 | teach me the billing module, I'm new to it | no | no |
| 13 | why is this test failing intermittently? | no | no |
| 14 | walk me through PR 1234 so I understand the change | no | no |
| 15 | use the how skill on the billing subsystem | no | no |
| 16 | add OpenTelemetry tracing spans to the checkout controller | no | no |
| 17 | where should the new export job live? | no | yes |
| 18 | why was complete_task_by_type written to pick the latest start date? which PR brought it in? | no | yes |
| 19 | Sentry shows a crash with a stack trace in event_listener.ex, what's the cause? | no | yes |
| 20 | I didn't follow your last answer, say it simpler | no | yes |
