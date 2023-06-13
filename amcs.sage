from time import time

def remove_randleaf(G):
    '''Removes a random leaf from G'''
    leaves = [v for v in G.vertices() if G.degree(v) == 1]
    if leaves == []:
        return
    leaf = choice(leaves)
    G.delete_vertex(leaf)
    return leaf
    
def remove_subdiv(G):
    '''Removes a random subdivision from G'''
    deg_2 = [v for v in G.vertices() if G.degree(v) == 2]
    if deg_2 == []:
        return remove_randleaf(G)
    random_vertex = choice(deg_2)
    G.add_edge(G.neighbors(random_vertex))
    G.delete_vertex(random_vertex)
    return random_vertex

def AMCS(score_function, current_graph=graphs.RandomTree(5), max_depth=5, max_level=3, trees_only=False):
    '''The proposed AMCS algorithm'''
    if trees_only == True:
        NMCS = NMCS_trees
    else:
        NMCS = NMCS_connected_graphs
    print("Best score (initial):", float(score_function(current_graph)))
    plot(current_graph, vertex_labels=False).show()
    depth = 0
    level = 1
    min_order = current_graph.order()
    while score_function(current_graph) <= 0 and level <= max_level:
        next_graph = current_graph.copy()
        while next_graph.order() > min_order:
            if random() < depth / (depth + 1):
                if random() < 0.5:
                    vertex = remove_randleaf(next_graph)
                else:
                    vertex = remove_subdiv(next_graph)
                if vertex != None:
                    next_graph.relabel(lambda i: i-1 if i > vertex else i)
                else:
                    break
            else:
                break
        next_graph = NMCS(next_graph, depth, level, score_function)
        print(f"Best score (lvl {level}, dpt {depth}):", float(max(score_function(next_graph), score_function(current_graph))))
        if score_function(next_graph) > score_function(current_graph):
            current_graph = next_graph.copy()
            depth = 0
            level = 1
            plot(current_graph, vertex_labels=False).show()
        elif depth < max_depth:
            depth += 1
        else:
            depth = 0
            level += 1
    if score_function(current_graph) > 0:
        print("Counterexample found")
    else:
        print("No counterexample found")
    return current_graph

def main():
    start_time = time()
    AMCS(Conj1_score)
    print("Search time: %s seconds" %(time() - start_time))
    
if __name__ == "__main__":
    main()
