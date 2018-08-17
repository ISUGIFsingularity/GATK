    #!/bin/bash


    module load singularity

    #change this variable to correspond to the directory you downloaded the git repository
    export GATKgit="/pylon5/mc48o5p/severin/isugif/GATK"
    export TMPDIR=$LOCAL
    THREADS="28"




    REF=$1

    export BASEREF=$(basename ${REF%.*})
    export GENOMEINTERVALS=${BASEREF}_100kb_gatk_intervals.list



    # generate gatk haplotype caller functions on intervals and generate slurms

        # Create interval list (here 100 kb intervals)
        ${GATKgit}/wrappers/fasta_length ${BASEREF}.fasta > ${BASEREF}_length.txt
        # Not sure where the pwd line at the top of the file is coming from but deleted it.
        sed -i -e "1d" ${BASEREF}_length.txt
        ${GATKgit}/wrappers/GATK bedtools makewindows -w 100000 -g ${BASEREF}_length.txt > ${BASEREF}_100kb_coords.bed
        ${GATKgit}/wrappers/GATK picard BedToIntervalList \
          INPUT= ${BASEREF}_100kb_coords.bed \
          SEQUENCE_DICTIONARY=${BASEREF}.dict \
          OUTPUT=${BASEREF}_100kb_gatk_intervals.list
