#!/bin/bash
# Prepares the Reference Genome for mapping as well as for using it with GATK pipeline
# You need to supply the referece genome as REF below or as:
# ./GATK_00_PrepareRef.sh your_genome.fasta

#module load GIF2/picard
#module load samtools
#module load bwa
#module load bedtools2
#module load parallel
#module load python
#module load bioawk

module load singularity
#change this variable to correspond to the directory you downloaded the git repository
export GENMODgit="/pylon5/mc48o5p/severin/isugif/GATK"
export TMPDIR="./"

REF="$1"
export BASEREF=$(basename ${REF%.*})_sorted

#index genome for (a) picard, (b) samtools and (c) bwa
${GENMODgit}/wrappers/GATK bioawk -c fastx '{print}' $REF | sort -k1,1V -T $TMPDIR | awk '{print ">"$1;print $2}' > ${BASEREF}.fa

#${GENMODgit}/wrappers/GATK parallel <<FIL
${GENMODgit}/wrappers/GATK picard CreateSequenceDictionary \
  REFERENCE=${BASEREF}.fa \
  OUTPUT=${BASEREF}.dict
${GENMODgit}/wrappers/GATK samtools faidx ${BASEREF}.fa
${GENMODgit}/wrappers/GATK bwa index -a bwtsw ${BASEREF}.fa
#FIL



# Create interval list (here 100 kb intervals)
${GENMODgit}/wrappers/fasta_length ${BASEREF}.fa > ${BASEREF}_length.txt
${GENMODgit}/wrappers/GATK bedtools makewindows -w 100000 -g ${BASEREF}_length.txt > ${BASEREF}_100kb_coords.bed
${GENMODgit}/wrappers/GATK picard BedToIntervalList \
  INPUT= ${BASEREF}_100kb_coords.bed \
  SEQUENCE_DICTIONARY=${BASEREF}.dict \
  OUTPUT=${BASEREF}_100kb_gatk_intervals.li st
