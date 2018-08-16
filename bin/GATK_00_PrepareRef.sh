#!/bin/bash
# Prepares the Reference Genome for mapping as well as for using it with GATK pipeline
# You need to supply the referece genome as REF below or as:
# ./GATK_00_PrepareRef.sh your_genome.fasta


module load singularity
#change this variable to correspond to the directory you downloaded the git repository
export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"
export TMPDIR=$LOCAL

REF="$1"
export BASEREF=$(basename ${REF%.*})_sorted

#index genome for (a) picard, (b) samtools and (c) bwa
${GATKgit}/wrappers/GATK bioawk -c fastx '{print}' $REF | sort -k1,1V -T $TMPDIR | awk '{print ">"$1;print $2}' > ${BASEREF}.fa

${GATKgit}/wrappers/GATK picard CreateSequenceDictionary \
  REFERENCE=${BASEREF}.fa \
  OUTPUT=${BASEREF}.dict
${GATKgit}/wrappers/GATK samtools faidx ${BASEREF}.fa
${GATKgit}/wrappers/GATK bwa index -a bwtsw ${BASEREF}.fa


# Create interval list (here 100 kb intervals)
${GATKgit}/wrappers/fasta_length ${BASEREF}.fa > ${BASEREF}_length.txt
${GATKgit}/wrappers/GATK bedtools makewindows -w 100000 -g ${BASEREF}_length.txt > ${BASEREF}_100kb_coords.bed
${GATKgit}/wrappers/GATK picard BedToIntervalList \
  INPUT= ${BASEREF}_100kb_coords.bed \
  SEQUENCE_DICTIONARY=${BASEREF}.dict \
  OUTPUT=${BASEREF}_100kb_gatk_intervals.list
