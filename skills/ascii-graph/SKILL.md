---
name: ascii-graph
description: Draws algorithmic graphs (nodes and edges, DAGs, trees, state machines, pipelines) as Unicode box-drawing art for visual explanations in the terminal, and keeps a library of saved drawings printed with one command. Use when the user asks to "draw a graph", "ascii graph", "show it as a diagram in the terminal", "visualize this DAG/tree/flow", "save this graph", or "show the [name] graph".
metadata:
  category: write
---

# Drawing an ASCII graph

Draw the graph as box-drawing art in a fenced code block, so it reads in a terminal without a browser. Check the library first, because a saved drawing beats a fresh one.

## Check the library first

Run `scripts/graph list`. If a saved graph fits the request, print it with `scripts/graph <name>` and stop. Done when a saved graph is shown or none fits.

## Draw the graph left to right

Draw it inline in a fenced code block, with the characters below. Lay it out horizontally, never as a vertical flow: one left-to-right line that ends in `▶`, with node names above the line and short notes below. Put each branch on its own parallel horizontal line. Let the width pass 80 columns; wrap onto a second horizontal line only past 160. Write edge weights and labels on the edge itself. Done when every node and edge from the source appears once and no line crosses a node.

| Use | Characters |
|---|---|
| Node | `(A)` for a vertex, `┌─┐ │ │ └─┘` for a labeled box |
| Lines | `─ │` straight, `┌ ┐ └ ┘` corners, `├ ┤ ┬ ┴ ┼` junctions |
| Arrows | `▶ ◀ ▲ ▼` |
| Label | text or weight written on the line: `──3──▶` |

Follow this example:

```
 (A)──4──▶(B)──5──▶(D)──3──▶(E)
 (A)──2──▶(C)──1──▶(B)
          (C)──8──▶(D)
```

It is saved as `weighted-dag`; `scripts/graph weighted-dag` prints it.

## Save a drawing worth reusing

Save the graph when the user asks, or when it explains something reusable: `scripts/graph save <kebab-name> <<'EOF' … EOF`. Done when `scripts/graph <name>` prints it back identically.

## Use the script this way

`scripts/graph` with no argument or `list` lists the saved names; `<name>` prints one; `save <name>` reads the drawing from stdin. The library is `library/` beside the script, or `$ASCII_GRAPH_LIB` when that variable is set.
