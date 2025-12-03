# Char_Phylogenetics


To install the software, first clone this repository to your local HPC machine (must use Slurm)

Then, create a conda environment and run 

conda env create --file=environment.yml


To run this software, put the location of your data directory and the name of your outgroup in the Phylogenetics_Pipeline.nf file.

Then, type nextflow run Phylogenetics_Pipeline.nf
