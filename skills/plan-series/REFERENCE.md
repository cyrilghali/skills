# Sources behind the rules

Each rule in `SKILL.md` and `STYLE.md`, with its source and how well it holds. Pages were read in October 2026.

Status: `confirmed` = two independent sources; `single-source` = one source or one author group; `inferred` = reasoned from a sourced premise; `contested` = sources disagree; `owner rule` = a requirement of the skill, kept as a hard rule without a source; `taste` = no source, kept in `STYLE.md`.

## Rules in SKILL.md

| Rule | Status | Source |
|---|---|---|
| State what the people who finish can do before choosing any unit. | confirmed | [McTighe and Wiggins, UbD white paper, ASCD 2012](https://files.ascd.org/staticfiles/ascd/pdf/siteASCD/publications/UbD_WhitePaper0312.pdf): three stages, "Desired Results, Evidence, and Learning Plan". [University of Toronto OCW, Backward design](https://ocw.utoronto.ca/backward-design/): goals first. |
| Say how you will know the goal was reached before planning units (`evidence`). | single-source | UbD white paper 2012: skipping the evidence stage is the common failure ("little, if any, attention to assessment evidence"). |
| Plan the whole series before any one unit. | single-source | UbD white paper 2012: "we do not recommend isolated lesson planning separate from unit planning." |
| Each fact in one unit; check the plan for gaps and repeats. | single-source | [Curriculum mapping](https://en.wikipedia.org/wiki/Curriculum_mapping) (Jacobs and Johnson 2009): reviews for "gaps, repetitions, or omissions" and removes redundancies. [dita-lang.org](https://dita-lang.org/): self-contained topics that each cover one subject. |
| A later unit does not re-teach what its audience already has. | single-source | [Kalyuga, Ayres, Chandler, Sweller 2003](https://api.openalex.org/works/doi:10.1207/S15326985EP3801_4) and [Kalyuga 2007](https://www.uky.edu/~gmswan3/EDC608/Kalyuga2007_Article_ExpertiseReversalEffectAndItsI.pdf): material that helps novices becomes redundant for learners who know it and loads working memory (expertise reversal). |
| A cue reminds; real recall needs a question the viewer answers. | confirmed | [Roediger and Karpicke 2006](https://www.gwern.net/docs/spaced-repetition/2006-roediger.pdf): after one week, tested 56% against restudied 42%. [Pastötter and Bäuml 2014](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2014.00286/full): retrieval practice is robust. A narrated clause is restudy, so the brief calls it a cue. |
| A short cue to a prerequisite fact is enough. | inferred | Gagné on prerequisites (via Phillips, below) plus Kalyuga 2007 on the cost of redundancy. |
| A deeper unit returns to a topic only with new facts. | single-source | [QMUL, Spiral curriculum](https://www.qmul.ac.uk/queenmaryacademy/educators/resources/degree-apprenticeships/curriculum-design/spiral-curriculum) (Harden and Stamper 1999): each return is at a deeper level, not repetition. |
| A prerequisite comes before the unit that needs it. | contested | [Phillips, c. 1977, review of Gagné](https://journals.flvc.org/fjer/article/download/133788/137741/246379): hierarchy order beat scrambled order in several studies; other studies found order made little difference. Kept as the safer default. |
| Give each audience units written for it, with what it already knows. | single-source | Kalyuga 2007; [Mintlify, Understand your audience](https://www.mintlify.com/docs/guides/understand-your-audience) (a vendor guide): separate content per audience, link to depth instead of repeating it. |
| Split a large topic into short segments the viewer moves through at their own pace: chapters inside a unit, or several units. | confirmed | [Mayer and Pilegard 2014](https://www.cambridge.org/core/books/cambridge-handbook-of-multimedia-learning/principles-for-managing-essential-processing-in-multimedia-learning-segmenting-pretraining-and-modality-principles/DD24C2F48B9B1277CE59F78276110258): segmenting held in 10 of 10 tests. [Brame 2016](https://pmc.ncbi.nlm.nih.gov/articles/PMC5132380/) states it too. |
| Make the first tier stand alone. | inferred | [MIT News, 21/01/2014](https://news.mit.edu/2014/mit-and-harvard-release-working-papers-on-open-online-courses-0121): most of 841,687 course registrants viewed less than half the units. The data is on courses, not video series. |
| A standalone unit has no back references. | single-source | [EduTechWiki, Learning object](https://edutechwiki.unige.ch/en/Learning_object) (on Wiley 2000): "as you will recall from the last module" makes reuse very hard. |
| Drop a fact only as false, outdated, a duplicate or off the goal. | single-source | UbD white paper 2012: the goal sets priorities and content can be cut for them, which `off-goal:` covers. |
| Depth is never a reason to drop a fact. | owner rule | No source; backward design expects some cutting for priority. Kept hard because the skill exists to plan for every audience, and depth is what deeper tiers are for. |
| Size follows the source; no unit without facts of its own. | inferred | Follows from one home per fact: a unit with no fact can only repeat. |

## Defaults in STYLE.md

| Default | Status | Note |
|---|---|---|
| Tiers named by depth (overview, deep dive). | taste | Only vendor guides say "broad first, then depth". [Diátaxis](https://diataxis.fr/foundations/) sorts by need (tutorial, how-to, reference, explanation), not by depth. [Nielsen 2006, progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/) backs it by analogy only. |
| A prerequisite sits in the same tier or a broader one. | taste | Follows from the tier idea. |
| One idea per unit. | taste | Consistent with segmenting; no source states it. |
| About 2 minutes per overview video, about 4 per deeper one. | taste | No source. |
| Keep videos under about 6 minutes. | single-source | [Guo, Kim, Rubin 2014](https://pg.ucsd.edu/publications/edX-MOOC-video-production-and-engagement_LAS-2014.pdf): median watch time at most 6 minutes in 6.9 million sessions. It measures engagement, not learning. |
| About 20 seconds per fact. | taste | No source. |

## Source caveats

The UbD white paper comes from the authors' own publisher. Kalyuga 2003 and 2007 share an author, so they count as one group. Mintlify is a documentation vendor. dita-lang.org is unattributed and is not the OASIS standard. Diátaxis is described only by its own site. The MIT figures come from the institutions' press release on their own data.
