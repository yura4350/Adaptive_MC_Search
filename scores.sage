from numpy import argmax, abs

# Import for working with exact numbers
from sage.rings.rational_field import QQ

import sys
import os

# Determine the absolute path to the directory containing this script
# This helps in creating a robust path to the library
script_dir = os.path.abspath(".")
project_root_dir = os.getcwd()

# Path to the 'count-graph-homs' directory
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

def calculate_sidorenko_score(G, H_fixed, e_H, v_H_order):
    """
    Calculates the score for Sidorenko's conjecture using EXACT rational arithmetic
    to avoid floating-point precision errors.
    """
    n_G = G.order()
    m_G = G.size()

    if n_G == 0:
        return -float('inf')

    try:
        t_K2_G_rational = QQ(2 * m_G) / (n_G**2)
    except ZeroDivisionError:
        t_K2_G_rational = QQ(0)

    num_homs_H_G = count_homomorphisms(H_fixed, G)
    
    try:
        t_H_G_rational = QQ(num_homs_H_G) / (n_G**v_H_order)
    except ZeroDivisionError:
        t_H_G_rational = QQ(0)

    score_as_rational = (t_K2_G_rational**e_H) - t_H_G_rational
    
    return score_as_rational
    
def get_sidorenko_score_function(H_target_graph):
    """
    This is the 'unique score-calculating function' setup for Sidorenko.
    It takes the fixed bipartite graph H, pre-calculates its properties,
    and returns a score function suitable for AMCS (which takes only G).
    """
    if not H_target_graph.is_bipartite():
        raise ValueError("H_target_graph must be bipartite for Sidorenko's conjecture!")
    
    e_H = H_target_graph.size()
    v_H_order = H_target_graph.order()
    
    print(f"Sidorenko score function configured for H: order={v_H_order}, size={e_H}")
    # The returned lambda captures H_target_graph, e_H, v_H_order from this scope
    return lambda G_prime: calculate_sidorenko_score(G_prime, H_target_graph, e_H, v_H_order)

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
