#!/bin/bash

#This script is expecting you to have all of your vcf files and vcf.idx files placed in a subfolder from where you ran GATK.  This way the files that are generated are placed in your GATK folder.
#Also update the GATK location, Raw file and the reference for your run



#vcffile=(*.vcf)
#this is just naming the vcf file that will be generated belwo.
RAW=$1
REFERENCE=$2
#MAXDEPTH=30000


#vcf-concat ${vcffile[@]} >> ../${RAW}

      MAXDEPTH=$(grep -oh ";DP=.*;" ${RAW} | cut -d ";" -f 2 | cut -d "="  -f 2  | ${GATKgit}/wrappers/GATK datamash mean 1 sstdev 1 | awk '{print $1+5*$2}' | tail -n 1)
#cat ../${RAW} | ${GATKgit}/wrappers/GATK vcf-sort -t $TMPDIR -p 16 -c > ${RAW%.*}_sorted.vcf

${GATKgit}/wrappers/GATK gatk SelectVariants \
  -R ${REFERENCE} \
  -V ${RAW} \
  -select-type SNP \
  --output ${RAW%.*}_sorted_SNPs.vcf

${GATKgit}/wrappers/GATK gatk VariantFiltration \
  -R ${REFERENCE} \
  -V ${RAW%.*}_sorted_SNPs.vcf \
  --filter-expression "QD<2.0||FS>60.0||MQ<40.0||MQRankSum<-12.5||ReadPosRankSum<-8.0||SOR>3.0||DP>${MAXDEPTH}" \
  --filter-name "FAIL" \
  --output ${RAW%.*}_sorted_filtered_SNPs.vcf

${GATKgit}/wrappers/GATK gatk  SelectVariants \
  -R ${REFERENCE} \
  -V ${RAW} \
  -select-type INDEL \
  --output ${RAW%.*}_sorted_indels.vcf

${GATKgit}/wrappers/GATK gatk  VariantFiltration \
  -R ${REFERENCE} \
  -V ${RAW%.*}_sorted_indels.vcf \
  --filter-expression "QD<2.0||FS>200.0||ReadPosRankSum<-20.0||SOR>10.0||InbreedingCoeff<-0.8" \
  --filter-name "FAIL" \
  --output ${RAW%.*}_sorted_filtered_indels.vcf
