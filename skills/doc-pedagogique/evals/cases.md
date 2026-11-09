# doc-pedagogique eval cases

Chaque case fournit à un agent de génération toute la matière nécessaire pour rédiger le document
SANS poser de question. L'agent applique le skill et retourne uniquement le markdown final.
Un juge le note ensuite contre `rubric.md`. Le champ `Piège` nomme l'échec que le case doit attraper.

---

## Case 1 — matière d'agents à réécrire (le case canonique)

**Demande :** « Rédige le document comparatif sur la stratégie d'invalidation du cache produit, pour l'équipe élargie (dont deux nouveaux qui ne connaissent pas le système). »

**Matière brute (sorties d'agents, style scorecard — à NE PAS recopier telle quelle) :**
- Système actuel : `product_cache` (Redis, TTL 1h) → lecture API ; invalidation = TTL only → fenêtre staleness 0-60min ; incidents support ×3/mois.
- Opt A « TTL court » : TTL→2min ; +load DB ×8 (mesuré staging) ; 0 refonte ; staleness résiduelle 2min.
- Opt B « invalidation événementielle » : hook post-update produit → `DEL` ; couvre 90% des writes (imports bulk hors chemin → staleness persiste sur imports) ; 2 sprints ; risque : oubli de hook sur futurs write-paths.
- Opt C « write-through » : cache écrit à la source, lecture jamais stale ; refonte du write-path (4+ sprints) ; risque migration élevé ; DEFAUT CONNU : les imports bulk (30% des updates) passent par COPY SQL direct → contournent le write-through, staleness totale sur ce flux tant que l'import n'est pas réécrit.

**Piège :** recopier le télégraphe (`TTL→2min ; +load DB ×8`), utiliser « staleness »/« write-through » sans les expliquer, masquer le défaut rédhibitoire de C, oublier le fil rouge.

---

## Case 2 — sujet pointu pour lecteur produit

**Demande :** « Explique à Sarah (PM, non-technique) pourquoi les compteurs de l'écran admin affichent parfois des valeurs périmées juste après une action, et les deux options de correction. »

**Matière :** lecture sur réplica (lag 1-3s) après écriture sur primaire ; Opt A = lire le primaire pour ces 3 écrans (coût : charge primaire, +0j) ; Opt B = read-your-writes par session sticky 5s (2j, couvre tous les écrans futurs).

**Piège :** jargon non introduit (réplica, lag, sticky), pas d'exemple concret incarné, structure en 7 sections complète pour un sujet qui en demande 4 (le skill dit de proportionner).

---

## Case 3 — mémo court à ne pas sur-structurer

**Demande :** « Note courte pour l'équipe : pourquoi on passe les jobs de nettoyage de cron shell à Oban, il n'y a pas vraiment d'alternative sérieuse. »

**Matière :** cron shell actuel sans retry ni observabilité, 2 incidents silencieux ; Oban déjà dans la stack ; seule alternative écartée : Quantum (pas de persistance des runs).

**Piège :** dérouler le template 7 sections et le fil rouge nommé pour un mémo d'une page à option unique — l'inverse du « scale down » ; l'autre piège symétrique : produire du télégraphe sous prétexte de brièveté.


---

## Case 4 — explication d'un système existant, sans options

**Demande :** « Écris pour les deux personnes qui rejoignent l'équipe support un document qui explique comment une demande de remboursement client circule chez nous, de la réception au virement. »

**Matière :** le client écrit via le formulaire ; un agent support vérifie la commande et classe la demande (< 50 € : accord direct ; ≥ 50 € : validation d'un responsable sous 48 h) ; la finance exécute les virements chaque jeudi ; le client reçoit un e-mail à l'accord puis un second au virement ; les demandes sans réponse du client après 7 jours sont clôturées. Aucune alternative n'est étudiée, aucune décision n'est attendue.

**Piège :** inventer des options, un tableau comparatif ou une recommandation pour un document qui explique seulement ; jargon non introduit ; pas de fil rouge incarné (une demande suivie de bout en bout).

---

## Case 5 — décision de process hors infrastructure

**Demande :** « Prépare pour la direction un comparatif sur la façon de traiter les factures fournisseurs : saisie manuelle par la comptabilité, ou outil de lecture automatique avec contrôle humain. Les lecteurs ne connaissent pas le circuit actuel. »

**Matière :** aujourd'hui 400 factures/mois saisies à la main, ~6 min chacune, 1 erreur de montant sur 50 ; outil automatique : 9 €/facture traitée en dessous de 500 factures/mois, lecture correcte à 95 % sur les factures au format standard, 70 % sur les scans manuscrits (15 % du volume) ; le contrôle humain reste nécessaire sur ces scans, donc le gain de temps réel est plus faible que l'affichage commercial ; mise en place : 3 semaines.

**Piège :** masquer la limite sur les scans manuscrits, jargon comptable non introduit, absence de fil rouge (une facture suivie dans chaque option), décisions finales non formulées en questions.
