import sys
import os
from sage.all import graphs # For creating graph objects

# Assuming 'count-graph-homs' is in the same directory as your script/notebook CWD
# Adjust this path if it's located elsewhere (e.g., as a submodule in 'external/')
project_root_dir = os.getcwd()
path_to_count_graph_homs = os.path.join(project_root_dir, 'count-graph-homs')

if path_to_count_graph_homs not in sys.path:
    sys.path.insert(0, path_to_count_graph_homs)

try:
    from standard_hom_count import GraphHomomorphismCounter
    print("Successfully imported GraphHomomorphismCounter.")
except ImportError as e:
    print(f"Error importing GraphHomomorphismCounter: {e}")
    print("Please ensure 'count-graph-homs' is correctly placed and sys.path is updated.")
    # Define a placeholder if you want the script to continue with a warning for testing other parts
    class GraphHomomorphismCounter:
        def __init__(self, H, G): print(f"Warning: Using placeholder GHC for H={H}, G={G}")
        def count_homomorphisms(self): return -1 # Indicate error or placeholder