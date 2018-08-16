#!/bin/bash


module load singularity

#change this variable to correspond to the directory you downloaded the git repository
export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"
export TMPDIR=$LOCAL

REF=$1
READ1="$2"
READ2="$3"

export BASEREF=$(basename ${REF%.*})

echo "[FASTQ to uBAM](https://gatkforums.broadinstitute.org/gatk/discussion/6484#latest#top)""



${GATKgit}/wrappers/GATK picard FastqToSam FASTQ=${READ1} FASTQ2=${READ2}  OUTPUT=$(basename ${READ1%.*})_fastqtosam.bam READ_GROUP_NAME=RG SAMPLE_NAME=sample LIBRARY_NAME=Solexa-272222 PLATFORM=illumina




echo "Mark Illumina adapters"


${GATKgit}/wrappers/GATK picard MarkIlluminaAdapters I=$(basename ${READ1%.*})_fastqtosam.bam O=$(basename ${READ1%.*})_markilluminaadapters.bam M=$(basename ${READ1%.*})_markilluminaadapters_metrics.txt TMP_DIR=$LOCAL


echo "3A convert BAM to fastq"


${GATKgit}/wrappers/GATK picard SamToFastq I=$(basename ${READ1%.*})_markilluminaadapters.bam FASTQ=$(basename ${READ1%.*})_samtofastq_interleaved.fq CLIPPING_ATTRIBUTE=XT CLIPPING_ACTION=2 INTERLEAVE=true NON_PF=true TMP_DIR=$LOCAL


echo "3B Align reads and flag secondary hits using BWA-MEM"


${GATKgit}/wrappers/GATK bwa index -a bwtsw ${BASEREF}.fasta

${GATKgit}/wrappers/GATK bwa mem -M -t 7 -p ${BASEREF}.fasta $(basename ${READ1%.*})_samtofastq_interleaved.fq > $(basename ${READ1%.*})_bwa_mem.sam


echo "3C Restore altered data and apply & adjust meta information using MergeBamAlignment"


echo "need sequence dictionary and Reference index file"
${GATKgit}/wrappers/GATK samtools faidx ${BASEREF}.fasta
${GATKgit}/wrappers/GATK picard CreateSequenceDictionary \
  REFERENCE=${BASEREF}.fasta \
  OUTPUT=${BASEREF}.dict

echo "merge BAM Alignment"
${GATKgit}/wrappers/GATK picard MergeBamAlignment R=${BASEREF}.fasta UNMAPPED_BAM=$(basename ${READ1%.*})_fastqtosam.bam ALIGNED_BAM=$(basename ${READ1%.*})_bwa_mem.sam O=$(basename ${READ1%.*})_mergebamalignment.bam CREATE_INDEX=true ADD_MATE_CIGAR=true CLIP_ADAPTERS=false CLIP_OVERLAPPING_READS=true INCLUDE_SECONDARY_ALIGNMENTS=true MAX_INSERTIONS_OR_DELETIONS=-1 PRIMARY_ALIGNMENT_STRATEGY=MostDistant ATTRIBUTES_TO_RETAIN=XS TMP_DIR=$LOCAL



echo "Mark Duplicates https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_sam_markduplicates_MarkDuplicates.php"


${GATKgit}/wrappers/GATK picard MarkDuplicates INPUT=$(basename ${READ1%.*})_mergebamalignment.bam OUTPUT=$(basename ${READ1%.*})_mergebamalignment_markduplicates.bam METRICS_FILE=$(basename ${READ1%.*})_mergebamalignment_markduplicates_metrics.txt OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 CREATE_INDEX=true TMP_DIR=$LOCAL


echo "Call with HaplotypeCaller https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_tools_walkers_haplotypecaller_HaplotypeCaller.php"


 ${GATKgit}/wrappers/GATK gatk HaplotypeCaller -R ${BASEREF}.fasta -I $(basename ${READ1%.*})_mergebamalignme nt_markduplicates.bam --output test.vcf
