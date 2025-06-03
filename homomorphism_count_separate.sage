from standard_hom_count import GraphHomomorphismCounter

#Define H
H_K55_minus_C10 = graphs.CompleteBipartiteGraph(5,5)
edges_to_remove = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
H_K55_minus_C10.delete_edges(edges_to_remove)
H = H_K55_minus_C10

# Define G (the 12-vertex graph)
edges_G_test = [(0, 1), (0, 4), (0, 5), (0, 6), (0, 9), (0, 10), (0, 11), (1, 4), (1, 5), (1, 6), (1, 9), (1, 10), (2, 3), (2, 4), (2, 7), (2, 8), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 9), (3, 11), (4, 5), (4, 6), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 10), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (8, 9), (8, 11), (10, 11)]

G = Graph(edges_G_test)
vertices = list(range(12))
mapping = {v: i for i, v in enumerate(sorted(G.vertices()))}
# Relabel vertices to sorted order
G_relabel = G.relabel(mapping, inplace=False)
counter = GraphHomomorphismCounter(H, G_relabel)
count = counter.count_homomorphisms()
print(count)

# Check - Conjecture VIOLATED
t_H_G = count/(G.order()**H.order())
print(t_H_G)
t_K2_G = ((2 * G.size())/(G.order()*(G.order())))**H.size()
print(float(t_K2_G))
print(t_H_G >= t_K2_G) #Outputted False
