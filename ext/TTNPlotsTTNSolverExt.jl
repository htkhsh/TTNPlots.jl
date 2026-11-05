module TTNPlotsTTNSolverExt

using TTNPlots, TTNSolver

for render in (:tree_svg,:tree_text)
    @eval begin
        function TTNPlots.$render(tree::BinaryTree;kwargs...)
            return TTNPlots.$render(tree.children;root=tree.root,leaf_order=tree.leaf_order,kwargs...)
        end
        function TTNPlots.$render(state::TTNTensor;
                                  dimensions=leafdims(state),ranks=tree_ranks(state),kwargs...)
            return TTNPlots.$render(state.tree;dimensions,ranks,kwargs...)
        end
    end
end

end
