    #!/bin/bash


    module load singularity

    #change this variable to correspond to the directory you downloaded the git repository
    export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"
    export TMPDIR=$LOCAL
    THREADS="27"




    REF=$1

    export BASEREF=$(basename ${REF%.*})

echo "create bwa index"

    ${GATKgit}/wrappers/GATK bwa index -a bwtsw ${BASEREF}.fasta

echo "need sequence dictionary and Reference index file"

    ${GATKgit}/wrappers/GATK samtools faidx ${BASEREF}.fasta
    ${GATKgit}/wrappers/GATK picard CreateSequenceDictionary \
      REFERENCE=${BASEREF}.fasta \
      OUTPUT=${BASEREF}.dict

echo "generate gatk haplotype caller functions on intervals and generate slurms"

        # Create interval list (here 100 kb intervals)
        ${GATKgit}/wrappers/fasta_length ${BASEREF}.fasta > ${BASEREF}_length.txt
        # Not sure where the pwd line at the top of the file is coming from but deleted it.
        sed -i -e "1d" ${BASEREF}_length.txt
        ${GATKgit}/wrappers/GATK bedtools makewindows -w 1000000 -g ${BASEREF}_length.txt > ${BASEREF}_1000kb_coords.bed
        ${GATKgit}/wrappers/GATK picard BedToIntervalList \
          INPUT= ${BASEREF}_1000kb_coords.bed \
          SEQUENCE_DICTIONARY=${BASEREF}.dict \
          OUTPUT=${BASEREF}_1000kb_gatk_intervals.list
