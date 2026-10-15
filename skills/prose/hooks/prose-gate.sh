#!/usr/bin/env bash
# Prose gate: the mechanical half of the prose skill (SKILL.md and VOICE.md).
#
#   prose-gate.sh stop   Stop hook: lint the reply the agent just wrote.
#   prose-gate.sh doc    PostToolUse hook: lint the .md or .html file a Write or Edit
#                        just touched, or the content/description/body string of any
#                        other tool call the matcher sends (a docs or tracker tool).
#
# Judgment calls (answer first, one why, what a cold reader lacks) stay in the skill.
# Fail-open on any missing input. Stop mode never blocks: a blocked reply is written
# a second time, which doubles its cost, so findings come back as a system message.
# Doc mode blocks: fixing a document is one Edit.
set -uo pipefail

SKILL_DIR=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
MODE=${1:-stop}
MAX_SENTENCE=40
MAX_PARAGRAPH=120

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

# ---------- HTML pages: the same text a reader sees, in the markdown shapes the checks know ----------
# style/script/svg dropped; h1-h3 become "## " lines; table rows, blockquotes and pre blocks take
# the markdown prefixes the prose filter skips; inline code keeps its backticks; entities unescaped.
html_to_text() {
  perl -0777 -pe '
    s{<(style|script|svg)\b[^>]*>.*?</\1>}{}gis;
    s{<!--.*?-->}{}gs;
    s{<pre\b[^>]*>(.*?)</pre>}{"\n```\n".$1."\n```\n"}gise;
    s{<h[1-3]\b[^>]*>}{\n\n## }gi;  s{</h[1-3]>}{\n}gi;
    s{<blockquote\b[^>]*>}{\n> }gi;
    s{<tr\b[^>]*>}{\n| }gi;
    s{<(p|div|li|br|h[4-6]|section|article|figcaption)\b[^>]*>}{\n}gi;
    s{<code\b[^>]*>(.*?)</code>}{`$1`}gis;
    s{<[^>]+>}{ }g;
    s{&nbsp;}{ }g; s{&amp;}{&}g; s{&lt;}{<}g; s{&gt;}{>}g; s{&quot;}{"}g; s{&#0*39;|&apos;}{\x27}g;
    s{&#x([0-9a-f]+);}{chr(hex($1))}gie; s{&#(\d+);}{chr($1)}ge;
    s{[ \t]+}{ }g; s{\n[ \t]+}{\n}g; s{\n{3,}}{\n\n}g;
  ' "$1" 2>/dev/null
}

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
          *.md|*.html|*.htm) ;;
          *) exit 0 ;;
        esac
        # Agent configuration and vendored files are not documents a person reads.
        case "$file" in
          */.claude/*|*/CLAUDE.md|*/AGENTS.md|*/node_modules/*|"$HOME/.config/"*) exit 0 ;;
        esac
        [ -f "$file" ] || exit 0
        case "$file" in
          *.html|*.htm) text=$(html_to_text "$file") ;;
          *) text=$(cat "$file") ;;
        esac
        label="$file"
        ;;
      *)
        text=$(printf '%s' "$input" | jq -r '
          .tool_input as $t
          | [ $t.content?, $t.description?, $t.body? ]
          | map(select(type == "string" and . != "")) | join("\n\n")' 2>/dev/null)
        label="the text you just saved with $tool"
        ;;
    esac
    ;;
  *) exit 0 ;;
esac


# ---------- required formats are not prose ----------
# YAML frontmatter at the top of a file (skill and agent definitions) is key: value data.
text=$(printf '%s\n' "$text" | awk 'NR == 1 && /^---[[:space:]]*$/ { fm = 1; next } fm && /^---[[:space:]]*$/ { fm = 0; next } !fm { print }')
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
tells='verbatim|corroborations?|crucially|importantly|it is important to note|it is worth noting|clearly|obviously|essentially|basically|in other words|to put it simply|needless to say|note that|consequently|crucial'
hits=$(printf '%s\n' "$prose" | grep -oiE "(^|[^[:alnum:]])($tells)([^[:alnum:]]|$)" 2>/dev/null | sed -E 's/^[^[:alnum:]]+//; s/[^[:alnum:]:]+$//' | sort -fu | head -8)
[ -n "$hits" ] && add "emphasis or scaffolding words: $(printf '%s' "$hits" | paste -sd, - | sed 's/,/, /g'). State the point; the consequence leads, it does not get announced."

# 1b. AI tells, the VOICE.md list. Exact phrases: each one is a tell on its own.
ai='here'"'"'s the thing|the truth is,|let me be clear|here'"'"'s the kicker|here'"'"'s where it gets interesting|let'"'"'s dive in|let'"'"'s unpack|let'"'"'s break this down|without further ado|in today'"'"'s [a-z-]* (world|landscape)|it'"'"'s worth noting|at the end of the day|in a world where|let that sink in|make no mistake|that'"'"'s it\. that'"'"'s the|serves as a testament|delve|tapestry|multifaceted|holistic|groundbreaking|transformative|indelible|paramount|quintessential|showcases|fosters|garners|bolsters|spearheads|galvanizes|nexus|interplay|cornerstone'
ah=$(printf '%s\n' "$prose" | grep -oiE "$ai" 2>/dev/null | sort -fu | head -8)
[ -n "$ah" ] && add "AI tells: $(printf '%s' "$ah" | paste -sd, - | sed 's/,/, /g'). State the point without the preamble, name the actor, use the plain verb (VOICE.md in the prose skill)."

# 1c. Openers that flatter and closers that offer more: the reply starts on the answer and ends on content.
frame='great question|good question|you'"'"'re absolutely right|you are absolutely right|hope this helps|let me know if|feel free to|don'"'"'t hesitate to'
fh=$(printf '%s\n' "$prose" | grep -oiE "$frame" 2>/dev/null | sort -fu | head -6)
[ -n "$fh" ] && add "openers or closers: $(printf '%s' "$fh" | paste -sd, - | sed 's/,/, /g'). Start on the answer, end on content or the directed ask."

# 1d. Glue at the start of a sentence: transitions, signposting numerals, a dangling "this".
glue='(that said|moving forward|going forward|building on this|with that in mind|at this point|in this context|first(ly)?|second(ly)?|third(ly)?|finally|lastly),|this (ensures|allows|means|enables|makes|helps)'
gh=$(printf '%s\n' "$prose" | grep -oiE "(^|[.!?] +)($glue)" 2>/dev/null | sed -E 's/^[.!?] +//; s/,$//' | sort -fu | head -6)
[ -n "$gh" ] && add "sentence-start glue: $(printf '%s' "$gh" | paste -sd, - | sed 's/,/, /g'). The sentence stands alone; a dangling \"this\" gets its noun; a numbered sequence goes in a table."

# 1e. Hedge stacks and pair-up flourishes.
hedge='may potentially|could potentially|it seems that|arguably|to some extent|in many cases|not only [^.!?]{1,60} but also|more than just|beyond just'
hh=$(printf '%s\n' "$prose" | grep -oiE "$hedge" 2>/dev/null | sort -fu | head -6)
[ -n "$hh" ] && add "hedges or pair-ups: $(printf '%s' "$hh" | paste -sd, - | sed 's/,/, /g'). One claim, stated; \"X and Y\" instead of \"not only X but also Y\"."

# 1f. Bullets in changelog voice (a past participle with no subject).
changelog=$(printf '%s\n' "$prose" | grep -oiE '^[[:space:]]*[-*] (\*\*)?(added|improved|fixed|updated|removed|refactored|implemented)' | sed -E 's/^[[:space:]]*[-*] //; s/\*\*//' | sort -fu | head -4)
[ -n "$changelog" ] && add "bullets in changelog voice: $(printf '%s' "$changelog" | paste -sd, - | sed 's/,/, /g'). Give each one a subject, or move the list into a table."

# 1f2. Test counts in prose: the check is named, the number is evidence.
counts=$(printf '%s\n' "$prose" | grep -oiE '[0-9][0-9 ,]* (tests?|specs?|assertions?) ?(pass|green|run|ok)?|0 failures?' 2>/dev/null | sort -fu | head -4)
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

# 2b. A label and a colon standing in for a sentence ("Result: ...", "Bottom line: ...",
# "- **Cost:** two days"): one to three words opening a line or a sentence, then a spaced colon.
# A colon glued to its left neighbour (14:30, https://) is not a label.
labels=$(printf '%s\n' "$prose" | grep -oE "(^|[.!?] +)([-*] |[0-9]+\. |#+ )?(\*\*)?[[:alpha:]][[:alnum:]'’-]*( [[:alnum:]'’-]+){0,2}(\*\*)? ?:(\*\*)? +[^ ]" 2>/dev/null \
  | sed -E 's/^[.!?] +//; s/^([-*] |[0-9]+\. |#+ )//; s/\*\*//g; s/ *:.*$//' \
  | grep -vE '^[a-z0-9]+(-[a-z0-9]+)+$' | sort -fu | head -6)
[ -n "$labels" ] && add "labels standing in for a sentence: $(printf '%s' "$labels" | paste -sd, - | sed 's/,/, /g'). Write the sentence; the label becomes its subject or goes."

# 2c. Status emoji, in tables and headings too.
emoji=$(printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { fence = !fence; next } fence { next } /^[[:space:]]*>/ { next } { print }' | grep -oE '✅|❌|⚠️|✔️?|✓|🚀|🔴|🟢|🟡|🟠|👉|💡|🎯|📌|🔥|⭐|🧠|🛠️?' 2>/dev/null | sort -u | paste -sd' ' -)
[ -n "$emoji" ] && add "status emoji: $emoji. Words."

# 2d. Generic headings, bold or #-prefixed: a heading is a question that carries its stake.
generic=$(printf '%s\n' "$text" | grep -oiE '^[[:space:]]*(#+ |\*\*)(overview|summary|introduction|background|context|conclusion|next steps|key takeaways|takeaways|tl;dr)(\*\*)?[[:space:]]*$' | sed -E 's/^[[:space:]]*(#+ |\*\*)//; s/\*\*//' | sort -fu | head -4)
[ -n "$generic" ] && add "generic headings: $(printf '%s' "$generic" | paste -sd, - | sed 's/,/, /g'). A heading is the question the section answers."

# 3. Doc-only: proof trail and session bookkeeping; bold headings that are not questions.
if [ "$MODE" = doc ]; then
  trail='I verified|we verified|as verified|verified in the code|(decided|agreed) on [0-9]{1,2}/[0-9]{1,2}|this morning|in this session|earlier today'
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
      if (h ~ /^(What |Which |Who |When |Where |How |Why |Should |Does |Do |Is |Are |Can |Will )/) next
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
    jq -n --arg m "[prose-gate] $(printf '%s' "$findings" | head -c 400)" '{suppressOutput: true, systemMessage: $m}'
    ;;
  doc)
    jq -n --arg r "$reason" '{decision: "block", reason: $r}'
    ;;
esac
exit 0
