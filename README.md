# TTNPlots.jl

Lightweight tensor-tree figures: standalone SVG and readable text, written
directly in Julia. The core package has **no runtime dependencies**. It needs
neither a plotting framework nor Graphviz, a browser, Python or native drawing
libraries. SVGs retain editable text, scale without pixelation and open in
browsers and IDE previews. Requires Julia 1.11+.

```julia
using TTNPlots

children = [(0,0), (0,0), (1,2)]
write_tree_svg("tree.svg", children;
    title="Two-mode tree",
    leaf_labels=["Electronic state", "Vibration"],
    dimensions=[4,8], ranks=[2,2,1])
print(tree_text(children; dimensions=[4,8], ranks=[2,2,1]))
```

With TTNSolver loaded, an optional Julia package extension accepts its tree
and state types. It reads dimensions and ranks without contracting tensors or
expanding a dense state:

```julia
using TTNSolver, TTNPlots

state = product_state(balanced_tree(3), [ones(4),ones(3),ones(3)])
write_tree_svg("tree.svg", state;
    title="Thermofield tree", subtitle="Initial state",
    leaf_labels=["Electron + ancilla", "Oscillator · +ω", "Oscillator · −ω"],
    leaf_details=["physical × inactive", "n = 0:2", "n = 0:2"],
    leaf_colors=["#4263aa", "#25887e", "#b17c38"])
write("tree.txt", tree_text(state))
```

- `tree_svg(subject; ...)` returns an SVG string; `write_tree_svg(path, subject;
  ...)` writes it and returns the path. `tree_text(subject; ...)` returns text.
- For raw children, `(0,0)` marks a leaf, and the default root is the last node.
  `root` and `leaf_order` can be supplied. Trees must be connected and binary.
- Leaf labels, details, colors and dimensions follow **physical `leaf_order`**;
  ranks follow **node IDs**. State defaults can be overridden explicitly.
- Layout follows left/right traversal to prevent crossing branches for permuted
  physical order. Cards wrap long labels; canvas width grows with leaf count.
- SVG-only keywords are `title` and `subtitle`. The metadata keywords
  `leaf_labels`, `leaf_details`, `leaf_colors`, `dimensions`, `ranks` work for
  both outputs. Colors use `#RRGGBB`; user text is XML escaped.
- Figures show the topology/ranks of the supplied state, including a single
  leaf/root. No numerical state is modified. Model names and units belong to
  the calling example, keeping this package independent of HEOM and TFD.

For this workspace, run the integrated examples from sibling TTNDynamics:

```sh
julia --project=examples -e 'using Pkg; Pkg.instantiate()'
julia --project=examples examples/holstein_tfd/dynamics.jl
julia --project=examples examples/heom/adaptive_dynamics/run.jl
julia --project=examples examples/heom/bug_dynamics/run.jl
```

That example environment resolves TTNPlots, TTNSolver and TTNDynamics from
sibling paths. The adaptive HEOM and Holstein TFD dynamics examples save initial
and final trees as `.svg` and `.txt` under their `trees/` directories.
TTNSolver and TTNDynamics do not depend on this visualization package.

Run package tests from TTNPlots with `julia --project=. -e 'using Pkg; Pkg.test()'`.
The test target loads TTNSolver to check its optional extension; a normal
`using TTNPlots` does not load it. SVG is the output format; PNG/PDF conversion
can be done externally if needed and is not a package dependency.
