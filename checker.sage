# SageMath script to verify Sidorenko's Conjecture for H = K_5,5 and a specific G

import sys
import os
from sage.all import Graph, graphs, RR # Ensure Graph, graphs, and RR (Real Field) are imported

# --- Setup for count-graph-homs library ---
# This path manipulation allows importing count-graph-homs if it's
# placed in a 'count-graph-homs' subdirectory relative to the current working directory.
_GHC_IMPORTED_SUCCESSFULLY = False
_PlaceholderGraphHomomorphismCounter = None # Define for isinstance check later

try:
    project_root_dir = os.getcwd()
    path_to_count_graph_homs = os.path.join(project_root_dir, 'count-graph-homs')

    if path_to_count_graph_homs not in sys.path:
        sys.path.insert(0, path_to_count_graph_homs)
    
    from standard_hom_count import GraphHomomorphismCounter
    _GHC_IMPORTED_SUCCESSFULLY = True
    print("Successfully imported GraphHomomorphismCounter from count-graph-homs.")

except ImportError as e:
    print(f"Warning: Could not import GraphHomomorphismCounter from count-graph-homs: {e}")
    print(f"Ensure the path '{path_to_count_graph_homs}' is correct and contains 'standard_hom_count.py'.")
    print("Will fallback to Sage's default (potentially very slow) homomorphism counting.")
    # Define a placeholder for isinstance check if the real one fails to import
    class _PlaceholderGraphHomomorphismCounter_Class: # Different name to avoid conflict if GHC fails
        def __init__(self, H, G): 
            self.H_pattern = H
            self.G_target = G
            print(f"Warning: Using SAGE'S SLOW DEFAULT len(list(G.homomorphisms(H))) for H({self.H_pattern.order()},{self.H_pattern.size()}) to G({self.G_target.order()},{self.G_target.size()})")
        def count_homomorphisms(self):
            if self.H_pattern.order() > 0 and self.G_target.order() < self.H_pattern.order() and self.H_pattern.is_connected(): 
                return 0
            try:
                return len(list(self.G_target.homomorphisms(self.H_pattern)))
            except Exception as e_sage_fallback:
                print(f"Sage default homomorphism count failed: {e_sage_fallback}")
                return 0
    _PlaceholderGraphHomomorphismCounter = _PlaceholderGraphHomomorphismCounter_Class


def count_homomorphisms_wrapper(H_pattern, G_target):
    """
    Counts homomorphisms from H_pattern to G_target.
    Uses GraphHomomorphismCounter if available, otherwise Sage's default.
    """
    if not H_pattern or not G_target or G_target.order() == 0:
        if H_pattern and H_pattern.order() == 0 and G_target.order() > 0: return 1 # Hom from empty graph
        return 0

    if _GHC_IMPORTED_SUCCESSFULLY:
        try:
            counter = GraphHomomorphismCounter(H_pattern, G_target)
            num_homs = counter.count_homomorphisms()
            return num_homs
        except Exception as e_ghc:
            print(f"Error using GraphHomomorphismCounter: {e_ghc}")
            print("Falling back to Sage's default method for this pair.")
            # Fall through
    
    # Fallback or if GHC was not imported/failed
    if _PlaceholderGraphHomomorphismCounter: # Check if placeholder was defined
         counter_fallback = _PlaceholderGraphHomomorphismCounter(H_pattern, G_target)
         return counter_fallback.count_homomorphisms()
    else: # Should not happen if try-except for import is set up
        print("Critical error: No homomorphism counter available.")
        return 0


def verify_sidorenko_for_pair(H_test, G_test):
    """
    Verifies Sidorenko's conjecture for a given bipartite H_test and graph G_test.
    Prints the components and the result.
    """
    print(f"\n--- Verifying Sidorenko's Conjecture ---")
    print(f"For H: {H_test.graph6_string()} (Order={H_test.order()}, Size={H_test.size()})")
    print(f"For G: {G_test.graph6_string()} (Order={G_test.order()}, Size={G_test.size()})")

    if not H_test.is_bipartite():
        print("Error: Graph H_test must be bipartite for Sidorenko's conjecture.")
        return

    v_H = RR(H_test.order()) # Use RR for RealField to ensure float division later
    e_H = RR(H_test.size())
    v_G = RR(G_test.order())
    e_G = RR(G_test.size())

    if v_G == 0:
        print("Graph G has 0 vertices. Cannot compute densities.")
        return
    if v_H == 0: # Sidorenko typically for H with edges
        print("Graph H has 0 vertices. Trivial case.")
        # t_H(G) = 1 if v_G > 0, t_K2(G)^0 = 1. So 1 >= 1 holds.
        if v_G > 0: print("Conjecture holds trivially (1 >= 1).")
        return


    # Calculate t_K2(G)
    t_K2_G = (2 * e_G) / (v_G**2) if v_G > 0 else RR(0)
    print(f"t_K2(G) = (2 * {e_G}) / ({v_G}^2) = {float(t_K2_G):.8f}")

    # Calculate RHS: t_K2(G)^e(H)
    if t_K2_G == 0:
        rhs_val = RR(1.0) if e_H == 0 else RR(0.0)
    elif t_K2_G > 0:
        try:
            rhs_val = t_K2_G**e_H
        except OverflowError:
            print(f"OverflowError calculating t_K2(G)^e(H). t_K2(G)={t_K2_G}, e(H)={e_H}")
            rhs_val = RR(float('inf')) # Or some indicator of problem
    else: # t_K2_G < 0 not expected for simple graphs
        rhs_val = RR(0.0) # Or handle as error
        
    print(f"RHS = t_K2(G)^e(H) = ({float(t_K2_G):.8f})^{e_H} = {float(rhs_val):.8e}")


    # Calculate hom(H,G)
    print("Calculating hom(H,G)... (This might take a while)")
    num_homs_H_G = RR(count_homomorphisms_wrapper(H_test, G_test))
    print(f"hom(H,G) = {num_homs_H_G}")

    # Calculate LHS: t_H(G)
    if v_G == 0 or v_H == 0 : # Should be caught earlier for v_H
         lhs_val = RR(0)
    else:
         denominator_tH = v_G**v_H
         if denominator_tH == 0: # Should not happen if v_G > 0
             lhs_val = RR(float('inf')) if num_homs_H_G > 0 else RR(0)
         else:
             lhs_val = num_homs_H_G / denominator_tH

    print(f"LHS = t_H(G) = {num_homs_H_G} / ({v_G}^{v_H}) = {float(lhs_val):.8e}")

    # Verify
    holds = (lhs_val >= rhs_val)
    print(f"\nVerification: t_H(G) >= t_K2(G)^e(H) ?")
    print(f"{float(lhs_val):.8e} >= {float(rhs_val):.8e}  =>  {holds}")

    if holds:
        print("Sidorenko's conjecture HOLDS for this pair of H and G.")
    else:
        print("Sidorenko's conjecture is VIOLATED for this pair of H and G (potential counterexample).")
    print("--- End of Verification ---")


# --- Define your graphs ---

# Define H_fixed = K_5,5
H_sidorenko_test = graphs.CompleteBipartiteGraph(5,5)

# Define G (the 12-vertex graph from your previous example)
edges_G_test = [
    (0, 1), (0, 6), (0, 8), (0, 10), (0, 11), (1, 2), (1, 7), (1, 8), (1, 9), (1, 10), 
    (2, 4), (2, 5), (2, 6), (2, 7), (2, 10), (2, 11), (3, 4), (3, 5), (3, 8), (3, 11), 
    (4, 6), (4, 9), (4, 10), (5, 6), (5, 7), (5, 8), (5, 10), (6, 8), (6, 9), 
    (7, 8), (7, 9), (8, 10), (8, 11), (9, 11), (10, 11)
]
G_sidorenko_test = Graph(edges_G_test)

# --- Perform the verification ---
verify_sidorenko_for_pair(H_sidorenko_test, G_sidorenko_test)

# You can also test with H = K5,5 - C10 if you want, by redefining H_sidorenko_test:
# H_K55_minus_C10 = graphs.CompleteBipartiteGraph(5,5)
# edges_to_remove = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
# H_K55_minus_C10.delete_edges(edges_to_remove)
# print("\n\n--- Verifying for H = K5,5 - C10 ---")
# verify_sidorenko_for_pair(H_K55_minus_C10, G_sidorenko_test)