from time import time
from random import choice, random
from sage.all import graphs, plot # Using SageMath environment for graphs and plot

# Slightly edited helper functions from the original AMCS code
def remove_randleaf(G):
    '''Removes a random leaf from G'''
    if not G: return None
    leaves = [v for v in G.vertices() if G.degree(v) == 1]
    if not leaves:
        # If no leaves and G is not empty, try to remove a degree-0 vertex if any
        deg_0 = [v for v in G.vertices() if G.degree(v) == 0]
        if deg_0:
            leaf = choice(deg_0)
            G.delete_vertex(leaf)
            return leaf # Technically not a leaf, but a vertex to remove
        return None # Cannot remove
    leaf = choice(leaves)
    G.delete_vertex(leaf)
    return leaf
    
def remove_subdiv(G):
    '''Removes a random subdivision from G'''
    if not G: return None
    deg_2 = [v for v in G.vertices() if G.degree(v) == 2]
    if not deg_2:
        return remove_randleaf(G) # Fallback to removing a leaf
    
    random_vertex = choice(deg_2)
    neighbors = G.neighbors(random_vertex)
    if len(neighbors) == 2: # Should always be true for degree 2 vertex
        # Only add edge if neighbors are not already connected to avoid multi-edges,
        # though SageMath graphs might handle this by default depending on type.
        # If G is a simple graph, this check is good.
        if not G.has_edge(neighbors[0], neighbors[1]):
            G.add_edge(neighbors[0], neighbors[1])
    G.delete_vertex(random_vertex)
    return random_vertex


def AMCS(score_function, initial_graph=graphs.RandomGNP(10,0.3), max_depth=5, max_level=3, trees_only=False, H_for_min_order=None, visualize_steps=False):
    '''The AMCS algorithm'''
    # We'll assume trees_only = False for Sidorenko's conjecture on general graphs G.
    if trees_only:
        # NMCS = NMCS_trees # This function needs to be defined if trees_only=True is used
        print("Warning: NMCS_trees not defined. Sidorenko typically involves general graphs G.")
        # For now, default to connected graphs if NMCS_trees is not available
        _NMCS_algo = NMCS_connected_graphs
    else:
        _NMCS_algo = NMCS_connected_graphs
        
    current_graph = initial_graph.copy()
    # Ensure graph is not empty if H_for_min_order is provided
    if not current_graph and H_for_min_order:
        current_graph = graphs.PathGraph(H_for_min_order.order()) # Or some other sensible default
    elif not current_graph:
        current_graph = graphs.PathGraph(2) # Default non-empty graph
        
    print("Initial graph G: order =", current_graph.order(), ", size =", current_graph.size())
    current_score_val = score_function(current_graph)
    print("Best score (initial):", float(current_score_val))

    depth = 0
    level = 1
    # min_order for G should ideally be at least the order of H
    min_order = H_for_min_order.order() if H_for_min_order else 2 # Default min_order if H not given for this
    
    # Ensure initial graph respects min_order if H is provided
    if H_for_min_order and initial_graph.order() < min_order:
        print(f"Warning: Initial graph order ({initial_graph.order()}) is less than H order ({min_order}). Adjusting initial graph or min_order might be needed.")
        # For simplicity, we'll proceed, but AMCS might prune it down further.
        # A better approach might be to ensure initial_graph.order() >= min_order.

    best_graph_overall = current_graph.copy()
    best_score_overall = current_score_val

    while current_score_val <= 0 and level <= max_level: # AMCS searches for s(G) > 0
        next_graph_candidate = current_graph.copy()
        
        # Pruning phase based on depth
        # Only prune if current graph is larger than min_order
        temp_graph_for_pruning = next_graph_candidate.copy()
        order_before_pruning = temp_graph_for_pruning.order()
        
        # Try to prune down, but not below min_order
        while temp_graph_for_pruning.order() > min_order:
            if random() < depth / (depth + 1): # Probability of attempting a prune
                if random() < 0.5:
                    removed_vertex_label = remove_randleaf(temp_graph_for_pruning)
                else:
                    removed_vertex_label = remove_subdiv(temp_graph_for_pruning)
                
                if removed_vertex_label is None: # Cannot prune further
                    break 
            else: # Did not attempt to prune this step
                break
        
        # If pruning resulted in a valid graph, use it as starting point for NMCS
        if temp_graph_for_pruning.order() >= min_order or (temp_graph_for_pruning.order() == 0 and min_order == 0) : # check if graph is still valid
             next_graph_candidate = temp_graph_for_pruning
        elif order_before_pruning >=min_order : # Pruning made it too small, revert to graph before this pruning phase
            next_graph_candidate = current_graph.copy()


        # Call to NMCS (Nested Monte Carlo Search)
        # _NMCS_algo is NMCS_connected_graphs or NMCS_trees
        # It should try to find a better graph starting from next_graph_candidate
        print(f"Starting NMCS for G (order {next_graph_candidate.order()}) at lvl {level}, dpt {depth}...")
        returned_graph_from_nmcs = _NMCS_algo(next_graph_candidate, depth, level, score_function)
        score_from_nmcs = score_function(returned_graph_from_nmcs)
        
        print(f"Best score (lvl {level}, dpt {depth}): current_best_overall={float(best_score_overall):.6f}, nmcs_returned_score={float(score_from_nmcs):.6f}")

        if score_from_nmcs > best_score_overall:
            best_graph_overall = returned_graph_from_nmcs.copy()
            best_score_overall = score_from_nmcs
            current_graph = returned_graph_from_nmcs.copy() # Update current base for next iteration
            current_score_val = score_from_nmcs
            depth = 0 # Reset depth on improvement
            #level = 1 # Original AMCS resets level too; consider if this is intended for progress
            print(f"Found new best graph with score: {float(best_score_overall):.6f}")
            if visualize_steps:
                plot(best_graph_overall, vertex_labels=False, layout="spring").show() # Optional: show new best
            if best_score_overall > 0: # Counterexample found
                break
        elif depth < max_depth:
            depth += 1
        else: # Max depth reached for this level without improvement
            depth = 0
            level += 1
            print(f"Increasing level to {level}")
            # current_graph remains the best_graph_overall found so far to start the new level
            current_graph = best_graph_overall.copy()
            current_score_val = best_score_overall


    if best_score_overall > 0:
        print("\nCounterexample found for Sidorenko's Conjecture!")
        print(f"Graph G: order = {best_graph_overall.order()}, size = {best_graph_overall.size()}")
        print(f"Score V(H,G) = t_K2(G)^e(H) - t_H(G) = {float(best_score_overall):.6f}")
        plot(best_graph_overall, vertex_labels=False, layout="spring").show()
        print("Edges of G:", best_graph_overall.edges(labels=False))
    else:
        print("\nNo counterexample found within the given limits.")
        print(f"Best score achieved: {float(best_score_overall):.6f}")
        print(f"Best graph G found: order = {best_graph_overall.order()}, size = {best_graph_overall.size()}")
        print("Edges of best G:", best_graph_overall.edges(labels=False))

    return best_graph_overall

def main():
    # Choose which conjecture to test
    # Options: "Sidorenko" and other conjectures
    CONJECTURE_TO_TEST = "Sidorenko" 
    # CONJECTURE_TO_TEST = "Conj1"
    
    print(f"--- Attempting to find a counterexample for {CONJECTURE_TO_TEST} using AMCS ---")
    
    target_score_function = None
    initial_G = None
    H_for_sidorenko = None # Only used if CONJECTURE_TO_TEST is "Sidorenko"
    run_trees_only = False # Default for most conjectures unless they are tree-specific

    if CONJECTURE_TO_TEST == "Sidorenko":
        # Define H_fixed for Sidorenko
        # H_fixed = graphs.CycleGraph(6) # A simpler H for quick testing
        H_fixed = graphs.CompleteBipartiteGraph(5,5)
        edges_to_remove_K55_C10 = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
        H_fixed.delete_edges(edges_to_remove_K55_C10)
        print(f"Using H = K5,5-C10 (Order={H_fixed.order()}, Size={H_fixed.size()}) for Sidorenko.")
        
        target_score_function = get_sidorenko_score_function(H_fixed)
        H_for_sidorenko = H_fixed # Pass H to AMCS for min_order logic
        
        # Initial G for Sidorenko
        n_init_G = H_fixed.order() + 2 if H_fixed.order() > 0 else 5 # e.g., 12 for K5,5-C10
        initial_G = graphs.RandomGNP(n_init_G, 0.5)
        if not initial_G.is_connected() and initial_G.order() > 1:
            lgst_comp = initial_G.connected_component_subgraph(initial_G.random_vertex() if initial_G.order() >0 else None)
            if lgst_comp and lgst_comp.order() >= H_fixed.order(): initial_G = lgst_comp
            elif H_fixed.order() > 0: initial_G = graphs.PathGraph(H_fixed.order())
            else: initial_G = Graph()
        run_trees_only = False

    elif CONJECTURE_TO_TEST == "Conj1":
        pass # Add stuff relevant to conjecture 1

    else:
        print(f"Error: Conjecture '{CONJECTURE_TO_TEST}' not recognized or configured in main().")
        return

    if target_score_function is None or initial_G is None:
        print("Error: Score function or initial graph not set up for the chosen conjecture.")
        return

    # AMCS Parameters
    MAX_DEPTH = 3  # Keep small for testing; increase for real search
    MAX_LEVEL = 1  # Keep small for testing
    VISUALIZE = False # Set to True to see plots of best graphs found

    start_time = time()
    AMCS(score_function=target_score_function, 
         initial_graph=initial_G, 
         max_depth=MAX_DEPTH,
         max_level=MAX_LEVEL,
         trees_only=run_trees_only,
         H_for_min_order=H_for_sidorenko, # Pass H only if it's Sidorenko, else None
         visualize_steps=VISUALIZE)
    
    print(f"\nTotal search time for {CONJECTURE_TO_TEST}: {time() - start_time:.4f} seconds")

    if CONJECTURE_TO_TEST == "Sidorenko":
        print("\n--- Note on Homomorphism Counting (Sidorenko) ---")
        print("The 'count_homomorphisms' function using 'GraphHomomorphismCounter' is more efficient")
        print("than naive methods but can still be slow for large H (large treewidth) or large G.")
        print("Results depend heavily on the chosen H and the search parameters.")

if __name__ == "__main__":
    main()