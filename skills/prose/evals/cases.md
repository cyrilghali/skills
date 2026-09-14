# prose eval cases

Each case gives a generation agent a text and the audience, nothing else. The agent applies
`SKILL.md` and returns only the rewritten text. A judge then scores it
against `rubric.md`, and `hooks/prose-gate.sh doc` runs on the output as the
mechanical half.

The `Trap` field names the failure mode the case is designed to catch.

---

## Case 1 — a French decision answer carrying its proof trail

**Audience:** a Linear technical appendix, read cold by a backend engineer joining the project.

**Text:**

> **Stockage de l'exposition**
>
> Après vérification dans le code, la table `social_profiles` porte déjà une colonne `raw_data` jsonb qui conserve le dernier payload du scraper, et j'ai vérifié sur pièces (prod-main, 59 842 lignes) qu'elle est remplie pour tous les scans confirmés depuis 2023, ce qui est corroboré par le job `ScrapeSocialProfileJob` qui l'écrit à chaque tentative réussie. Il est donc clairement inutile de créer une table dédiée : l'exposition sera **recalculée à la lecture** depuis `raw_data` et le niveau publié, exactement comme le fait déjà `evaluate_social_profile/1` pour `isFootprintGood`. À noter que cette décision a été actée le 04/09 avec le lead, après avoir envisagé une table `linkedin_exposures` (colonnes `level`, `secured`, `findings` jsonb, `scanned_at`), rejetée parce qu'elle dupliquerait le payload — autrement dit, on garde une seule source de vérité. Conséquence : un changement de niveau ne déclenche aucun re-scrape, ce qui est important pour le coût.

**Trap:** keeping the trail (verification, counts, who agreed when, the rejected alternative's columns) and the emphasis words. The rewrite must keep the decision, the one why (no duplicated payload) and the consequence (level change without rescrape), and drop the rest.

---

## Case 2 — an English ticket paragraph with statement headings

**Audience:** a Linear ticket a fresh executor agent will implement from.

**Text:**

> **Sole writer, not two.**
>
> The scan side becomes the single open/close writer for this kind. When a scan evaluation finishes, it looks up the open cycle for the employee (there is at most one, the partial unique index guarantees it), and if the exposure is open and no cycle exists it opens one with the employee as subject and no target, and if the exposure is secured and a cycle exists it closes it with outcome secured and no actor, and if the exposure is unreadable it touches nothing, and if the employee has left the audience the cycle is closed cleared by the generic reconciliation which is the only thing the generic compute still does for this kind since its detections are empty. This ensures a single open cycle. That said, the impact preview keeps reading the compute module for its counts. Idempotence matters: replaying the same evaluation twice must not open a second cycle or close the same one twice, which the index and a status guard on close both ensure. Note that the rescan job is a separate ticket ✅. This ticket is essentially the heart of the rule!

**Trap:** the heading is a punchline, not a question; five transitions are packed into one 90-word sentence and belong in a table; "Note that", "essentially", the dangling "This ensures", the "That said" glue, the checkmark, the exclamation and the closing flourish are tells. The rewrite must keep every transition and the idempotence requirement.

---

## Case 3 — a session reply reporting a PR

**Audience:** the requester, in session, right after the agent pushed a draft PR.

**Text:**

> I've gone ahead and pushed the draft PR #21203, which essentially adds the rescan job. It is worth noting that I took great care to ensure that the job only enqueues scrapes for confirmed profiles — I verified this with a test that seeds one unconfirmed and one confirmed profile and asserts a single enqueued job. Tests were updated and are green (412 tests, 0 failures). Formatting was also run. Window: read from the published config, as decided. Résultat : the job only fires for confirmed profiles. In other words, the rescan is now fully in place and ready for your review! Let me know if you'd like any changes.

**Trap:** over-applying the no-proof rule. A session reply keeps the certification voice: first person, what I checked, where the requester's eyes should go. The rewrite strips the tells, the passive "tests were updated", the two label-colon fragments ("Window:", "Résultat :"), the closing offer and the test count in prose, but must keep "I verified" and end with a directed ask.

---

## Case 4 — a three-line README note

**Audience:** a developer reading the repo README.

**Text:**

> Note that `mix ci` is essentially the same as running format, compile, tests, credo and gettext one after the other — it's not a different pipeline, it's just the shortcut. Importantly, it clearly fails fast on the first failing step.

**Trap:** over-rewriting. Three lines do not warrant a question heading or a table. The rewrite is two plain sentences with the tells and the "not X, it's Y" reframe removed, nothing added.

---

## Case 5 — a paragraph written from inside the project

**Audience:** a product manager reading the PRD, who knows the product but not its policies engine.

**Text:**

> The kind escalates through the chain like any other: the employee step fires on open, the manager step after the threshold, the admin step last. The recheck is not the rescan — one is the chain's re-ask after an approval, the other is the window. Closing pays aura once per cycle. That's it. That's the whole escalation.

**Trap:** curse of knowledge. Kind, chain, threshold, recheck, rescan, window, aura and cycle are never defined; the last two fragments are a punchline. The rewrite defines or replaces each term for that reader and ends on content.

---

## Case 6 — implicit context: a section that reads well and says nothing a stranger can use

**Audience:** a Linear design appendix, read by a backend engineer who knows the company's two products (courses delivered in monthly missions; a rules engine that opens cases) but nothing about this rule.

**Text:**

> **When has the course "had its chance" for an employee?**
>
> When it is completed, or when it has been presented in two missions without completion, the same silence threshold the rule applies to its own employee step. An unfinished course comes back every month of the year, so waiting for it to leave the mission means waiting for December.

**Trap:** implicit context. Every sentence is short and the heading is a question, so the mechanical gate passes. Three things the author knew and never wrote still block the reader: the heading quotes a phrase the author coined ("had its chance") as if it were an established term; the why leans on a comparison to something the section never defines ("the same silence threshold the rule applies to its own employee step"); and an image ("waiting for December") stands in for the fact (an unfinished course is carried into every later mission until the end of the year). The rewrite names the mode in plain words in the heading, states the carry-over fact and the two-mission delay as facts, and keeps the decision (completed, or presented twice without completion).
