#!/bin/bash -ue
java -jar /export/scratch/tsvanorden/Char_Phylogenetics/src/phyparts/target/phyparts-0.0.1-SNAPSHOT-jar-with-dependencies.jar phyparts -a 1 -v -d used_trees -m Astral_rerooted.tre -o out
