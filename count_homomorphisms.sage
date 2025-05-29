# (Assuming the setup code from above has been run)

# Define your first pair of graphs
H1 = graphs.PathGraph(3)  # Pattern graph 1 (P3: 0-1-2)
G1 = graphs.CycleGraph(4) # Target graph 1 (C4)

# Define your second pair of graphs
H2 = graphs.CompleteBipartiteGraph(5,5)
edges_to_remove_K55_C10 = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
H2.delete_edges(edges_to_remove_K55_C10) # Pattern graph 2 (C4)
# Let's use the 12-vertex graph G from your previous example as G2
edges_G_prev = [(0, 1), (0, 4), (0, 5), (0, 6), (0, 7), (0, 9), (1, 2), (1, 5), (1, 7), (1, 8), (1, 9), (1, 11), (2, 4), (2, 5), (2, 6), (2, 10), (2, 11), (3, 4), (3, 6), (3, 9), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 8), (5, 9), (6, 8), (6, 9), (7, 8), (7, 10), (7, 11), (8, 9), (8, 10), (10, 11)]
G2 = Graph(edges_G_prev) # Target graph 2

# --- Count homomorphisms for the first pair (H1, G1) ---
print(f"\nCounting homomorphisms from H1 (P3) to G1 (C4)...")
if 'GraphHomomorphismCounter' in globals() and not isinstance(GraphHomomorphismCounter(H1,G1), _PlaceholderGraphHomomorphismCounter if '_PlaceholderGraphHomomorphismCounter' in globals() else type(None) ): # Check if using real counter
    counter1 = GraphHomomorphismCounter(H1, G1)
    num_homs_H1_G1 = counter1.count_homomorphisms()
else: # Fallback if import failed
    print("Using Sage's default method for H1, G1 due to import issue.")
    num_homs_H1_G1 = len(list(G1.homomorphisms(H1)))
    
print(f"Number of homomorphisms from H1 to G1: {num_homs_H1_G1}")


# --- Count homomorphisms for the second pair (H2, G2) ---
print(f"\nCounting homomorphisms from H2 (C4) to G2 (Your 12-vertex graph)...")
if 'GraphHomomorphismCounter' in globals() and not isinstance(GraphHomomorphismCounter(H2,G2), _PlaceholderGraphHomomorphismCounter if '_PlaceholderGraphHomomorphismCounter' in globals() else type(None) ): # Check if using real counter
    counter2 = GraphHomomorphismCounter(H2, G2)
    num_homs_H2_G2 = counter2.count_homomorphisms()
else: # Fallback if import failed
    print("Using Sage's default method for H2, G2 due to import issue.")
    num_homs_H2_G2 = len(list(G2.homomorphisms(H2)))

print(f"Number of homomorphisms from H2 to G2: {num_homs_H2_G2}")

# Example of counting for H_sidorenko and G_sidorenko_previous
# H_sidorenko = graphs.CompleteBipartiteGraph(5,5)
# edges_to_remove_K55_C10 = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
# H_sidorenko.delete_edges(edges_to_remove_K55_C10)

# edges_G_sidorenko_prev = [
#     (0, 2), (0, 4), (0, 5), (0, 7), (0, 11), (1, 2), (1, 3), (1, 7), (1, 9), (1, 11), 
#     (2, 3), (2, 5), (2, 6), (2, 9), (3, 8), (3, 9), (3, 10), (4, 6), (4, 7), (4, 8), (4, 11), 
#     (5, 6), (6, 7), (6, 8), (6, 10), (6, 11), (7, 8), (7, 10), (7, 11), (8, 9), (8, 10), 
#     (9, 10), (9, 11), (10, 11)
# ]
# G_sidorenko_prev = Graph(edges_G_sidorenko_prev)

# print(f"\nCounting homomorphisms for H_sidorenko ({H_sidorenko.order()}v, {H_sidorenko.size()}e) to G_sidorenko_prev ({G_sidorenko_prev.order()}v, {G_sidorenko_prev.size()}e)...")
# if 'GraphHomomorphismCounter' in globals() and not isinstance(GraphHomomorphismCounter(H_sidorenko,G_sidorenko_prev), _PlaceholderGraphHomomorphismCounter if '_PlaceholderGraphHomomorphismCounter' in globals() else type(None) ):
#     counter3 = GraphHomomorphismCounter(H_sidorenko, G_sidorenko_prev)
#     num_homs_H3_G3 = counter3.count_homomorphisms()
# else:
#     print("Using Sage's default method for H_sidorenko, G_sidorenko_prev due to import issue.")
#     num_homs_H3_G3 = len(list(G_sidorenko_prev.homomorphisms(H_sidorenko)))
# print(f"Number of homomorphisms from H_sidorenko to G_sidorenko_prev: {num_homs_H3_G3}")

