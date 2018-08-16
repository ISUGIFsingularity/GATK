#!/bin/bash
#be sure to add the --env _ variable to your parallel to pass the PBS variables set by torque
#see this website http://www.gnu.org/software/parallel/parallel_tutorial.html
# specifically this needs to be run and the -env _ set in your script when using parallel
# parallel --record-env
# cat ~/.parallel/ignored_vars
# runs the complete Data Cleanup part of the GATK best practices pipeline
# Sort, Clean, MarkDuplicates, Add ReadGroups and IndelRealigner
# You'll need:
# 1. Alignment files in BAM format (for each line separately) with names formated as uniquename_otherinfo.bam
#    unique name shouldn't have any underscores in them, otherinfo added will be used for the readgroup [REQUIRED]
# GATK variable needs to be set to GATK directory

######################################
### Format file names as:
###
### <UNIQIE_FILE_IDENTIFIER>_<UNIT>_<READGROUP>.bam
###
### This will ensure that the Read Group will be properly parsed
### Else you need to manually add them below (SAMPLE, UNIT, RGLB)
###
######################################

#module load picard
#module load samtools
#module load java
#module load gatk
#module load $1
export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"

FILE="$2"

REF="$1"  ## same as input for GATK_00

# This assumes that you ran GATK_00 to sort the original reference file.
export REF=$(basename ${REF%.*})_sorted.fa

# for adding read group info
# if filenames don't have 3 fields, manually add them below
SAMPLE=$(echo ${FILE} | cut -d "_" -f 1)
UNIT=$(echo ${FILE} | cut -d "_" -f 2)
RGLB=$(echo ${FILE} | cut -d "_" -f 3)
#GATK=$GATK_HOME/GenomeAnalysisTK.jar

#I have set up the temp directory that works on Bridges you may need to modify this if the script fails with a java.nio.file.NoSuchFileException:
#TMPDIR=/local/scratch/${USER}/${PBS_JOBID}
export TMPDIR=$LOCAL/
#mkdir -p /local/scratch/${USER}/${PBS_JOBID}
echo $TMPDIR

echo "Sorting BAM of ${FILE}"

if [ ! -f $PBS_O_WORKDIR/${FILE%.*}_picsort.bam ]; then
${GATKgit}/wrappers/GATK picard SortSam \
  TMP_DIR=${TMPDIR}\
  INPUT=${FILE} \
  OUTPUT=${FILE%.*}_picsort.bam \
  SORT_ORDER=coordinate \
  MAX_RECORDS_IN_RAM='null' || {
  echo >&2 sorting failed for $FILE
  exit 1
}
fi

echo "Cleaning Alignment file of ${FILE}"
if [ ! -f $PBS_O_WORKDIR/${FILE%.*}_picsort_cleaned.bam ]; then
${GATKgit}/wrappers/GATK picard CleanSam \
  TMP_DIR=${TMPDIR} \
  INPUT=${FILE%.*}_picsort.bam \
  OUTPUT=${FILE%.*}_picsort_cleaned.bam \
  MAX_RECORDS_IN_RAM='null' || {
  echo >&2 cleaning failed for $FILE
  exit 1
}
fi

echo "Marking Duplicates of ${FILE}"
if [ ! -f $PBS_O_WORKDIR/${FILE%.*}_dedup.bam ]; then
${GATKgit}/wrappers/GATK picard MarkDuplicates \
  TMP_DIR=${TMPDIR} \
  INPUT=${FILE%.*}_picsort_cleaned.bam \
  OUTPUT=${FILE%.*}_dedup.bam \
  METRICS_FILE=${FILE%.*}_metrics.txt \
  ASSUME_SORTED=true \
  REMOVE_DUPLICATES=true \
  MAX_RECORDS_IN_RAM=5000000 || {
  echo >&2 deduplicating failed for $FILE
  exit 1
}
fi

echo "Adding RG info of ${FILE}"
if [ ! -f $PBS_O_WORKDIR/${FILE%.*}_dedup_RG.bam ]; then
${GATKgit}/wrappers/GATK picard AddOrReplaceReadGroups \
  TMP_DIR=${TMPDIR} \
  INPUT=${FILE%.*}_dedup.bam \
  OUTPUT=${FILE%.*}_dedup_RG.bam \
  RGID=${SAMPLE} RGLB=${RGLB} \
  RGPL=illumina \
  RGPU=${UNIT} \
  RGSM=${SAMPLE} \
  MAX_RECORDS_IN_RAM='null' \
  CREATE_INDEX=true || {
  echo >&2 RG adding failed for $FILE
  exit 1
}
fi

${GATKgit}/wrappers/GATK samtools index ${FILE%.*}_dedup_RG.bam


echo "cleaning up of ${FILE%.*}"
#if your job stops midway move all the intermediate files into the main directory and comment out this section
#rewrite to check this folder instead of the main folder for restart
#!/bin/bash

if [ ! -d /tmp/mydir ]; then

mkdir -p IntermediateBAMfiles
fi

mv ${FILE%.*}_picsort.bam IntermediateBAMfiles
mv ${FILE%.*}_picsort_cleaned.bam IntermediateBAMfiles
mv ${FILE%.*}_dedup.bam IntermediateBAMfiles
mv ${FILE%.*}_target_intervals.list IntermediateBAMfiles
mv ${FILE%.*}_metrics.txt IntermediateBAMfiles

echo "All done!"
