using Test, TTNPlots, TTNSolver

@testset "TTNPlots" begin
    children = [(0,0),(0,0),(0,0),(1,3),(4,2)]
    order = [3,1,2]
    labels = ["electron < ancilla", "site & mode", "a very long label that should wrap across several lines"]
    svg = tree_svg(children; leaf_order=order, leaf_labels=labels,
        dimensions=[4,3,2], ranks=[2,2,4,3,1], title="A & B <check>")
    @test startswith(svg,"<svg")
    @test occursin("A &amp; B &lt;check&gt;",svg)
    @test occursin("electron &lt; ancilla",svg)
    @test occursin("site &amp; mode",svg)
    @test length(collect(eachmatch(r"class=\"edge\"",svg))) == 4
    @test !occursin(r"\b(NaN|Inf)\b",svg)
    txt = tree_text(children; leaf_order=order,leaf_labels=labels,dimensions=[4,3,2],ranks=[2,2,4,3,1])
    @test occursin("n3 · p1 · d=4 · r=4 · electron < ancilla",txt)
    @test occursin("n1 · p2 · d=3 · r=2 · site & mode",txt)
    @test occursin("root n5",txt)
    @test occursin("└─",txt)
    wide = tree_svg([(0,0)];leaf_labels=[repeat("W",25)],title=repeat("W",40))
    @test !occursin(">"*repeat("W",25)*"</text>",wide)
    @test !occursin(">"*repeat("W",40)*"</text>",wide)
    @test sum(length(m.captures[1]) for m in eachmatch(r">(W+)</text>",wide)) == 65
    for topology in ([(0,0)], [(2,3),(0,0),(0,0)])
        result = tree_svg(topology; root=1)
        @test !occursin(r"\b(NaN|Inf)\b",result)
    end
    @test_throws ArgumentError tree_svg([(1,2),(0,0)])
    @test_throws ArgumentError tree_svg([(0,0),(0,0)])
    @test_throws ArgumentError tree_svg(children;leaf_order=[1,1,2])
    @test_throws DimensionMismatch tree_svg(children;leaf_labels=["too few"])
    @test_throws DimensionMismatch tree_svg(children;ranks=[1])
    @test_throws ArgumentError tree_svg(children;ranks=[0,1,1,1,1])
    @test_throws ArgumentError tree_svg(children;leaf_colors=["url(bad)","#abcdef","#abcdef"])
    tree = BinaryTree(children;leaf_order=order)
    state = product_state(tree, [ones(4),ones(3),ones(2)])
    before = dense(state)
    @test tree_svg(state) == tree_svg(tree;dimensions=[4,3,2],ranks=ones(Int,5))
    @test occursin("d=4",tree_text(state))
    @test dense(state) == before
    mktempdir() do dir
        path = joinpath(dir,"tree.svg")
        @test write_tree_svg(path,state) == path
        @test read(path,String) == tree_svg(state)
    end
end
