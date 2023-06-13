# Adaptive_MC_Search

This repository contains the official SageMath implementation of the adaptive Monte Carlo Search (AMCS) algorithm from the paper "An Asymmetric Contrastive Loss for Handling Imbalanced Datasets".

AMCS is a conjecture-refuting algorithm designed to search for graph counterexamples to graph theory conjectures. It is built on the nested Monte Carlo search (NMCS) algorithm, which was employed to refute spectral graph theory conjectures in a previous work.

To implement the algorithm, a score function s(G) needs to be extracted from the conjecture to be refuted. The score function is formulated in a way that a graph G is a counterexample to said conjecture if s(G) is positive. In essence, AMCS is aims to maximize s(G) to produce a counterexample having positive score.

Score functions for a total of ten conjectures are provided in this repository, ready to be used directly. All ten conjectures are able to be refuted within minutes using minimal computational resources.

Other than the score function, AMCS needs four other arguments: the initial graph (G), the maximum search depth (max_depth), the maximum search level (max_level), and whether or not the search is restricted to only the class of trees (trees_only). For simplicity, the initial graph is usually a tree of small order. Having a search level greater than 3 may slow down the algorithm substatially, so it is advised to raise the depth first. If trees_only is set to False, the algorithm will explore the entire space of connected graphs, which will make the search run a bit slower.
