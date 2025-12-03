#!/usr/bin/env nextflow


//Process that generates the gene trees. Outputs to directory results/gene_trees

process generate_gene_trees {
    publishDir 'results/gene_trees', mode: 'copy'

    input:
    path file
    val script
    
//Controls Slurm    
    executor 'slurm'
    clusterOptions '--cpus-per-task=1'
    queue 'defq'
    time = '1h'
    cpus = 1
    memory = '4.GB'

   output:
	path "${file}.treefile", emit: gene_trees

    script:
    """
    ${script} -s $file -m MFP -bb 1000 -T 1
    """
}

//Process that generates astral phylogeny. Outputs to directory results/astral

process generate_astral {
    publishDir 'results/astral', mode: 'copy'

    input:
    path input_trees
    val script

   output:
	path 'all.tre'
        path 'astral.tre', emit: astral_tree

    script:
    """
    cat ${input_trees} > all.tre 
    java -jar ${script} -i all.tre -o astral.tre
    """
}

//Process that reroots the gene trees. Outputs to a new directory results/rerooted_trees

process reroot_gene_trees {
    publishDir 'results/rerooted_trees', mode: 'copy'

    input:
    path input_gene_tree
    val reroot_script
    val outgroup

   output:
        path "${input_gene_tree}_rerooted.tre", emit: rerooted_trees

    script:
    """
    python ${reroot_script} ${input_gene_tree} ${outgroup}
    """
}

//Process that is called to reroot the astral phylogeny. Outputs to results/rerooted_trees

process reroot_astral {
    publishDir 'results/astral', mode: 'copy'

    input:
    path astral_input
    val reroot_script
    val outgroup

   output:
        path "Astral_rerooted.tre", emit: astral_tree_rerooted

    script:
    """
    python ${reroot_script} ${astral_input} ${outgroup}
    mv astral.tre_rerooted.tre Astral_rerooted.tre
    """
}

//This process generates the sequence super matrix and the partition file

process generate_ML_info {
    publishDir 'results/concatenated_ML', mode: 'copy'

    input:
    path file
    val FASconCAT
    val extractPartition

   output:
        path "FcC_smatrix.fas", emit: super_matrix
        path "FcC_info.xls", emit: info_file
	path "IQtree_partition.txt", emit: ML_partition
    script:
    """
    perl ${FASconCAT} -i -s
    python ${extractPartition} FcC_info.xls
    """
}

//This makes the maximum likelihood phylogeny and annotates it with concordance factors

process generate_ML {
    publishDir 'results/concatenated_ML', mode: 'copy'

    input:
    path super_matrix
    path partition
    val IQtree_Script

    executor 'slurm'
    clusterOptions '--cpus-per-task=16'
    queue 'defq'
    time = '2h'
    cpus = 16
    memory = '4.GB'

   output:
        path "ML_Tree.treefile", emit: ML_Tree
	path "Aligned_scf.cf.tree", emit: SCF_Tree

    script:
    """
	${IQtree_Script} -s ${super_matrix} -spp ${partition} -pre ML_Tree -m MFP -bb 1000 -T 16
	${IQtree_Script} --scf 100 -s ${super_matrix} -t ML_Tree.treefile -pre Aligned_scf -T 16
    """
}

//This is the weird process I had to do to create a  dircetory location that doesn't exist at runtime as a channel

process make_directory {
    publishDir 'results/PhyParts', mode: 'copy'

   output:
        path "used_trees", emit: used_trees

    script:
    """
    mkdir used_trees
    """
}



//This is the weird process I had to use a directory that didn't exist at runtime

process gene_tree_directory {
    publishDir 'results/PhyParts/used_trees', mode: 'copy'

    input:
    path used_trees
    path gene_trees

   output:
        path "${gene_trees}"

    script:
    """
    cp ${gene_trees} ${used_trees}
    """
}

//This process runs PhyParts and outputs it to the directory results/PhyParts

process run_PhyParts {
    publishDir 'results/PhyParts', mode: 'copy'

    input:
    path astral_tree
    path gene_tree_directory
    val PhyParts_script

   output:
        path "out.concon.tre", emit: concon
	path "out.hist", emit: hist
	path "out.hist.alts", emit: alt
	path "out.node.key", emit: key

    script:
    """
    java -jar ${PhyParts_script} phyparts -a 1 -v -d ${gene_tree_directory} -m ${astral_tree} -o out
    """
}

//This process makes the svg files with pie charts

process make_pie {
    publishDir 'results/PhyParts', mode: 'copy'

    input:
    path astral_tree
    path concon
    path hist
    path alt
    path key
    val PhyPartsPie_script

   output:
        path "pies.svg"

    script:
    """
    python ${PhyPartsPie_script} ${astral_tree} out 881
    """
}

//Location of the genes
params.data = 'data'

//Source Code location
params.iqtree = 'src/iqtree-2.1.3-Linux/bin/iqtree2'
params.astral = 'src/ASTRAL-5.7.1/Astral/astral.5.7.1.jar'
params.reroot = 'src/reroot.py'
params.FASconCAT = 'src/FASconCAT_v1.11.pl'
params.extractPartition = 'src/extract_partition.py'
params.PhyParts = 'src/phyparts/target/phyparts-0.0.1-SNAPSHOT-jar-with-dependencies.jar'
params.PhyPartsPie = 'src/phypartspiecharts.py'


//Outgroup that can be changed to anything
params.outgroup = 'GCF013265735_Rainbow_Trout'



//This is the workflow that executes all of the processes in order
workflow {



//Grab IQtree Script
   iqtree_script =  Channel.fromPath(params.iqtree)

//Put genes into a queue channel
   listOfFiles = Channel.of(file('data/*.fas'))

//Pass in list of loci and IQtree2 script to generate_gene_trees process
   generate_gene_trees(listOfFiles.flatten(), iqtree_script.first())

//Grab Astral Script
   astral_Script = Channel.fromPath(params.astral)

//Pass in list of gene trees and astral script to generate_astral function
   generate_astral(generate_gene_trees.out.gene_trees.collect(flat: false), astral_Script.first())


//Pass in input_gene_trees, python script for rerooting, and an outgroup

   reroot_script = Channel.fromPath(params.reroot)
   outgroup = Channel.of(params.outgroup)

//Run rerooting process
   reroot_gene_trees(generate_gene_trees.out.gene_trees.collect(flat: false).flatten(), reroot_script.first(), outgroup.first())
   reroot_astral(generate_astral.out.astral_tree, reroot_script.first(), outgroup.first())

//Make concatenated super matrix
   
   FASconCAT = Channel.fromPath(params.FASconCAT)
   extractPartition = Channel.fromPath(params.extractPartition)

   generate_ML_info(listOfFiles, FASconCAT.first(), extractPartition.first())
   generate_ML(generate_ML_info.out.super_matrix, generate_ML_info.out.ML_partition, iqtree_script.first())

//setup PhyParts
//PhyParts is weird, and I had to have an extra process to pull files into the working directory

   make_directory()
   gene_tree_directory(make_directory.out.used_trees, reroot_gene_trees.out.rerooted_trees)

//Run PhyParts
   PhyParts = Channel.fromPath(params.PhyParts)
   run_PhyParts(reroot_astral.out.astral_tree_rerooted, make_directory.out.used_trees, PhyParts.first())

//PhyPartsPie
   reroot_astral.out.astral_tree_rerooted.view()
   PhyPartsPie = Channel.fromPath(params.PhyPartsPie)
   make_pie(reroot_astral.out.astral_tree_rerooted, run_PhyParts.out.concon, run_PhyParts.out.hist, run_PhyParts.out.alt, run_PhyParts.out.key, PhyPartsPie.first())
}
