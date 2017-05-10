# IMP
IGS Metagenomics Pipeline

This is a stable initial release of code that performs (via a combination
of internal logic, wrappers for the khmer (0.8) package, and wrappers
for IDBA-UD) both single- and paired-end assembly, with or without the
help of a local SGE grid.  Not all permutations are represented in
this repository yet, but all four versions (single/paired X grid/no_grid)
will appear in the near future.

INSTALLATION

1. Clone this repository onto your local machine.

  a) If you have no thread-enabled SGE grid accessible to you, use the "\*.LOCAL"
     codesets to run assemblies locally (make sure you have at least 100GB of memory).

  b) If you do have a thread-enabled SGE grid available, then do the following in
     the "paired_reads.SGE_GRID" and "unpaired_reads.SGE_GRID" subdirectories:
     
    Edit 000_setup.pl:
      
      - Change the value of the "$INSTALL_ROOT" variable to point to your local clone directory
        (the parent directory of "paired_reads.SGE_GRID/").
      - If your system requires that threaded jobs be specified with the "-pe threads X" argument
        to qsub (or something similar: the label following "pe" can be set at the installation level,
        and is thus not consistent across different grids), you'll need to modify the $SGEpeArg variable
        to conform to your own system.
      - Change the name of $SGEdefaultQueue as needed (defaults to "all.q").
      - Change the name of $SGEthreadedQueue as needed (defaults to "threaded.q").
  
OPERATION

Create a working directory for your assembly (you can specify multiple samples to be assembled
in the same working directory if you wish).

Copy 000_setup.pl from the appropriate codeset to this new working directory and run it.
By default, it'll prompt you for sampleID, mate and FASTQ-location data for your input
sample(s), as well as for an SGE project code to use when running grid jobs (if you're
using a grid).  If you prefer, you can specify all of this information (as well as a
list of grid nodes to exclude from submission, if applicable and desired) in three
tab-delimited text files; see your cloned repository for examples of these files whose
dummy values indicate correct syntax.

Run 003_run_assemblies.sh and wait.  Associated grid job names (if running on a grid)
will begin with "mga" and will contain the name of the associated sample ID; check
qstat to assess completion.  The final FASTA product for each assembled sample should
appear in the sample's subdirectory of the main assembly working directory when done.
