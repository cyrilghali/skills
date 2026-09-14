#!/usr/bin/env bash
# Prose gate (personal, all repos). One tripwire for the three prose skills:
# the mechanical half of the voice pass (AI tells), of the cold read (compression walls)
# and of decision-prose (register of a document). Replaces deslop-gate.sh.
#
#   prose-gate.sh stop   Stop hook: lint the reply Claude just wrote.
#   prose-gate.sh doc    PostToolUse hook on Write|Edit of a .md file and on
#                        the Linear save_document / save_issue tools: lint the
#                        document text that was written.
#
# Both modes: AI tells (delve, tapestry, "let's dive in", ...), emphasis and
# scaffolding words (verbatim, exactement, clairement, "Conséquence :", ...),
# labels standing in for a sentence, flattering openers and closing offers,
# sentence-start glue, hedges, changelog bullets, exclamation marks, status
# emoji, generic headings, em dashes, sentences over 40 words, paragraphs over 120 words outside
# tables, code and quotes. Doc mode adds the proof trail and session
# bookkeeping ("j'ai vérifié", "session du", "décision du 04/09") and a bold
# heading line that is not a question. Judgment calls (answer first, one why,
# what a cold reader lacks, false agency, rhythm) stay in the skills.
#
# Guardrails: fail-open on any missing input; in stop mode an attempt cap so a
# stubborn reply still gets through.
set -uo pipefail

SKILL_DIR=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
MODE=${1:-stop}
MAX_ATTEMPTS=2
MAX_SENTENCE=40
MAX_PARAGRAPH=120

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

# ---------- collect the text to lint ----------
text=""
label=""
case "$MODE" in
  stop)
    transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
    [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
    # The last assistant message that carries text: the reply the user is about to read.
    # Lines cut by tail fail to parse and are dropped before the slurp.
    text=$(tail -n 400 "$transcript" 2>/dev/null \
      | jq -c 'select(.type == "assistant")' 2>/dev/null \
      | jq -rs '[ .[] | (.message.content // []) | map(select(.type == "text") | .text) | select(length > 0) | join("\n") ] | last // empty' 2>/dev/null)
    label="your reply"
    ;;
  doc)
    tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
    case "$tool" in
      Write|Edit)
        file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
        case "$file" in
          *.md) ;;
          *) exit 0 ;;
        esac
        # Files the user never reads as documents: memory, skills, hooks, plans.
        case "$file" in
          "$HOME/.claude/"*|*/.claude/*|*/memory/*|*/CLAUDE.md|*/node_modules/*) exit 0 ;;
        esac
        [ -f "$file" ] || exit 0
        text=$(cat "$file")
        label="$file"
        ;;
      mcp__linear-server__save_document|mcp__linear-server__save_issue)
        text=$(printf '%s' "$input" | jq -r '
          .tool_input as $t
          | [ $t.content?, $t.description?,
              ($t.patch[]? | .new_string?, .text?) ]
          | map(select(. != null and . != "")) | join("\n\n")' 2>/dev/null)
        label="the Linear text you just saved"
        ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

[ -n "$text" ] && printf '%s' "$text" | grep -q . || exit 0

# ---------- prose only: drop fenced code, quotes, tables, inline code, links ----------
prose=$(printf '%s\n' "$text" | awk '
  /^[[:space:]]*```/ { fence = !fence; next }
  fence { next }
  /^[[:space:]]*>/ { next }
  /^[[:space:]]*\|/ { next }
  { gsub(/`[^`]*`/, ""); gsub(/\]\([^)]*\)/, "]"); print }
')

findings=""
add() { findings="${findings}${findings:+
}- $1"; }

# 1. Emphasis and scaffolding words. Exact phrases: each one is a tell on its own.
tells='verbatim|corroborations?|exactement|clairement|simplement|évidemment|bien sûr|il est important de|à noter que|notez que|conséquence :|note :|attention :|en résumé|pour résumer|autrement dit|en d'"'"'autres termes|il faut savoir que|tout d'"'"'abord|crucially|importantly|it is worth noting|clearly|obviously|essentially|basically|in other words|to put it simply|note that|consequently|il convient de|il est à noter|force est de constater|il s'"'"'agit de|concrètement|in fine|au final|impacter|impactée?s?|crucial|incontournable'
hits=$(printf '%s\n' "$prose" | grep -oiE "(^|[^[:alnum:]])($tells)([^[:alnum:]]|$)" 2>/dev/null | sed -E 's/^[^[:alnum:]]+//; s/[^[:alnum:]:]+$//' | sort -fu | head -8)
[ -n "$hits" ] && add "emphasis or scaffolding words: $(printf '%s' "$hits" | paste -sd, - | sed 's/,/, /g'). State the point; the consequence leads, it does not get announced."

# 1b. AI tells, the VOICE.md list. Exact phrases: each one is a tell on its own.
ai='here'"'"'s the thing|the truth is,|let me be clear|here'"'"'s the kicker|here'"'"'s where it gets interesting|let'"'"'s dive in|let'"'"'s unpack|let'"'"'s break this down|without further ado|in today'"'"'s [a-z-]* (world|landscape)|it'"'"'s worth noting|at the end of the day|in a world where|let that sink in|make no mistake|that'"'"'s it\. that'"'"'s the|serves as a testament|delve|tapestry|multifaceted|holistic|groundbreaking|transformative|indelible|paramount|quintessential|showcases|fosters|garners|bolsters|spearheads|galvanizes|nexus|interplay|cornerstone'
ah=$(printf '%s\n' "$prose" | grep -oiE "$ai" 2>/dev/null | sort -fu | head -8)
[ -n "$ah" ] && add "AI tells: $(printf '%s' "$ah" | paste -sd, - | sed 's/,/, /g'). State the point without the preamble, name the actor, use the plain verb (VOICE.md in the prose skill)."

# 1c. Openers that flatter and closers that offer more: the reply starts on the answer and ends on content.
frame='great question|good question|you'"'"'re absolutely right|you are absolutely right|bonne question|excellente question|bonne remarque|hope this helps|let me know if|feel free to|n'"'"'hésitez pas|don'"'"'t hesitate to'
fh=$(printf '%s\n' "$prose" | grep -oiE "$frame" 2>/dev/null | sort -fu | head -6)
[ -n "$fh" ] && add "openers or closers: $(printf '%s' "$fh" | paste -sd, - | sed 's/,/, /g'). Start on the answer, end on content or the directed ask."

# 1d. Glue at the start of a sentence: transitions, signposting numerals, a dangling "this".
glue='(that said|moving forward|going forward|building on this|with that in mind|at this point|in this context|cela dit|à ce stade|dans ce contexte|dans un (premier|second|deuxième) temps|first(ly)?|second(ly)?|third(ly)?|finally|lastly|ensuite|enfin|premièrement|deuxièmement),|(this|cela|ceci) (ensures|allows|means|enables|makes|helps|permet|garantit|signifie|assure)'
gh=$(printf '%s\n' "$prose" | grep -oiE "(^|[.!?] +)($glue)" 2>/dev/null | sed -E 's/^[.!?] +//; s/,$//' | sort -fu | head -6)
[ -n "$gh" ] && add "sentence-start glue: $(printf '%s' "$gh" | paste -sd, - | sed 's/,/, /g'). The sentence stands alone; a dangling \"this\" gets its noun; a numbered sequence goes in a table."

# 1e. Hedge stacks and pair-up flourishes.
hedge='may potentially|could potentially|it seems that|arguably|to some extent|in many cases|il semble que|dans une certaine mesure|not only [^.!?]{1,60} but also|more than just|beyond just|non seulement [^.!?]{1,60} mais (aussi|également)'
hh=$(printf '%s\n' "$prose" | grep -oiE "$hedge" 2>/dev/null | sort -fu | head -6)
[ -n "$hh" ] && add "hedges or pair-ups: $(printf '%s' "$hh" | paste -sd, - | sed 's/,/, /g'). One claim, stated; \"X and Y\" instead of \"not only X but also Y\"."

# 1f. Bullets in changelog voice (a past participle with no subject).
changelog=$(printf '%s\n' "$prose" | grep -oiE '^[[:space:]]*[-*] (\*\*)?(added|improved|fixed|updated|removed|refactored|implemented|ajouté|amélioré|corrigé|mis à jour|supprimé)' | sed -E 's/^[[:space:]]*[-*] //; s/\*\*//' | sort -fu | head -4)
[ -n "$changelog" ] && add "bullets in changelog voice: $(printf '%s' "$changelog" | paste -sd, - | sed 's/,/, /g'). Give each one a subject, or move the list into a table."

# 1f2. Test counts in prose: the check is named, the number is evidence.
counts=$(printf '%s\n' "$prose" | grep -oiE '[0-9][0-9 ,]* (tests?|specs?|assertions?) ?(pass|green|run|ok|verts?|passent)?|0 (failures?|échecs?)' 2>/dev/null | sort -fu | head -4)
[ -n "$counts" ] && add "test counts: $(printf '%s' "$counts" | paste -sd, - | sed 's/,/, /g'). Say the suite is green; the number stays out."

# 1g. Exclamation marks in prose.
if printf '%s\n' "$prose" | grep -qE '[[:alpha:])]!([[:space:]]|$)'; then
  add "exclamation marks. A full stop."
fi

# 2. Em dashes.
# Tables and headings count too: an em dash in a cell is still an em dash.
if printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { fence = !fence; next } fence { next } /^[[:space:]]*>/ { next } { print }' | grep -q '—'; then
  add "em dashes. Use a comma, two sentences, or a colon inside the sentence."
fi

# 2b. A label and a colon standing in for a sentence ("Résultat : ...", "Bottom line: ...",
# "- **Cost:** two days"): one to three words opening a line or a sentence, then a spaced colon.
# A colon glued to its left neighbour (14:30, https://) is not a label.
labels=$(printf '%s\n' "$prose" | grep -oE "(^|[.!?] +)([-*] |[0-9]+\. |#+ )?(\*\*)?[[:alpha:]][[:alnum:]'’-]*( [[:alnum:]'’-]+){0,2}(\*\*)? ?:(\*\*)? +[^ ]" 2>/dev/null \
  | sed -E 's/^[.!?] +//; s/^([-*] |[0-9]+\. |#+ )//; s/\*\*//g; s/ *:.*$//' | sort -fu | head -6)
[ -n "$labels" ] && add "labels standing in for a sentence: $(printf '%s' "$labels" | paste -sd, - | sed 's/,/, /g'). Write the sentence; the label becomes its subject or goes."

# 2c. Status emoji, in tables and headings too.
emoji=$(printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { fence = !fence; next } fence { next } /^[[:space:]]*>/ { next } { print }' | grep -oE '✅|❌|⚠️|✔️?|✓|🚀|🔴|🟢|🟡|🟠|👉|💡|🎯|📌|🔥|⭐|🧠|🛠️?' 2>/dev/null | sort -u | paste -sd' ' -)
[ -n "$emoji" ] && add "status emoji: $emoji. Words."

# 2d. Generic headings, bold or #-prefixed: a heading is a question that carries its stake.
generic=$(printf '%s\n' "$text" | grep -oiE '^[[:space:]]*(#+ |\*\*)(overview|summary|introduction|background|context|conclusion|next steps|key takeaways|takeaways|tl;dr|vue d'"'"'ensemble|résumé|contexte|prochaines étapes|points clés)(\*\*)?[[:space:]]*$' | sed -E 's/^[[:space:]]*(#+ |\*\*)//; s/\*\*//' | sort -fu | head -4)
[ -n "$generic" ] && add "generic headings: $(printf '%s' "$generic" | paste -sd, - | sed 's/,/, /g'). A heading is the question the section answers."

# 3. Doc-only: proof trail and session bookkeeping; bold headings that are not questions.
if [ "$MODE" = doc ]; then
  trail='j'"'"'ai vérifié|nous avons vérifié|vérifié dans le code|vérifié sur pièces|preuve :|session du|décision du [0-9]{2}/[0-9]{2}|décidé le|acté le|chiffré le|vérifié le|ce matin|dans cette session|I verified|we verified|as verified'
  th=$(printf '%s\n' "$prose" | grep -oiE "$trail" 2>/dev/null | sort -fu | head -6)
  [ -n "$th" ] && add "proof trail or session bookkeeping: $(printf '%s' "$th" | paste -sd, - | sed 's/,/, /g'). A document records the decision and what it changes; how you got convinced stays in the session reply."

  bad_headings=$(printf '%s\n' "$text" | awk '
    /^[[:space:]]*\*\*[^*]+\*\*[[:space:]]*$/ {
      h = $0; sub(/^[[:space:]]*\*\*/, "", h); sub(/\*\*[[:space:]]*$/, "", h)
      # a heading that labels a table is a label, not a question
      getline nxt
      while (nxt ~ /^[[:space:]]*$/) { if ((getline nxt) <= 0) break }
      if (nxt ~ /^[[:space:]]*\|/) next
      if (h ~ /\?[[:space:]]*$/) next
      if (h ~ /^(Quel|Quelle|Quels|Quelles|Que |Qu.|Qui |Quand |Où |Comment |Pourquoi |Combien |Faut-il|Doit-on|Peut-on|Est-ce|What |Which |Who |When |Where |How |Why |Should |Does |Do |Is |Can )/) next
      print h
    }' | head -4)
  [ -n "$bad_headings" ] && add "bold headings that are not questions: $(printf '%s' "$bad_headings" | paste -sd'|' - | sed 's/|/ | /g'). A heading is a question that carries its own alternatives."

  # 3b. A quoted phrase inside a question heading is usually the author's coinage, not a real quote.
  quoted_headings=$(printf '%s\n' "$text" | grep -E '^[[:space:]]*\*\*[^*]*\?[[:space:]]*\*\*[[:space:]]*$' | grep -oE '"[^"]{3,40}"|«[^»]{3,40}»|“[^”]{3,40}”' | head -3)
  [ -n "$quoted_headings" ] && add "quoted phrase in a heading: $(printf '%s' "$quoted_headings" | paste -sd, - | sed 's/,/, /g'). Quotation marks hold a real quote (UI text, a user, a document); a phrase coined while working is written out as what it means."
fi

# 4. Long sentences (over MAX_SENTENCE words).
# A line that ends without punctuation (heading, list item, label) closes its sentence.
long_sentences=$(printf '%s\n' "$prose" | awk -v max="$MAX_SENTENCE" '
  { line = $0; if (line !~ /[.!?]["»)]*[[:space:]]*$/ && line !~ /^[[:space:]]*$/) line = line "."; buf = buf " " line }
  END {
    n = split(buf, s, /[.!?](["»)]*)([[:space:]]+|$)/)
    for (i = 1; i <= n; i++) {
      w = split(s[i], words, /[[:space:]]+/)
      if (w > max) { t = s[i]; gsub(/^[[:space:]]+/, "", t); printf "%d words: %.60s...\n", w, t }
    }
  }' | head -3)
[ -n "$long_sentences" ] && add "sentences over ${MAX_SENTENCE} words: $(printf '%s' "$long_sentences" | paste -sd'|' - | sed 's/|/ ; /g'). One idea per sentence."

# 5. Long paragraphs (over MAX_PARAGRAPH words).
# A list item is its own paragraph: a blank line is inserted before each one.
long_paragraphs=$(printf '%s\n' "$prose" | awk '/^[[:space:]]*([-*]|[0-9]+\.) / { print "" } { print }' | awk -v max="$MAX_PARAGRAPH" '
  BEGIN { RS = "" }
  { w = split($0, words, /[[:space:]]+/); if (w > max) { t = $0; gsub(/\n/, " ", t); printf "%d words: %.50s...\n", w, t } }' | head -3)
[ -n "$long_paragraphs" ] && add "paragraphs over ${MAX_PARAGRAPH} words: $(printf '%s' "$long_paragraphs" | paste -sd'|' - | sed 's/|/ ; /g'). Split into two questions, or move the detail into a table."

[ -z "$findings" ] && exit 0

reason="Prose gate on ${label}:
${findings}

Rewrite before finishing: answer first, one why, details in a table, no proof trail, no emphasis. See $SKILL_DIR/SKILL.md. Quoting a tell to discuss it does not count once it sits in a code fence or a blockquote."

case "$MODE" in
  stop)
    session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null || echo nosession)
    counter="/tmp/claude-prose-gate-${session}.n"
    n=$( [ -f "$counter" ] && cat "$counter" || echo 0 )
    n=$((n + 1))
    if [ "$n" -ge "$MAX_ATTEMPTS" ]; then
      rm -f "$counter"
      jq -n --arg m "[prose-gate] still failing after ${MAX_ATTEMPTS} attempts, letting the reply through: $(printf '%s' "$findings" | head -c 300)" \
        '{suppressOutput: true, systemMessage: $m}'
      exit 0
    fi
    printf '%s' "$n" > "$counter"
    jq -n --arg r "Prose gate (attempt ${n}/${MAX_ATTEMPTS}). ${reason}" '{decision: "block", reason: $r}'
    ;;
  doc)
    jq -n --arg r "$reason" '{decision: "block", reason: $r}'
    ;;
esac
exit 0
