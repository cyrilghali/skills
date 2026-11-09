# design-props rubric

Noter la production sur 20. PASS ≥ 15 avec zéro dimension à 0.
**Règle anti-hallucination : toute pénalité cite le passage exact fautif (ou nomme l'absence précise). Sans citation, pénalité nulle.**

| Dimension | Points | 0 si… |
|---|---|---|
| Phase 0 : verdicts par exigence (🟢/🟠/🔴 motivés) et **l'hypothèse structurante vérifiée/relevée** (case 1 : la rétention 7j qui tue les métriques 30j ; case 6 : la purge du stockage du webview qui contredit l'exigence de non-perte) | 0-5 | l'hypothèse piégée est avalée telle quelle |
| Philosophies réellement distinctes (stratégies d'écriture différentes, pas des variantes), contender minimal présent, template commun tenu | 0-4 | ≥2 propositions sont la même philosophie |
| Honnêteté par proposition : limites assumées, coûts chiffrés (ordre de grandeur), extensibilité point par point contre les besoins futurs fournis ; case 6 : la critique exactitude/performance porte sur la concurrence entre onglets et la resynchronisation contre une API sans versionnement | 0-4 | une proposition sans limite ni coût ; case 6 : la critique ne parle que de tables/requêtes |
| Synthèse : le **vrai choix** nommé (options réellement en concurrence ; compléments/extensions nommés s'il y en a), convergences relevées, option qui n'hypothèque pas les autres identifiée ou constat motivé qu'aucune ne le fait | 0-4 | tableau sans lecture croisée |
| Trajectoire phasée avec déclencheurs de bascule explicites + décisions restantes **en questions** | 0-3 | recommandation sans déclencheur ni question |

Le juge lit le case (état du code + piège), puis la production, puis note avec citations.
Verdict : PASS/FAIL + les 2 améliorations les plus rentables.

## Cases 4 et 5 — grille dédiée

Ces deux cases se notent sur cette grille à la place de la grille principale. Noter sur 10. PASS ≥ 7 avec zéro dimension à 0. Même règle anti-hallucination.

| Dimension | Points | 0 si… |
|---|---|---|
| Case 4 : la question « CTE vs matérialisé » est tranchée par une mesure (script exécuté, ou protocole de mesure exact avec la métrique et le seuil de 2 000/s) avant la synthèse, et n'apparaît pas dans les décisions remises au lecteur. Case 5 : les deux signaux (même contournement dans des appels sans rapport ; `any()`) sont nommés comme preuve que le design est faux | 0-4 | la question est rendue au lecteur (4) ; un patch local est proposé (5) |
| Case 4 : chaque philosophie porte l'esquisse d'appel et ses signatures publiques. Case 5 : retour à la Phase 1 avec le constat, sans modifier l'esquisse en silence | 0-3 | aucune signature (4) ; on continue l'implémentation (5) |
| Honnêteté : ce qui reste au lecteur est une vraie question produit ou de préférence (4) ; ce que l'esquisse ignorait (les plans legacy, 12 %) est nommé (5) | 0-3 | question technique mesurable laissée au lecteur (4) ; cause non nommée (5) |
