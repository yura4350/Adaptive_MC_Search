from time import time
import sys

'''
This algorithm is essentially the same as the amcs algorithm, except for the adaptation of the main class for
the Sidorenko conjecture. It will be also more convenient to adapt to other conjectures now, as it allows for
more flexibility in the amcs function and not the scoring function, which seems as a more intuitive place to be.
'''

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

def AMCS(score_function, initial_graph=graphs.RandomTree(5), max_depth=5, max_level=3, trees_only=False):
    '''The AMCS algorithm'''
    if trees_only == True:
        NMCS = NMCS_trees
    else:
        NMCS = NMCS_connected_graphs
    print("Best score (initial):", float(score_function(initial_graph)))

    """ Do not need initial graph plot """
    #plot(initial_graph, vertex_labels=False, layout="spring").show()
    depth = 0
    level = 1
    min_order = initial_graph.order()
    current_graph = initial_graph.copy()
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

            """ Do not need current graph plot """
            #plot(current_graph, vertex_labels=False, layout="spring").show()
        elif depth < max_depth:
            depth += 1
        else:
            depth = 0
            level += 1
    if score_function(current_graph) > 0:
        print("Counterexample found")
        plot(current_graph, vertex_labels=False, layout="spring").show() # printing current graph
        print("Edges:", current_graph.edges(labels=False))

    else:
        print("No counterexample found")
    return current_graph

def main():

    # Set conjecture to test    
    CONJECTURE_TO_TEST = "Sidorenko"

    target_score_function = None
    initial_G = None
    H_for_sidorenko = None # Only used if CONJECTURE_TO_TEST is "Sidorenko"
    run_trees_only = False # Default for most conjectures unless they are tree-specific

    # AMCS Parameters
    MAX_DEPTH = 3  # Keep small for testing; increase for real search
    MAX_LEVEL = 1  # Keep small for testing
    VISUALIZE = False # Set to True to see plots of best graphs found

    if CONJECTURE_TO_TEST == "Sidorenko":

        # Define H_fixed for Sidorenko
        
        # Famous unproven case - K5,5 - 10
        H_fixed = graphs.CompleteBipartiteGraph(5,5)
        edges_to_remove_K55_C10 = [(0,5), (0,6), (1,6), (1,7), (2,7), (2,8), (3,8), (3,9), (4,9), (4,5)]
        H_fixed.delete_edges(edges_to_remove_K55_C10)
        print(f"Using H = K5,5-C10 (Order={H_fixed.order()}, Size={H_fixed.size()}) for Sidorenko.")
        
        # Simple case for check
        # H_fixed = graphs.CycleGraph(6)

        # K_4,4 - M - also unresolved for Sidorenko conjecture
        # H_fixed = graphs.CompleteBipartiteGraph(4, 4)
        # edges_to_remove_K44_M = [(0, 4), (1, 5), (2, 6), (3, 7)]
        # H_fixed.delete_edges(edges_to_remove_K44_M)
        # print(f"Using H = K4,4 - M (Order={H_fixed.order()}, Size={H_fixed.size()}) for Sidorenko.")

        # Define score function
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

        try:
            start_time = time() 
            AMCS(score_function=target_score_function, initial_graph=initial_G, max_depth=MAX_DEPTH, max_level=MAX_LEVEL, trees_only=run_trees_only)
            print(f"\nTotal search time for {CONJECTURE_TO_TEST}: {time() - start_time:.4f} seconds")

        except KeyboardInterrupt:
            # Executed when user presses Ctrl+C
            print("\n\n--- Search terminated by user ---")
            try:
                # This provides a clean exit from the script
                sys.exit(0)
            except SystemExit:
                # In some interactive environments (like a Jupyter/Sage notebook),
                # sys.exit() raises this exception, so we can just pass.
                pass
    
    elif CONJECTURE_TO_TEST == "Conj1":
        try:
            start_time = time()
            AMCS(Conj1_score)
            print("Search time: %s seconds" %(time() - start_time))
        except KeyboardInterrupt:
            print("\n\n--- Search terminated by user ---")
            sys.exit(0)
  
if __name__ == "__main__":
    main()
