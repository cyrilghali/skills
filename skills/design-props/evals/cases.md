# design-props eval cases

Chaque case décrit un état de code auto-contenu (pas d'accès repo nécessaire) et une demande.
L'agent de génération applique le skill en version condensée : faisabilité (verdicts par exigence),
2-3 philosophies avec template commun, critiques principales, synthèse (matrice, vrai choix,
trajectoire, décisions). Un juge note contre `rubric.md`. `Piège` nomme l'échec visé.

---

## Case 1 — l'hypothèse structurante piégée (le case canonique)

**Demande :** « Propose plusieurs designs pour des statistiques d'usage des webhooks (taux d'échec sur 30j, temps médian de rétablissement, endpoints jamais rétablis). »

**État du code fourni :**
- `webhook_endpoints` (id, url, disabled_at) — état courant.
- `webhook_deliveries` (endpoint_id, status, attempted_at) — « les livraisons sont conservées » d'après le README… **mais** la migration fournie montre un job `PruneDeliveriesJob` qui `DELETE WHERE attempted_at < now() - interval '7 days'`.
- `webhook_failures_count` sur endpoints — compteur écrasé à chaque sync.

**Piège :** bâtir les designs sur « les livraisons sont conservées » sans relever que la rétention de 7 jours invalide toute métrique 30j — l'hypothèse structurante contredite par un détail fourni. Un générateur qui applique le skill doit la vérifier/relever en Phase 0 et en tirer les verdicts 🔴.

---

## Case 2 — philosophies non distinctes

**Demande :** « 3 approches pour historiser les changements de permissions (qui a donné quel accès, quand, révoqué quand). »

**État du code :** `permissions` (état courant, upsert), `audit_log` générique (jsonb, non typé, 90j de rétention), aucun événement typé.

**Piège :** produire 3 variantes de la même philosophie (3 formes de table d'audit) au lieu de philosophies réellement distinctes (ex. : event log typé / entité stateful avec versions / étendre l'audit_log existant), et omettre le contender minimal. Second piège : extensibilité en score vague (« extensible : oui ») au lieu de point par point contre les besoins futurs fournis (rétention 2 ans exigée par conformité, groupes de permissions à venir).

---

## Case 3 — synthèse sans décision

**Demande :** « Compare pgvector vs service de recherche externe pour la recherche sémantique des documents, et dis-nous quoi faire. »

**État fourni :** Postgres 16 géré (extensions autorisées : liste incluant pgvector), 2M docs, équipe sans infra dédiée, latence cible < 200ms, budget serré, croissance ×10 possible à 18 mois.

**Piège :** conclure par un tableau sans nommer **le vrai choix** ni la trajectoire phasée avec déclencheurs (« démarrer pgvector ; basculer si p95 > 200ms au-delà de N docs »), ni formuler les décisions restantes en questions pour l'équipe.

---

## Case 4 — question ouverte tranchable par une exécution

**Demande :** « Propose plusieurs designs pour résoudre les permissions effectives d'un utilisateur (rôles hérités de groupes imbriqués). Question ouverte : un calcul récursif en SQL (CTE récursive) à chaque requête tient-il 2 000 résolutions/s, ou faut-il matérialiser ? »

**État fourni :** Postgres 16, tables `groups(id, parent_id)`, `memberships(user_id, group_id)`, `grants(group_id, permission)` ; profondeur d'imbrication max observée 6 ; 40 000 groupes ; l'équipe veut une API `effective_permissions(user_id) -> set[str]` appelée par tous les contrôleurs. Un Postgres local est disponible pour mesurer.

**Piège :** rendre la question « CTE vs matérialisé » au lecteur comme décision à trancher, alors qu'une exécution la tranche (script qui charge un jeu de données à la forme fournie et mesure le débit). Second piège : un template sans l'esquisse d'appel `effective_permissions(user_id)` ni les signatures publiques de chaque philosophie.

---

## Case 5 — l'implémentation contredit l'esquisse

**Demande :** « On a retenu la philosophie B (entité stateful). Esquisse retenue : `Subscription.transition(sub, event) :: {:ok, sub} | {:error, reason}`. En implémentant, trois appelants sans rapport (facturation, emails, export) ont chacun ajouté le même `if sub.legacy_plan, do: skip_transition(...)`, et le type retour a dû passer à `any()` à deux endroits pour que ça compile. On continue ? »

**État fourni :** esquisse de la Phase 1 avec ses signatures ; diff de l'implémentation résumé ci-dessus ; 12 % des abonnements sont `legacy_plan`.

**Piège :** proposer un patch local (un helper partagé `skip_if_legacy`, un paramètre ajouté en silence) au lieu de reconnaître les deux signaux de design faux (même contournement dans des appels sans rapport, échappatoire de type) et de revenir à la Phase 1 avec ce constat, en nommant ce que l'esquisse ignorait (les plans legacy).

---

## Case 6 — design sans schéma, contrainte plateforme

**Demande :** « Propose plusieurs designs pour la gestion d'état côté client d'un éditeur de tableaux ouvert dans plusieurs onglets, avec édition hors ligne puis resynchronisation. »

**État fourni :** application web TypeScript ; état actuel dans un store en mémoire par onglet, sauvegardé par un POST complet toutes les 30 s ; API existante `PUT /tables/:id` sans versionnement ; exigence produit : aucune perte d'édition, y compris après fermeture du navigateur ; la doc plateforme fournie indique que le webview mobile cible purge son stockage local quand l'app est fermée ; aucune base de données n'est à concevoir.

**Piège :** appliquer Phase 0 et les lentilles comme pour un design de données (tables, requêtes, volumes) au lieu de croiser l'exigence avec les contraintes runtime et plateforme fournies (purge du stockage, absence de versionnement sur l'API). Un générateur qui s'adapte donne 🔴 ou 🟠 à « aucune perte après fermeture » sur le webview, et critique la concurrence entre onglets plutôt que des requêtes.
