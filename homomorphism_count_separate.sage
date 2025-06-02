from standard_hom_count import GraphHomomorphismCounter

#Define H
H_K55_minus_C10 = graphs.CompleteBipartiteGraph(5,5)
edges_to_remove = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
H_K55_minus_C10.delete_edges(edges_to_remove)
H = H_K55_minus_C10

# Define G (the 12-vertex graph)
edges_G_test = [(0, 2), (0, 8), (0, 9), (0, 10), (0, 11), (1, 5), (1, 7), (1, 9), (1, 11), (2, 3), (2, 7), (2, 8), (2, 11), (3, 6), (3, 7), (3, 8), (3, 10), (4, 5), (4, 6), (4, 8), (4, 11), (5, 6), (5, 8), (5, 10), (6, 10), (7, 8), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11)]

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
