import sys
import os

def read_fasconcat_out(fcc_info_filename):
    infile = open(fcc_info_filename)
    # Make a dictionary to store the beginning and ending site of each locus
    locus_start_end = {}
    for line in infile.readlines():
        if ".fas" in line:
            if line.split("\t")[0] == "FcC_smatrix.fas":
                pass
            else:
                splitter_line = line.split("\t")
                numbers = splitter_line[3].split(" => ")
                if numbers[1] == '':
                    pass
                else:
                    locus_start_end[splitter_line[0].strip(".fas")] = numbers
    infile.close()
    return locus_start_end

def write_raxml_partition_def(directory_name, locus_start_end):
    outfile_name = os.path.join(directory_name, "IQtree_partition.txt")
    outfile = open(outfile_name, "w")
    for i in locus_start_end:
        start = locus_start_end[i][0]
        end = locus_start_end[i][1]
        locus_name = "_".join(i.split("_")[:2])
        write_this = "LG, " + locus_name + " = " + start + "-" + end + "\n"
        outfile.write(write_this)
    outfile.close()

def write_beast_partition_def(directory_name, locus_start_end):
    outfile_name = os.path.join(directory_name, "Beast_partition.txt")
    with open(outfile_name, "w") as outfile:
        outfile.write("BEGIN SETS;")
        outfile.write("\n")
        counter = 1  # Initialize a counter for "part" naming
        for i in locus_start_end:
            start = str(locus_start_end[i][0])
            end = str(locus_start_end[i][1])
            locus_name = f"part{counter}"  # Generate "part" naming convention
            write_this = f"CHARSET {locus_name} = {start}-{end};\n"
            outfile.write(write_this)
            counter += 1  # Increment counter for the next part
        outfile.write("END;")





if __name__ == "__main__":
    fcc_info_filename = sys.argv[1]
    directory_name = os.path.dirname(fcc_info_filename)
    locus_start_end = read_fasconcat_out(fcc_info_filename)
    write_raxml_partition_def(directory_name, locus_start_end)
    write_beast_partition_def(directory_name, locus_start_end)

