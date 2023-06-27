def add_randleaf(G):
    '''Adds a random leaf to G'''
    n = G.order()
    random_vertex = choice(G.vertices())
    G.add_edge(random_vertex, n)
    
def add_leaf(G, v):
    '''Adds a leaf adjacent to a vertex v of G'''
    n = G.order()
    G.add_edge(v, n)
    
def add_randsubdiv(G):
    '''Subdivide a random edge of G'''
    random_edge = choice(G.edges())
    G.subdivide_edge(random_edge, 1)
    
def NMCS_trees(current_graph, depth, level, score_function, is_parent=True):
    '''The NMCS algorithm'''
    best_graph = current_graph
    best_score = score_function(current_graph)
    if level == 0:
        next_graph = current_graph.copy()
        for i in range(depth):
            if random() < 0.5:
                add_randleaf(next_graph)
            else:
                add_randsubdiv(next_graph)
        if score_function(next_graph) > best_score:
            best_graph = next_graph.copy()
    else:
        for x in current_graph.vertices() + current_graph.edges():
            next_graph = current_graph.copy()
            if type(x) == tuple:
                next_graph.subdivide_edge(x, 1)
            else:
                add_leaf(next_graph, x)
            next_graph = NMCS_trees(next_graph, depth, level-1, score_function, False)
            if score_function(next_graph) > best_score:
                best_graph = next_graph.copy()
                best_score = score_function(next_graph)
                if current_graph.order() > 20 and is_parent == True:
                    break
    return best_graph

def NMCS_connected_graphs(current_graph, depth, level, score_function, is_parent=True):
    '''The NMCS algorithm'''
    best_graph = current_graph
    best_score = score_function(current_graph)
    if level == 0:
        next_graph = current_graph.copy()
        for i in range(depth):
            random_number = random()
            if random_number < 0.5 and len(next_graph.complement().edges()) != 0:
                random_edge = choice(next_graph.complement().edges())
                next_graph.add_edge(random_edge)
            elif random_number < 0.8:
                add_randleaf(next_graph)
            else:
                add_randsubdiv(next_graph)
        if score_function(next_graph) > best_score:
            best_graph = next_graph.copy()
    else:
        for x in current_graph.vertices() + current_graph.edges() + current_graph.complement().edges():
            next_graph = current_graph.copy()
            if x in current_graph.vertices():
                add_leaf(next_graph, x)
            elif x in current_graph.edges():
                next_graph.subdivide_edge(x, 1)
            else:
                next_graph.add_edge(x)
            next_graph = NMCS_connected_graphs(next_graph, depth, level-1, score_function, False)
            if score_function(next_graph) > best_score:
                best_graph = next_graph.copy()
                best_score = score_function(next_graph)
                if current_graph.order() > 20 and is_parent == True:
                    break
    return best_graph
