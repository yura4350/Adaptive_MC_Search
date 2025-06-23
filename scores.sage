from numpy import argmax, abs

# Import for working with exact numbers
from sage.rings.rational_field import QQ

import sys
import os

sys.path.append('CountHom') # To gain access to homomorphism counting library

# The alias 'HomlibGraph' is crucial to avoid conflicts with Sage's native 'Graph'.
from homlib import Graph as HomlibGraph, countHom

def count_homomorphisms(H, G):
    """
    Counts homomorphisms by converting Sage graphs to homlib graphs via adjacency lists.
    """
    if G.order() == 0:
        return 0
    if H.order() == 0:
        return 1

    try:
        # --- FIX: Use the modern .to_dictionary() method instead of .adjacency_list() ---

        # 1. Get the adjacency dictionary from the Sage Graph objects.
        h_dict = H.to_dictionary()
        g_dict = G.to_dictionary()

        # 2. Build the adjacency list from the dictionary.
        #    This assumes vertices are labeled 0, 1, ..., n-1, which is true
        #    for the graphs used in the AMCS algorithm.
        #    Also, explicitly cast to standard Python ints for the C++ library.
        h_adj_list = [[int(v) for v in h_dict.get(i, [])] for i in range(H.order())]
        g_adj_list = [[int(v) for v in g_dict.get(i, [])] for i in range(G.order())]

        # 3. Create homlib.Graph objects from the now-correct adjacency lists.
        H_homlib = HomlibGraph(h_adj_list)
        G_homlib = HomlibGraph(g_adj_list)

        # 4. Call the countHom function from the library.
        return countHom(H_homlib, G_homlib)

    except Exception as e:
        print(f"An error occurred within the homlib library for H: {H.edges(labels=False)} in G: {G.edges(labels=False)}")
        print(f"Error details: {e}")
        print("Falling back to Sage's default (potentially slow) method.")
        sys.exit(0)
        

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
        t_K2_G_rational = QQ(2 * m_G) / QQ(n_G**2)
    except ZeroDivisionError:
        t_K2_G_rational = QQ(0)

    num_homs_H_G = count_homomorphisms(H_fixed, G)
    
    try:
        t_H_G_rational = QQ(num_homs_H_G) / QQ(n_G**v_H_order)
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
    '''Example of score function if had to be used for other conjectures'''
    n = G.order()
    return sqrt(n - 1) + 1 - max(G.spectrum()) - int(G.matching(value_only=True, use_edge_labels=False))
