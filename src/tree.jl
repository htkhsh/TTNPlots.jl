_escape(x) = replace(string(x), '&'=>"&amp;", '<'=>"&lt;", '>'=>"&gt;", '"'=>"&quot;", '\''=>"&apos;")

function _tree_data(children; root=length(children), leaf_order=nothing,
                    leaf_labels=nothing, leaf_details=nothing, leaf_colors=nothing,
                    dimensions=nothing, ranks=nothing)
    n = length(children)
    root isa Integer && 1 <= root <= n || throw(ArgumentError("root must be a valid node ID"))
    all(p -> p isa Tuple && length(p) == 2 && all(x -> x isa Integer, p), children) ||
        throw(ArgumentError("children must be pairs of node IDs; (0,0) marks a leaf"))
    all(p -> p == (0,0) || (1 <= p[1] <= n && 1 <= p[2] <= n && p[1] != p[2]), children) ||
        throw(ArgumentError("internal nodes need two distinct valid children"))
    visited = falses(n)
    depth = zeros(Int,n)
    postorder, traversal = Int[],Int[]
    function visit(node,level)
        visited[node] && throw(ArgumentError("tree contains a cycle or shared child"))
        visited[node] = true
        depth[node] = level
        if children[node] == (0,0)
            push!(traversal,node)
        else
            for child in children[node]
                visit(child,level+1)
            end
        end
        push!(postorder,node)
    end
    visit(root,0)
    all(visited) || throw(ArgumentError("all nodes must belong to the rooted tree"))
    order = isnothing(leaf_order) ? sort(traversal) : collect(leaf_order)
    all(x -> x isa Integer,order) && sort(order) == sort(traversal) ||
        throw(ArgumentError("leaf_order must contain every leaf exactly once"))
    count = length(order)
    labels = isnothing(leaf_labels) ? ["Mode $k" for k in 1:count] : string.(collect(leaf_labels))
    details = isnothing(leaf_details) ? fill("",count) : string.(collect(leaf_details))
    colors = isnothing(leaf_colors) ? fill("#547eaa",count) : string.(collect(leaf_colors))
    for (name,values) in (("leaf_labels",labels),("leaf_details",details),("leaf_colors",colors),("dimensions",dimensions))
        isnothing(values) || length(values) == count || throw(DimensionMismatch("$name must have one entry per physical leaf"))
    end
    all(c -> occursin(r"^#[0-9a-fA-F]{6}$",c),colors) || throw(ArgumentError("leaf colors must be #RRGGBB values"))
    isnothing(dimensions) || all(d -> d isa Integer && d > 0,dimensions) ||
        throw(ArgumentError("physical dimensions must be positive integers"))
    if !isnothing(ranks)
        length(ranks) == n || throw(DimensionMismatch("ranks must have one entry per node ID"))
        all(r -> r isa Integer && r > 0,ranks) || throw(ArgumentError("ranks must be positive integers"))
    end
    positions = Dict(node=>k for (k,node) in enumerate(order))
    return (; children,root,order,labels,details,colors,dimensions,ranks,positions,depth,postorder,traversal)
end

"""
    tree_text(children; root=length(children), leaf_order=nothing,
              leaf_labels=nothing, dimensions=nothing, ranks=nothing, ...)

Return a Unicode tree with node IDs, physical axes, dimensions and bond ranks.
`children[node] == (0,0)` marks a leaf. Leaf metadata follows `leaf_order`
(default: sorted leaf IDs); ranks are indexed by node ID. Labels are shown
in traversal order without changing which physical axis belongs to each node.
The optional TTNSolver extension also accepts BinaryTree and TTNTensor.
"""
function tree_text(children::AbstractVector; kwargs...)
    d = _tree_data(children; kwargs...)
    lines = String[]
    function visit(node,prefix,branch)
        parts = [node == d.root ? "root n$node" : "n$node"]
        if haskey(d.positions,node)
            p = d.positions[node]
            push!(parts,"p$p")
            isnothing(d.dimensions) || push!(parts,"d=$(d.dimensions[p])")
        end
        isnothing(d.ranks) || node == d.root || push!(parts,"r=$(d.ranks[node])")
        if haskey(d.positions,node)
            p = d.positions[node]
            push!(parts,replace(d.labels[p],r"\s+"=>" "))
            isempty(d.details[p]) || push!(parts,replace(d.details[p],r"\s+"=>" "))
        end
        push!(lines,prefix*branch*join(parts," · "))
        if d.children[node] != (0,0)
            next = prefix*(branch == "├─ " ? "│  " : branch == "└─ " ? "   " : "")
            visit(d.children[node][1],next,"├─ ")
            visit(d.children[node][2],next,"└─ ")
        end
    end
    visit(d.root,"","")
    return join(lines,'\n')*"\n"
end

# Conservative widths in em for the sans-serif fallback fonts. Terminal
# column counts alone underestimate wide proportional glyphs (especially W).
function _glyph_em(c)
    textwidth(c) == 0 && return 0.0
    !isascii(c) && return 1.25max(1,textwidth(c)/2)
    c in "W@%" && return 1.25
    c in "Mm" && return 1.1
    c == 'w' && return 1.0
    c in "ilI.,:;!'|` " && return 0.4
    isuppercase(c) && return 0.9
    return 0.75
end

_text_pixels(value,fontsize) = fontsize*sum(_glyph_em(c) for c in value;init=0.0)

# Wrap to a pixel budget without querying a native font library.
function _wrap_label(value,limit;fontsize)
    text = string(value)
    if occursin('\n',text)
        return reduce(vcat,[_wrap_label(line,limit;fontsize) for line in split(text,'\n')];init=String[])
    end
    lines = String[]
    line = ""
    for word in split(text)
        if !isempty(line) && _text_pixels(line*" "*word,fontsize) > limit
            push!(lines,line)
            line = ""
        end
        !isempty(line) && (line *= " ")
        for c in word
            if !isempty(line) && _text_pixels(line*c,fontsize) > limit
                push!(lines,line)
                line = ""
            end
            line *= c
        end
    end
    isempty(line) || push!(lines,line)
    return lines
end
