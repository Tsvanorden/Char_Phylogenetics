#!/bin/bash -ue
python /export/scratch/tsvanorden/Char_Phylogenetics/src/reroot.py astral.tre GCF013265735_Rainbow_Trout
mv astral.tre_rerooted.tre Astral_rerooted.tre
