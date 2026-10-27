# video-script trigger results

Each query ran three times in a fresh headless session (three turns, plan mode, no hooks). A run fired when the session called the skill or opened its folder. A query passes when most of its runs match its Should trigger column.

| # | Query | Should trigger | Held out | Fired (of 3) | Pass |
|---|---|---|---|---|---|
| 1 | write the narration for a 90 second explainer video on how vaccines train the immune system | yes | no | 3 | yes |
| 2 | here's the brief for episode 4, turn it into beats | yes | no | 3 | yes |
| 3 | fact-check this voiceover against the source doc before I record it | yes | no | 3 | yes |
| 4 | shorten this episode's script to about a minute without losing any of the facts | yes | no | 3 | yes |
| 5 | what should my video on how a bank clears a cheque actually say? | yes | no | 3 | yes |
| 6 | draft the voiceover for an animated explainer on why bread rises, for kids | yes | no | 2 | yes |
| 7 | I have the series plan, write the words for unit 3's video | yes | yes | 3 | yes |
| 8 | turn these notes into a narrated script for a two minute explainer, beat by beat | yes | yes | 3 | yes |
| 9 | the narration of my explainer says the limit is 20 but I think the docs changed, check every claim in it | yes | yes | 3 | yes |
| 10 | write the script for a short video that explains our deploy pipeline to new hires | yes | yes | 2 | yes |
| 11 | animate this finished narration into a video | no | no | 0 | yes |
| 12 | I already have the beats.json, render it with drawings and a voice | no | no | 0 | yes |
| 13 | plan a whole video series on our billing system: which episodes, for whom, in what order | no | no | 0 | yes |
| 14 | write a blog post on how a city sorts its recycling | no | no | 0 | yes |
| 15 | make slides that explain how vaccines work | no | no | 0 | yes |
| 16 | the voice in my explainer video sounds robotic, swap it for a warmer one | no | no | 0 | yes |
| 17 | transcribe this video and give me the text | no | yes | 0 | yes |
| 18 | plan a six-lesson course on bread baking | no | yes | 0 | yes |
| 19 | write a script that converts all my mp4 files to webm | no | yes | 0 | yes |
| 20 | how does a bank clear a cheque? just tell me | no | yes | 0 | yes |

Open queries: 12 of 12 pass. Held-out queries: 8 of 8 pass.
