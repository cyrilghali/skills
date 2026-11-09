# Shape of a category file

One file per output category, `<category>.md`, in the excellence folder. Its references sit beside it in `<category>/refs/`. Write the checks from real references and the owner's own corrections, never from generic advice. Each check must be decidable by looking at the output or its capture.

```
# What does excellent <category> look like?

<one line: which outputs this file covers, and which it does not>

## Which checks must pass?
1. <the check in one sentence>
   Observe: <how a reviewer tests it on the output>
   Seen in: <the reference that shows it>
... 5 to 10 checks

## Which references set the bar?
| Reference | Link | Saved | What it does best |
<3 to 5 rows; Saved is the path under <category>/refs/>

## Which failures recur in the owner's history?
- "<the owner's words>" (<date>) → check <n>
... 3 to 8 bullets
```
