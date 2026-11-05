# Lightweight tree output implementation plan

**Goal:** Output clean tree diagrams from a separate Julia package, as requested.
**Architecture:** TTNPlots writes standalone SVG and text using Base only;
an optional TTNSolver extension reads topology, leaf dimensions and bond ranks.
Example-only dependencies live in TTNDynamics/examples/Project.toml, keeping
visualization out of the dynamics and solver runtime dependency graphs.

The user requested a separate, lightweight package and clean figures. Choose
SVG over a plotting framework to avoid native plotting libraries and retain
editable vector output. No browser, Graphviz, Python or network needed to render.

- [x] Implement tree_svg, write_tree_svg, tree_text with validated binary-tree
  input. Preserve physical leaf metadata while laying out leaves in traversal
  order to avoid crossing edges. Handle one-leaf trees and wrap long labels.
- [x] Add TTNSolver extension, with dimensions in leaf_order and ranks by node ID.
  Check single-root, permuted leaves, malformed trees, XML escaping and IO output.
- [x] Integrate Holstein–TFD and HEOM adaptive examples: initial and final trees,
  leaf roles, dimensions, ranks, SVG and text files. Keep model labels in examples.
- [x] Run package tests and both examples; parse and visually inspect generated
  SVGs; obtain one final review. Do not commit unrelated existing changes.

Review focus: rank labels must come from the plotted state; custom leaf order
must not relabel nodes; arbitrary labels must not break XML; a single leaf
must not divide by zero; diagrams must remain legible for the default examples.

Verification: 27/27 package tests passed. Both default dynamics examples ran
and emitted initial/loose/tight SVG/text; XML node/edge counts match their trees.
Core-only loading did not load TTNSolver. Default SVGs are approximately 5–7 KB.
Final review found wide proportional glyphs could overflow; regression tests
failed before replacing terminal-column wrapping with conservative font-size
pixel estimates, and passed after the fix. Default and wide-label figures were
rendered locally for visual inspection; no rendering tools are package deps.
