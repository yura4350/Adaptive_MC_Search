def proximity(G):
    '''Returns the proximity of the graph G'''
    n = G.order()
    return min([sum([G.distance(v, w) for w in G.vertices()]) for v in G.vertices()]) / (n - 1)
    
def dist_eigenvalue(G, n):
    '''Returns the n-th largest eigenvalue of the distance matrix of G'''
    dist_spectrum = G.distance_matrix().eigenvalues()
    dist_spectrum.sort(reverse=1)
    return dist_spectrum[n - 1]

def mod_zagreb_2(G):
    '''Returns the modified second Zagreb index of G'''
    return sum([1/(G.degree(u) * G.degree(v)) for u, v, x in G.edges()])

def p_A(G):
    '''Returns the peak location of the non-zero coefficients of CPA(G)'''
    n = G.order()
    char_poly = G.adjacency_matrix().characteristic_polynomial()
    coefs = companion_matrix(char_poly, format='bottom')[n - 1].list() + [1]
    nonzero_coefs = [abs(i) for i in coefs if i != 0]
    return argmax(nonzero_coefs) + 1

def p_D(G):
    '''Returns the peak location of the normalized coefficients of G'''
    n = G.order()
    char_poly = G.distance_matrix().characteristic_polynomial()
    abs_coefs = abs(companion_matrix(char_poly, format='bottom')[n - 1].list() + [1])
    norm_coefs = abs_coefs * [2^(k+2-n) for k in range(n + 1)] 
    return argmax(norm_coefs)

def m(G):
    '''Returns the number of non-zero coefficients of CPA(G)'''
    n = G.order()
    char_poly = G.adjacency_matrix().characteristic_polynomial()
    coefs = companion_matrix(char_poly, format='bottom')[n - 1].list() + [1]
    num_nonzero_coefs = sum(i != 0 for i in coefs)
    return num_nonzero_coefs

def harmonic_index(G):
    '''Returns the harmonic index of G'''
    return sum([2/(G.degree(u) + G.degree(v)) for u, v, x in G.edges()])

def randic_index(G):
    '''Returns the Randic index of G'''
    return sum([1/sqrt(G.degree(u)*G.degree(v)) for u, v, x in G.edges()])

def connectivity(G):
    '''Returns the algebraic connectivity of G'''
    return sorted(G.kirchhoff_matrix().eigenvalues())[1]
    
def Conj1_score(G):
    '''Score function for Conjecture 1'''
    n = G.order()
    return sqrt(n - 1) + 1 - max(G.spectrum()) - int(G.matching(value_only=True, use_edge_labels=False))

def Conj2_score(G):
    '''Score function for Conjecture 2'''
    return -proximity(G) - dist_eigenvalue(G, floor(2 * G.diameter() / 3))

def Conj3_score(G):
    '''Score function for Conjecture 3'''
    n = G.order()
    return abs(p_A(G) / m(G) - (1 - p_D(G) / n)) - 0.28
    
def Conj4_score(G):
    '''Score function for Conjecture 4'''
    return sorted(G.spectrum())[-2] - harmonic_index(G)

def Conj5_score(G):
    '''Score function for Conjecture 5'''
    n = G.order()
    return mod_zagreb_2(G) - (n + 1) / 4

def Conj6_score(G):
    '''Score function for Conjecture 6'''
    n = G.order()
    gamma = G.dominating_set(value_only=True)
    return (1 - gamma)/(2 * n - 2 * gamma) + (gamma + 1)/2 - mod_zagreb_2(G)

def Conj7_score(G):
    '''Score function for Conjecture 7'''
    n = G.order()
    return max(G.spectrum()) * proximity(G) - n + 1

def Conj8_score(G):
    '''Score function for Conjecture 8'''
    n = G.order()
    if n % 2 == 0:
        return 0.5 * (n ** 2 / (n - 1)) * (1 - cos(pi / n)) - connectivity(G) * proximity(G)
    if n % 2 == 1:
        return 0.5 * (n + 1) * (1 - cos(pi / n)) - connectivity(G) * proximity(G)

def Conj9_score(G):
    '''Score function for Conjecture 9'''
    n = G.order()
    return sqrt(n - 1) - n + 1 - max(G.spectrum()) + len(G.independent_set())

def Conj10_score(G):
    '''Score function for Conjecture 10'''
    n = G.order()
    return randic_index(G) + len(G.independent_set()) - n + 1 - sqrt(n - 1)
