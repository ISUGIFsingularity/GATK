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

#change this variable to correspond to the directory you downloaded the git repository
export GENMODgit="/pylon5/mc48o5p/severin/isugif/genomeModules"
export TEMPDIR="./"

REF="$1"
#index genome for (a) picard, (b) samtools and (c) bwa
####need to change bioawk to singularity but can't update yet because bowtie2 is throwing an error on spack
bioawk -c fastx '{print}' $REF | sort -k1,1V -T $TEMPDIR | awk '{print ">"$1;print $2}' >Genome_sorted.fa
#parallel <<FIL
${GENMODgit}/wrappers/GM picard CreateSequenceDictionary \
  REFERENCE=Genome_sorted.fa \
  OUTPUT=Genome_sorted.dict
${GENMODgit}/wrappers/GM samtools faidx Genome_sorted.fa
${GENMODgit}/wrappers/GM bwa index -a bwtsw Genome_sorted.fa
#FIL



# Create interval list (here 100 kb intervals)
${GENMODgit}/wrappers/fasta_length Genome_sorted.fa > Genome_sorted_length.txt
${GENMODgit}/wrappers/GM bedtools makewindows -w 100000 -g Genome_sorted_length.txt > Genome_sorted_100kb_coords.bed
${GENMODgit}/wrappers/GM picard BedToIntervalList \
  INPUT= Genome_sorted_100kb_coords.bed \
  SEQUENCE_DICTIONARY=Genome_sorted.dict \
  OUTPUT=Genome_sorted_100kb_gatk_intervals.list
