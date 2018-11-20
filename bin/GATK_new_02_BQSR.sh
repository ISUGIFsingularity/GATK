#!/bin/bash
# If you don't have a known SNPs file, you will have to come back to this step after running haplotypecaller and stringent filtering.
# In other words, you can run this again, after you complete first round of SNP calling to improve the SNPs called

#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_tools_walkers_vqsr_VariantRecalibrator.php
#https://software.broadinstitute.org/gatk/documentation/article.php?id=1259


export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"


KNOWN_VCF="$2"
REFERENCE="$1"
FILE="$3"
${GATKgit}/wrappers/GATK gatk BaseRecalibrator \
    -R ${REFERENCE} \
    -I ${FILE} \
    -knownSites ${KNOWN_VCF} \
    -output ${FILE%.*}_recal_data.table || {
echo >&2 recal data table generation failed for $FILE
exit 1
}

${GATKgit}/wrappers/GATK gatk ApplyBQSR  \
    -R ${REFERENCE} \
    -I ${FILE} \
    -knownSites ${KNOWN_VCF} \
    -BQSR ${FILE%.*}_recal_data.table \
    -output ${FILE%.*}_post_recal_data.table || {
echo >&2 post recal data table generation failed for $FILE
exit 1
}
#java -jar ${GATK}/GenomeAnalysisTK.jar \
#    -T AnalyzeCovariates \
#    -R ${REFERENCE} \
#    -before ${FILE%.*}_recal_data.table \
#    -after ${FILE%.*}_post_recal_data.table \
#    -plots ${FILE%.*}_recalibration_plots.pdf || {
#echo >&2 recal plots generation failed for $FILE
#exit 1
#}
${GATKgit}/wrappers/GATK gatk PrintReads \
    -R ${REFERENCE} \
    -I ${FILE} \
    -BQSR ${FILE%.*}_recal_data.table \
    -output ${FILE%.*}_recal_reads.bam || {
echo >&2 writing recal bam failed for $FILE
exit 1
}
#${GATKgit}/wrappers/GATK picard BuildBamIndex \
#    INPUT=${FILE%.*}_recal_reads.bam \
#    OUTPUT=${FILE%.*}_recal_reads.bai || {
#echo >&2 recal bam indexing failed for $FILE
#exit 1
#}
