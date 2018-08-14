#!/bin/bash
# performs mapping of reads to the indexed reference genome
# uses the options specified in "best practices"

#command genomeModule READ1 READ2

module load singularity

#change this variable to correspond to the directory you downloaded the git repository
export GENMODgit="/pylon5/mc48o5p/severin/isugif/GATK"


REF="$1"  ## same as input for GATK_00

# This assumes that you ran GATK_00 to sort the original reference file.
export REF=$(basename ${REF%.*})_sorted.fa


# this option might be the frequetly changed, hence not it's a variable
THREADS="16"
# if the reads are paired then use -p option
if [ "$#" -eq 3 ]; then
  READ1="$2"
  READ2="$3"
  OUTNAME=$(basename ${READ1%.*} | cut -f 1-2 -d "_")
  ${GENMODgit}/wrappers/GATK bwa mem -M -t ${THREADS} ${REF} ${READ1} ${READ2} | ${GENMODgit}/wrappers/GATK samtools view -buS - > ${OUTNAME}.bam
# if not just use the reads as single reads
elif [ "$#" -eq 1 ]; then
  READ1="$2"
  OUTNAME=$(basename ${READ1%.*} | cut -f 1-2 -d "_")
  ${GENMODgit}/wrappers/GATK bwa mem -M -t ${THREADS} ${REF} ${READ1} | ${GENMODgit}/wrappers/GATK samtools view -buS - > ${OUTNAME}.bam
# if number of arguments do not match, raise error
else
  echo "ERROR: INVALID NUMBER OF ARGUMENTS"
  echo "GATK_01_RunBWA.sh genomeModule READ1 READ2"
fi
