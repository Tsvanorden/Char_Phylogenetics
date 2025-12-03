#!/bin/bash -ue
perl /export/scratch/tsvanorden/Char_Phylogenetics/src/FASconCAT_v1.11.pl -i -s
python /export/scratch/tsvanorden/Char_Phylogenetics/src/extract_partition.py FcC_info.xls
