#!/bin/bash


module load singularity

#change this variable to correspond to the directory you downloaded the git repository
export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"
export TMPDIR=$LOCAL
THREADS="28"




REF=$1
READ1="$2"
READ2="$3"

export BASEREF=$(basename ${REF%.*})


# generate gatk haplotype caller functions on intervals and generate slurms
    GENOMEINTERVALS=${BASEREF}_100kb_gatk_intervals.list

    # Create interval list (here 100 kb intervals)
    ${GATKgit}/wrappers/fasta_length ${BASEREF}.fa > ${BASEREF}_length.txt
    ${GATKgit}/wrappers/GATK bedtools makewindows -w 100000 -g ${BASEREF}_length.txt > ${BASEREF}_100kb_coords.bed
    ${GATKgit}/wrappers/GATK picard BedToIntervalList \
      INPUT= ${BASEREF}_100kb_coords.bed \
      SEQUENCE_DICTIONARY=${BASEREF}.dict \
      OUTPUT=${BASEREF}_100kb_gatk_intervals.list

    #Grab bamfiles that will be used for input. all bam files in the folder will be selected.
    #these files will be written to a temp file that will be read in later to create the input line for each command
    unset -v bamfiles
    bamfiles=(*.bam)
    for bam in ${bamfiles[@]}; do \
    echo -en "-I ${bam} "; \
    done > temp

    #combine the reference genome, 100k genomic intervals and the input files into gatk commands
    #need to figure out how to include direct path to genomeanalysistk.jar file if that is necessary
    while read line; do \
    g2=$(echo $line | awk '{print $1":"$2"-"$3}'); \
    g1=$(echo $line | awk '{print $1"_"$2"_"$3}'); \
    CWD=$(pwd)
    echo -n "${GATKgit}/wrappers/GATK gatk HaplotypeCaller  \
    -R ${GENOMEFASTA} \
    $(cat temp) \
    -L "${g2}" --output \${TMPDIR}/"${g1}".vcf;"; \
    echo "mv \${TMPDIR}/"${g1}".vcf $CWD" ; \
    done< $(grep -v "@" ${GENOMEINTERVALS})  > gatk.cmds



    ${GATKgit}/bin/makeSLURM_bridges.py 100 gatk.cmds
