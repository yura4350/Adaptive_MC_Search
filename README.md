# Adaptive Monte Carlo Search for Sidorenko's Conjecture

## Overview

This project provides a SageMath implementation of an **Adaptive Monte Carlo Search (AMCS)** algorithm to search for counterexamples to the **Sidorenko Conjecture**. Unlike approaches that analyze continuous graphons, this repository focuses on finding discrete graphs `G` that violate the conjecture for a fixed bipartite graph `H`.

The search algorithm explores the vast space of possible graphs by intelligently adding, removing, and modifying vertices and edges. The project's main goal is to test well-known difficult cases, such as `K_{5,5} - C_{10}`, to find a concrete counterexample. The AMCS implementation in this project was adapted from the framework in the [valentinovito/Adaptive_MC_Search](https://github.com/valentinovito/Adaptive_MC_Search) repository.

---

## The Sidorenko Conjecture (Discrete Graph Version)

Let `H` be a bipartite graph with `e(H)` edges and `v(H)` vertices. Let `G` be any graph. The homomorphism density `t(H, G)` is the probability that a random mapping from the vertices of `H` to the vertices of `G` is a homomorphism.

$$t(H, G) = \frac{\text{hom}(H, G)}{|V(G)|^{|V(H)|}}$$

where `hom(H, G)` is the number of homomorphisms from `H` to `G`.

The Sidorenko Conjecture states that for any bipartite graph `H` and any graph `G`:

$$t(H, G) \ge t(K_2, G)^{e(H)}$$

Here, `t(K_2, G)` is the edge density of `G`. The objective of this project is to find a pair `(H, G)` for which the score `t(K_2, G)^{e(H)} - t(H, G)` is positive.

---

## Methodology: Adaptive Monte Carlo Search on Graphs

The core of this project is the **AMCS algorithm**, which explores the search space of graphs `G` to find one that maximizes the Sidorenko score.

1.  **Graph Mutations:** The algorithm navigates the space of graphs by applying small, random modifications to the current best graph `G`. These mutations include:
    * Adding or removing a leaf (a vertex of degree 1).
    * Subdividing an edge.
    * Adding or removing an edge between existing vertices.

2.  **Adaptive Search Strategy:** The AMCS algorithm balances exploration and exploitation:
    * **Local Search (NMCS):** A Nested Monte Carlo Search (`nmcs.sage`) performs a "growth" phase by applying a sequence of mutations to explore the neighborhood of the current graph.
    * **Adaptive Heuristic (`amcs.sage`):** The main AMCS loop guides the search. If NMCS finds a better graph, the algorithm moves to this new point. If it repeatedly fails to improve, it increases the search "level," which intensifies the local search, helping it to escape local optima.

3.  **Efficient Homomorphism Counting:** Calculating homomorphism density is computationally expensive. This project uses the `count-graph-homs` library (included as a git submodule) for highly optimized, exact homomorphism counting, which is critical for performance.

---

## Main Case Studies

The search is primarily focused on bipartite graphs `H` that are known to be difficult cases for the conjecture:

* **`H = K_{5,5} - C_{10}`**: The graph formed by removing a 10-cycle from the complete bipartite graph K_5,5.
* Other case studies to be added

---

## Project Structure

This document outlines the structure of the project, detailing the purpose of each file and directory.

### Files

* **`amcs_for_sidorenko.sage`**: The main executable script. It configures the search parameters (the fixed graph `H`, `MAX_DEPTH`, `MAX_LEVEL`) and launches the AMCS algorithm.
* **`nmcs.sage`**: Implements the Nested Monte Carlo Search algorithm. This acts as the "local exploration" or "growth" phase of the search, responsible for exploring the neighborhood of a given graph.
* **`scores.sage`**: Defines the objective functions for the search. It contains the core logic for calculating the Sidorenko score as well as scores for other graph theory conjectures.
* **`homomorphism_count_separate.sage`**: A standalone utility script used to independently verify potential counterexamples found by the main algorithm.
* **`README.md`**: This documentation file.

### Directories

* **`count-graph-homs/`**: A git submodule containing an external, high-performance library for counting graph homomorphisms. This is crucial for the performance of `scores.sage`.

---

## How to Run the Experiments

### Prerequisites
* **SageMath:** This project is written in the SageMath language. You must have a working installation of Sage.
* **Git:** Required to clone the repository and its submodule.

### Steps
1.  **Clone the Repository:**
    ```bash
    git clone --recurse-submodules [https://github.com/yura4350/Adaptive_MC_Search.git](https://github.com/yura4350/Adaptive_MC_Search.git)
    cd Adaptive_MC_Search
    ```
    If you have already cloned without the submodule, run:
    ```bash
    git submodule init
    git submodule update
    ```

2.  **Configure the Search:**
    * Open `amcs_for_sidorenko.sage`.
    * Inside the `main()` function, choose which `H_fixed` you want to test (e.g., `K_{4,4} - M` is enabled by default). You can comment/uncomment blocks to switch to other graphs like `K_{5,5} - C_{10}`.
    * Adjust `MAX_DEPTH` and `MAX_LEVEL` to control the duration and intensity of the search.

3.  **Launch the Script:**
    Run the main script using Sage.
    ```bash
    sage
    load('scores.sage')
    load('nmcs.sage')
    load('amcs_for_sidorenko.sage')
    ```

4.  **Analyze the Output:**
    * The script will print the best score found at each step of the search.
    * The score represents `t(K_2, G)^e(H) - t(H, G)`.
    * If a **positive score** is found, the script will announce "Counterexample found," print its edges, and show a plot of the graph `G`. This graph is a valid counterexample to the Sidorenko Conjecture for the chosen `H`.
