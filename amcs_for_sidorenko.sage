# amcs_for_sidorenko.sage

import sys
import os

# Determine the absolute path to the directory containing this script
# This helps in creating a robust path to the library
script_dir = os.path.abspath(".")

project_root_dir = os.getcwd()

# Path to the 'count-graph-homs' directory, assuming it's directly in project_root_dir
path_to_count_graph_homs = os.path.join(project_root_dir, 'count-graph-homs')

if path_to_count_graph_homs not in sys.path:
    sys.path.insert(0, path_to_count_graph_homs)

try:
    from standard_hom_count import GraphHomomorphismCounter
    print("Successfully imported GraphHomomorphismCounter from count-graph-homs.")
except ImportError as e:
    print(f"Error importing from count-graph-homs: {e}")
    print(f"Ensure the path '{path_to_count_graph_homs}' is correct and contains 'standard_hom_count.py'.")
    print("Current sys.path includes:")
    for p in sys.path:
        print(f"  - {p}")
    # You might want to raise the error or exit if the import fails critically
    # raise

from time import time
from random import choice, random # Added random for clarity, though often available in Sage
from sage.all import graphs, plot # Assuming SageMath environment for graphs and plot
# NMCS_trees and NMCS_connected_graphs are assumed to be defined elsewhere
# For example, from the original AMCS paper's codebase.
# If not, they would need to be implemented.
# Placeholder for NMCS_connected_graphs if not available:

# Helper functions from the original AMCS code
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

##
## Sidorenko Conjecture Specific Code
##

def count_homomorphisms(H, G):
    """
    Counts the number of homomorphisms from graph H to graph G
    using the external 'count-graph-homs' library.
    """
    if G.order() == 0:
        return 0
    if H.order() == 0: # Homomorphism from empty graph to any graph is 1 (empty map)
        return 1       # if G is non-empty, or 0 if G is empty and H is not.
                       # This library should handle edge cases.

    try:
        # Create the counter object for the specific H and G pair
        hom_counter = GraphHomomorphismCounter(H, G)
        num_homs = hom_counter.count_homomorphisms()
        return num_homs
    except NameError: # If GraphHomomorphismCounter is not found (library not installed/imported correctly)
        print("Error: GraphHomomorphismCounter not found. Make sure 'count-graph-homs' is installed and imported.")
        print("Falling back to Sage's default (potentially slow) method.")
        if G.order() < H.order() and H.is_connected() and H.order() > 0 : # Heuristic for simple cases
             return 0
        return len(list(G.homomorphisms(H))) # Fallback
    except Exception as e:
        print(f"Error using GraphHomomorphismCounter for H: {H.edges(labels=False)} in G: {G.edges(labels=False)}: {e}")
        print("Falling back to Sage's default (potentially slow) method.")
        if G.order() < H.order() and H.is_connected() and H.order() > 0:
             return 0
        return len(list(G.homomorphisms(H))) # Fallback

def sidorenko_score(G, H_fixed, e_H, v_H_order):
    """
    Calculates the score for Sidorenko's conjecture.
    Score = t_K2(G)^e(H) - t_H(G)
    A positive score indicates a counterexample.
    H_fixed: The fixed bipartite graph H.
    e_H: Number of edges in H_fixed.
    v_H_order: Number of vertices in H_fixed.
    """
    n_G = G.order()
    m_G = G.size() # Number of edges in G

    if n_G == 0: # Avoid division by zero
        return -float('inf') # Or some other indicator of an invalid graph for scoring

    # Calculate t_K2(G)
    # t_K2(G) = hom(K2, G) / n_G^2 = 2*m_G / n_G^2
    if n_G < 2 and m_G > 0: # Pathological case
        t_K2_G = 0
    elif n_G >=1 : # Handles n_G=1 case where m_G must be 0
        t_K2_G = (2 * m_G) / (n_G**2) if n_G > 0 else 0
    else: # n_G = 0
        t_K2_G = 0


    # Calculate t_H(G)
    # t_H(G) = hom(H_fixed, G) / n_G^v_H_order
    # This is the bottleneck
    num_homs_H_G = count_homomorphisms(H_fixed, G)
    
    if n_G < v_H_order and num_homs_H_G > 0:
        # This case should generally not happen if H has no isolated vertices
        # and G is smaller than H. Homomorphism count definition might vary.
        # Sage's homomorphism_count should be 0 if |V(G)| < |V(H)| and H is connected.
        # If H has isolated vertices, it could be non-zero.
        # For safety, if n_G is too small for a meaningful density, treat t_H_G as effectively zero
        # or handle as per specific definition if H can map to smaller G.
        # Given the typical context of Sidorenko, we usually assume G is large enough.
        # If n_G < v_H_order, the term n_G**v_H_order can be problematic if v_H_order is large.
        # However, if num_homs_H_G is 0 (as expected for connected H), then t_H_G is 0.
        pass # num_homs_H_G will likely be 0 from count_homomorphisms if G is too small

    t_H_G = num_homs_H_G / (n_G**v_H_order) if n_G > 0 and v_H_order > 0 else 0
    
    try:
        score = (t_K2_G**e_H) - t_H_G
    except OverflowError: # Can happen if t_K2_G is large and e_H is large
        print(f"Warning: OverflowError calculating score for G with {n_G} vertices, {m_G} edges. t_K2(G)={t_K2_G}, e(H)={e_H}")
        return -float('inf') # Penalize configurations leading to overflow
        
    #print(f"G(n={n_G}, m={m_G}): t_K2(G)={t_K2_G:.4f}, t_H(G)={t_H_G:.4f}, e(H)={e_H}, Score={score:.6f}")
    return score

##
## Modified AMCS Class/Function
##

# The AMCS function itself does not need much change, as it takes score_function as an argument.
# The main changes are in how it's called and the definition of the score function.
# We might want to adjust min_order based on H.

def AMCS(score_function, initial_graph=graphs.RandomGNP(10,0.3), max_depth=5, max_level=3, trees_only=False, H_for_min_order=None):
    '''The AMCS algorithm'''
    # NMCS is assumed to be NMCS_connected_graphs as per original code if trees_only is False.
    # If trees_only is True, it would use NMCS_trees (not provided here).
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
                
                # Original AMCS relabels vertices after deletion:
                # if removed_vertex_label is not None:
                #    temp_graph_for_pruning.relabel(lambda i: i-1 if i > removed_vertex_label else i)
                # Relabeling might not be standard or desired in SageMath if vertices are not integers 0..N-1
                # For now, we skip explicit relabeling here, assuming Sage handles vertex labels robustly.
                # Or, ensure vertices are always relabeled to be contiguous if NMCS expects that.
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
        #plot(best_graph_overall, vertex_labels=False, layout="spring").show()
        print("Edges of G:", best_graph_overall.edges(labels=False))
    else:
        print("\nNo counterexample found within the given limits.")
        print(f"Best score achieved: {float(best_score_overall):.6f}")
        print(f"Best graph G found: order = {best_graph_overall.order()}, size = {best_graph_overall.size()}")
        print("Edges of best G:", best_graph_overall.edges(labels=False))

    return best_graph_overall

def main():
    print("Attempting to find a counterexample to Sidorenko's Conjecture using AMCS.")
    
    # MAIN ATTEMPT DATA
    '''
    # 1. Define the fixed bipartite graph H
    # Example: H = K_{5,5} - C_10 (Möbius-Kantor graph variant)
    # K5,5 has 10 vertices. C10 also has 10 vertices.
    # K5,5: U = {0,1,2,3,4}, V = {5,6,7,8,9}
    H_fixed = graphs.CompleteBipartiteGraph(5,5) # Vertices 0-4 in one part, 5-9 in the other
    # Define C10 edges to remove: e.g. (0,5)-(5,1)-(1,6)-(6,2)-(2,7)-(7,3)-(3,8)-(8,4)-(4,9)-(9,0)
    # This is a bit tricky to map directly to K5,5 vertex labeling if not careful.
    # Let's use a known construction if available, or define carefully.
    # For K5,5: vertices are typically 0..4 and 5..9.
    # C10 edges: (0,5), (1,5), (1,6), (2,6), (2,7), (3,7), (3,8), (4,8), (4,9), (0,9)
    # It seems the above C10 description is incorrect for K5,5.
    # A C10 in K5,5: u0-v0-u1-v1-u2-v2-u3-v3-u4-v4-u0
    # Let U = {0,1,2,3,4} and V = {5,6,7,8,9}
    # Edges of C10: (0,5), (5,1), (1,6), (6,2), (2,7), (7,3), (3,8), (8,4), (4,9), (9,0) - This looks like a valid C10
    
    # Create K5,5
    H_k55 = graphs.CompleteBipartiteGraph(5,5) # Vertices 0..4 (part A) and 5..9 (part B)
    
    # Edges of C10 to remove. Assume parts are {0,1,2,3,4} and {5,6,7,8,9}
    # Path: 0-5-1-6-2-7-3-8-4-9-0
    c10_edges_to_remove = [
        (0,5), (1,5), (1,6), (2,6), (2,7), (3,7), (3,8), (4,8), (4,9), (0,9)
    ]
    # Correction for K5,5 \ C10 - the standard C10 removed is u0-v0-u1-v1-u2-v2-u3-v3-u4-v4-u0
    # Vertices U = {u0, u1, u2, u3, u4}, V = {v0, v1, v2, v3, v4}
    # Let's map Sage K(5,5) vertices: first 5 are U, next 5 are V.
    # So, u_i -> i, v_j -> 5+j
    # u0=0, u1=1, u2=2, u3=3, u4=4
    # v0=5, v1=6, v2=7, v3=8, v4=9
    # C10 edges: (u0,v0), (v0,u1), (u1,v1), (v1,u2), (u2,v2), (v2,u3), (u3,v3), (v3,u4), (u4,v4), (v4,u0)
    # (0,5), (5,1), (1,6), (6,2), (2,7), (7,3), (3,8), (8,4), (4,9), (9,0) - This is indeed a C10.
    # Wait, (5,1) is not an edge if 5 is in one part and 1 in another (it is).
    # The C10 must alternate parts. u0-v0-u1-v1...
    # The edges are (ui, vj). So (5,1) is valid if 5 is from V and 1 from U.
    # Sage K(m,n) creates vertices 0..m-1 and m..m+n-1.
    # So for K(5,5), vertices are 0..4 (first part) and 5..9 (second part).
    # The C10 edges listed: (0,5), (1,5) - NO, (1,5) is ok, but (5,1) is same edge.
    # The list c10_edges_to_remove was faulty.
    # C10 edges: (0,5), (1,6), (2,7), (3,8), (4,9) AND (0,6), (1,7), (2,8), (3,9), (4,5) ??? NO.
    # Let's use a simpler H known to be bipartite, or a clearly defined K5,5 - C10.
    # The Möbius-Kantor graph K5,5 - C10 has 15 edges. K5,5 has 25 edges. C10 has 10 edges.
    # A C10 in K5,5: (0,5)-(1,5)-(1,6)-(2,6)... this is wrong.
    # A C10 in K5,5: (0,5)-(5,1)-(1,6)-(6,2)-(2,7)-(7,3)-(3,8)-(8,4)-(4,9)-(9,0)
    # Edges are: (0,5), (1,5), (1,6), (2,6), (2,7), (3,7), (3,8), (4,8), (4,9), (0,9) this is also wrong.
    # Edges are: (u0,v0), (u1,v0), (u1,v1), (u2,v1), ... No.
    
    # H_fixed = graphs.CycleGraph(4) # Example: C4 (which is K2,2)
    # H_fixed = graphs.CompleteBipartiteGraph(2,3) # Example K2,3
    
    # Let's define K5,5 \ C10 carefully
    # V1 = [0,1,2,3,4], V2 = [5,6,7,8,9]
    H_fixed = graphs.CompleteBipartiteGraph(5,5) # Edges between V1 and V2
    # C10 edges to remove (example): (0,5), (1,6), (2,7), (3,8), (4,9), (0,6), (1,7), (2,8), (3,9), (4,5)
    # Edges of a C10 in K5,5: (v0,w0), (w0,v1), (v1,w1), (w1,v2), (v2,w2), (w2,v3), (v3,w3), (w3,v4), (v4,w4), (w4,v0)
    # Let U = {0,1,2,3,4}, V = {5,6,7,8,9}
    c10_edges_to_remove = [
        (0,5), (1,5), # This means vertex 5 is connected to 0 and 1.
        (1,6), (2,6), # Vertex 6 connected to 1 and 2
        (2,7), (3,7), # ...
        (3,8), (4,8),
        (4,9), (0,9)  # Vertex 9 connected to 4 and 0
    ] # This is a union of 5 C4s sharing edges, or a specific structure.
      # This definition of C10 removal is the "standard" one for the Mobius-Kantor graph which IS K5,5 \ C10.
      # The standard C10 removed is edges (u_i, v_i) and (u_i, v_{i+1}) (indices mod 5).
      # u_i are part 1 (0-4), v_i are part 2 (5-9).
      # (0,5), (0,6)
      # (1,6), (1,7)
      # (2,7), (2,8)
      # (3,8), (3,9)
      # (4,9), (4,5) --- this is the standard K5,5 \ C10
    
    H_fixed = graphs.CompleteBipartiteGraph(5,5)
    edges_to_remove_for_K55_minus_C10 = [
        (0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)
    ]
    H_fixed.delete_edges(edges_to_remove_for_K55_minus_C10)
    
    print(f"Chosen H: {H_fixed.name()} (or K5,5 - C10). Order={H_fixed.order()}, Size={H_fixed.size()}")
    if not H_fixed.is_bipartite():
        raise ValueError("H_fixed must be bipartite for Sidorenko's conjecture!")
    '''
    # Example: H_fixed = C_6 (a cycle with 6 vertices, which is bipartite)
    H_fixed = graphs.CycleGraph(6)

    e_H = H_fixed.size()
    v_H_order = H_fixed.order()

    # 2. Create a score function wrapper for AMCS
    # AMCS expects score_function(G)
    current_sidorenko_score_func = lambda G_prime: sidorenko_score(G_prime, H_fixed, e_H, v_H_order)

    # 3. Define initial graph G for AMCS
    # Should have at least v_H_order vertices ideally.
    # For K5,5-C10, v_H_order = 10.
    # Let's start with a random graph of slightly larger order.
    n_initial_G = 12 # Example starting size
    p_initial_G = 0.4 # Example edge probability
    initial_G_for_sidorenko = graphs.RandomGNP(n_initial_G, p_initial_G)
    # Ensure it's connected if NMCS_connected_graphs expects it
    # For simplicity, we'll rely on AMCS to build up connectivity if needed, or ensure RandomGNP is connected.
    # If RandomGNP can be disconnected:
    if not initial_G_for_sidorenko.is_connected() and initial_G_for_sidorenko.order() > 1:
        print("Warning: Initial G is not connected. Taking largest connected component.")
        initial_G_for_sidorenko = initial_G_for_sidorenko.connected_component_subgraph(initial_G_for_sidorenko.random_vertex())
        if initial_G_for_sidorenko.order() < v_H_order :
             initial_G_for_sidorenko = graphs.PathGraph(v_H_order) # Fallback

    print(f"Initial G for AMCS: order={initial_G_for_sidorenko.order()}, size={initial_G_for_sidorenko.size()}")

    # 4. Run AMCS
    # max_depth and max_level can be tuned. These are small for a quick test.
    # trees_only should be False for general graphs G.
    start_time = time()
    # Pass H_fixed to AMCS for it to determine min_order
    AMCS(current_sidorenko_score_func, 
         initial_graph=initial_G_for_sidorenko, 
         max_depth=3,  # Reduced for quick test; increase for real search
         max_level=2,  # Reduced for quick test
         trees_only=False,
         H_for_min_order=H_fixed)
    
    print("Search time: %s seconds" % (time() - start_time))
    print("\n--- Note on Homomorphism Counting ---")
    print("The 'count_homomorphisms' function can be extremely slow for larger H or G.")
    print("For serious attempts, this part would need significant optimization,")
    print("or the use of HPC resources, or validated approximation methods.")
    print("The current implementation is for demonstration with small graphs.")

if __name__ == "__main__":
    # This requires a SageMath environment to run.
    # Example: save as amcs_sidorenko.py and run "sage -python amcs_sidorenko.py"
    # Or run inside a SageMath notebook.
    main()