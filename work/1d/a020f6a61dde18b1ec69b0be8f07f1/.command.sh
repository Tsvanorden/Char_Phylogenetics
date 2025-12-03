#!/bin/bash -ue
/export/scratch/tsvanorden/Char_Phylogenetics/src/iqtree-2.1.3-Linux/bin/iqtree2 -s FcC_smatrix.fas -spp IQtree_partition.txt -pre ML_Tree -m MFP -bb 1000 -T 16
/export/scratch/tsvanorden/Char_Phylogenetics/src/iqtree-2.1.3-Linux/bin/iqtree2 --scf 100 -s FcC_smatrix.fas -t ML_Tree.treefile -pre Aligned_scf -T 16
