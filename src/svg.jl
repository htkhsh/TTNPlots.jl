"""
    tree_svg(children; title="Tensor tree", subtitle="", kwargs...) -> String

Render a standalone, editable SVG with no plotting or native library dependency.
Accepts the topology/metadata keywords of tree_text, plus leaf_details and
leaf_colors (#RRGGBB). Text wraps within the leaf cards; canvas width grows
with leaf count. Traversal order prevents crossing edges even when the physical
leaf order is permuted. The optional TTNSolver extension accepts trees/states.
No tensor contraction or dense expansion is performed.
"""
function tree_svg(children::AbstractVector; title="Tensor tree", subtitle="",kwargs...)
    d = _tree_data(children;kwargs...)
    count = length(d.order)
    card_width,gap,margin = 210,26,40
    width = max(760,2margin+count*(card_width+gap)-gap)
    label_lines = [_wrap_label(s,card_width-44;fontsize=13) for s in d.labels]
    detail_lines = [_wrap_label(s,card_width-44;fontsize=11) for s in d.details]
    card_height = maximum(46+19length(label_lines[k])+16length(detail_lines[k]) for k in 1:count)
    titles = _wrap_label(title,width-2margin;fontsize=28)
    subtitles = _wrap_label(subtitle,width-2margin;fontsize=13)
    header_end = 56+32length(titles)+19length(subtitles)
    root_y = header_end+64
    leaf_top = count == 1 ? root_y-18 : root_y+112maximum(d.depth)
    height = leaf_top+card_height+74
    xs,ys = zeros(Float64,length(children)),zeros(Float64,length(children))
    lo,hi = similar(xs),similar(xs)
    origin = (width-(count*(card_width+gap)-gap))/2+card_width/2
    for (k,node) in enumerate(d.traversal)
        xs[node] = lo[node] = hi[node] = origin+(k-1)*(card_width+gap)
        ys[node] = leaf_top
    end
    for node in d.postorder
        children[node] == (0,0) && continue
        left,right = children[node]
        lo[node],hi[node] = lo[left],hi[right]
        xs[node] = (lo[node]+hi[node])/2
        ys[node] = root_y+112d.depth[node]
    end
    io = IOBuffer()
    println(io,"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\" aria-labelledby=\"ttn-title ttn-desc\">")
    println(io,"<title id=\"ttn-title\">$(_escape(title))</title><desc id=\"ttn-desc\">$(_escape(subtitle)) — $count physical axes, $(length(children)) nodes.</desc>")
    println(io,"<style>text{font-family:Inter,'Segoe UI','Noto Sans',Arial,sans-serif;fill:#203349}.muted{fill:#66788a}.root-text{fill:white}.edge{fill:none;stroke:#9dabb9;stroke-width:1.8}.rank{font-size:12px;font-weight:600;fill:#405c76}</style>")
    println(io,"<rect width=\"100%\" height=\"100%\" rx=\"16\" fill=\"#f8fafc\"/>")
    println(io,"<text x=\"$margin\" y=\"30\" font-size=\"10\" font-weight=\"700\" letter-spacing=\"2\" class=\"muted\">TTN / STRUCTURE</text>")
    for (k,line) in enumerate(titles)
        println(io,"<text x=\"$margin\" y=\"$(36+32k)\" font-size=\"28\" font-weight=\"650\">$(_escape(line))</text>")
    end
    for (k,line) in enumerate(subtitles)
        println(io,"<text x=\"$margin\" y=\"$(44+32length(titles)+19k)\" font-size=\"13\" class=\"muted\">$(_escape(line))</text>")
    end
    println(io,"<text x=\"$margin\" y=\"$(header_end+20)\" font-size=\"11\" class=\"muted\">$count physical axes   /   $(length(children)) nodes</text>")
    for parent in eachindex(children)
        children[parent] == (0,0) && continue
        for child in children[parent]
            x0,x1 = xs[parent],xs[child]
            y0,y1 = ys[parent]+20,ys[child]-(children[child] == (0,0) ? 0 : 20)
            xm,ym = (x0+x1)/2,(y0+y1)/2
            println(io,"<path class=\"edge\" d=\"M $x0 $y0 C $x0 $ym $x1 $ym $x1 $y1\"/>")
            if !isnothing(d.ranks)
                label = "r=$(d.ranks[child])"
                badge_width = 18+8textwidth(label)
                println(io,"<rect x=\"$(xm-badge_width/2)\" y=\"$(ym-11)\" width=\"$badge_width\" height=\"22\" rx=\"11\" fill=\"white\" stroke=\"#e0e7ee\"/>")
                println(io,"<text class=\"rank\" text-anchor=\"middle\" x=\"$xm\" y=\"$(ym+4)\">$label</text>")
            end
        end
    end
    for node in eachindex(children)
        x,y = xs[node],ys[node]
        println(io,"<g id=\"node-$node\">")
        if children[node] == (0,0)
            p = d.positions[node]
            xleft = x-card_width/2
            println(io,"<rect x=\"$xleft\" y=\"$y\" width=\"$card_width\" height=\"$card_height\" rx=\"10\" fill=\"white\" stroke=\"#dce4ec\"/>")
            println(io,"<path d=\"M $(xleft+15) $(y+16) v $(card_height-32)\" stroke=\"$(d.colors[p])\" stroke-width=\"3\" stroke-linecap=\"round\"/>")
            metadata = "p$p"*(isnothing(d.dimensions) ? "" : " · d=$(d.dimensions[p])")*" · n$node"
            println(io,"<text x=\"$(xleft+28)\" y=\"$(y+21)\" font-size=\"10\" class=\"muted\">$metadata</text>")
            for (k,line) in enumerate(label_lines[p])
                println(io,"<text x=\"$(xleft+28)\" y=\"$(y+28+19k)\" font-size=\"13\" font-weight=\"650\">$(_escape(line))</text>")
            end
            for (k,line) in enumerate(detail_lines[p])
                println(io,"<text x=\"$(xleft+28)\" y=\"$(y+34+19length(label_lines[p])+16k)\" font-size=\"11\" class=\"muted\">$(_escape(line))</text>")
            end
        else
            isroot = node == d.root
            println(io,"<circle cx=\"$x\" cy=\"$y\" r=\"20\" fill=\"$(isroot ? "#263e56" : "#e9eff5")\" stroke=\"$(isroot ? "#263e56" : "#bccbd8")\"/>")
            println(io,"<text x=\"$x\" y=\"$(y+4)\" text-anchor=\"middle\" font-size=\"11\" class=\"$(isroot ? "root-text" : "muted")\">$(isroot ? "root" : "n$node")</text>")
            isroot && println(io,"<text x=\"$(x+29)\" y=\"$(y+4)\" font-size=\"11\" class=\"muted\">n$node</text>")
        end
        println(io,"</g>")
    end
    legend = isnothing(d.ranks) ? "Topology only" : "r: bond dimension"
    legend *= "   ·   p: physical axis   ·   n: node ID"
    isnothing(d.dimensions) || (legend *= "   ·   d: local dimension")
    println(io,"<text x=\"$margin\" y=\"$(height-30)\" font-size=\"11\" class=\"muted\">$legend</text></svg>")
    return String(take!(io))
end

"""Write tree_svg(subject; kwargs...) to a file and return its path."""
function write_tree_svg(filename::AbstractString,subject;kwargs...)
    svg = tree_svg(subject;kwargs...)
    open(filename,"w") do io
        write(io,svg)
    end
    return filename
end
