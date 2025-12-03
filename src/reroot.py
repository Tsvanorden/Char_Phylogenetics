from Bio import Phylo
import sys

def reroot_tree(input_tree, outgroup_label):
    tree = Phylo.read(input_tree, "newick")

    # Find the outgroup clade
    outgroup = next((clade for clade in tree.find_clades() if clade.name == outgroup_label), None)


    # Reroot the tree
    tree.root_with_outgroup(outgroup)

    Phylo.write(tree, f"{input_tree}_rerooted.tre", "newick")



reroot_tree(sys.argv[1], sys.argv[2])
