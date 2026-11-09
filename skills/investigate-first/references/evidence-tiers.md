# Evidence tiers and the proof ladder

Grade every claim before you act on it or report it.

## Confidence tiers

1. **Direct** — an explicit source states it: a comment, commit message, PR/ticket description, or a fact you proved by running code. Phrase it plainly and cite the source (`file:line`, commit, PR/ticket).
2. **Supported** — several independent signals converge on the same conclusion, but no single one states it outright. Phrase it as "the evidence points to X: [items]".
3. **Inferred** — a reasonable reading with nothing explicit behind it. Hedge it: "appears to", "likely", "is consistent with". Make the inference chain visible ("given A and B, C seems likely because D").
4. **Speculative** — a plausible guess; other explanations fit as well. Label it "one possibility is X, unconfirmed" and don't act on it.
5. **Unknown** — you looked and found nothing. Say exactly what you searched, not just "unclear".

Never cite the code's own behavior as evidence of its intent ("it does X so it must be meant to do X" is not a citation). Don't round a Supported claim up to Direct because it reads better.

## The proof ladder

For the one or two facts a conclusion depends on, push each as far down this list as is cheap, and say where you stopped:

1. You said so — worthless alone.
2. You pointed at the line — a real `file:line`, or the library's own source.
3. You walked the failure step by step and it doesn't reach — a traced argument, not an assertion.
4. You ran it — a script or test that calls the real code and fails loud if you're wrong.
5. You reproduced it in the running app.

Step 4 is usually one small script that imports the same code the app ships and calls the exact function in question. Spend effort here, not on a longer writeup: a convincing writeup that was never run reads as true whether or not it is.
