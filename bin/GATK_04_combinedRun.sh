#!/bin/bash

export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"
export TMPDIR=$LOCAL/

# This assumes that you ran GATK_00 to sort the original reference file.
REF="$1"  ## same as input for GATK_00
export BASEREF=$(basename ${REF%.*})_sorted
export REF=${BASEREF}_sorted.fa

GENOMEFASTA=$REF
GENOMEINTERVALS=${BASEREF}_100kb_gatk_intervals.list
export TMPDIR=$LOCAL/

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


# -stand_emit_conf 10 -stand_call_conf 30
