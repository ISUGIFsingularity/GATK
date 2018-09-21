#!/bin/bash
# This step can be skipped if you don't have the known SNPs file
# You can run this again, after you complete first round of SNP calling to improve the SNPs called

#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_tools_walkers_vqsr_VariantRecalibrator.php
#https://software.broadinstitute.org/gatk/documentation/article.php?id=1259


export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"




KNOWN_VCF="/home/arnstrm/arnstrm/20150413_Graham_SoybeanFST/03_BAM/Soybean_SNPs_119_lines_gatk_htc_only_snps_filtered_pass.vcf"
REFERENCE="/home/arnstrm/arnstrm/20150413_Graham_SoybeanFST/01_DATA/B_REF/Gmax_275_v2.0.fa"
FILE="$1"
${GATKgit}/wrappers/GATK gatk \
    -T BaseRecalibrator \
    -R ${REFERENCE} \
    -I ${FILE} \
    -knownSites ${KNOWN_VCF} \
    -o ${FILE%.*}_recal_data.table || {
echo >&2 recal data table generation failed for $FILE
exit 1
}

${GATKgit}/wrappers/GATK gatk \
    -T BaseRecalibrator \
    -R ${REFERENCE} \
    -I ${FILE} \
    -knownSites ${KNOWN_VCF} \
    -BQSR ${FILE%.*}_recal_data.table \
    -o ${FILE%.*}_post_recal_data.table || {
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
${GATKgit}/wrappers/GATK gatk \
    -T PrintReads \
    -R ${REFERENCE} \
    -I ${FILE} \
    -BQSR ${FILE%.*}_recal_data.table \
    -o ${FILE%.*}_recal_reads.bam || {
echo >&2 writing recal bam failed for $FILE
exit 1
}
${GATKgit}/wrappers/GATK picard BuildBamIndex \
    INPUT=${FILE%.*}_recal_reads.bam \
    OUTPUT=${FILE%.*}_recal_reads.bai || {
echo >&2 recal bam indexing failed for $FILE
exit 1
}
