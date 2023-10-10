version 1.0

task ncbi_scrub_pe {
  input {
    File read1
    File read2
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/ncbi/sra-human-scrubber:1.0.2021-05-05"
    Int disk_size = 100
  }
  String r1_filename = basename(read1)
  String r2_filename = basename(read2)
  command <<<
    # date and version control
    date | tee DATE

    # unzip forward read file as the scrub tool does not take in .gz fastq files
    if [[ "~{read1}" == *.gz ]]
    then
      gunzip -c ~{read1} > r1.fastq
      read1_unzip=r1.fastq
    else
      read1_unzip=~{read1}
    fi

    # dehost reads
    /opt/scrubber/scripts/scrub.sh -n ${read1_unzip} |& tail -n1 | awk -F" " '{print $1}' > FWD_SPOTS_REMOVED

    # gzip dehosted forward reads
    gzip ${read1_unzip}.clean -c > ~{samplename}_R1_dehosted.fastq.gz

    # unzip reverse read file if necessary
    if [[ "~{read2}" == *.gz ]]
    then
      gunzip -c ~{read2} > r2.fastq
      read2_unzip=r2.fastq
    else
      read2_unzip=~{read2}
    fi

    # dehost reads
    /opt/scrubber/scripts/scrub.sh -n ${read2_unzip} |& tail -n1 | awk -F" " '{print $1}' > REV_SPOTS_REMOVED

    # gzip dehosted reverse reads
    gzip ${read2_unzip}.clean -c > ~{samplename}_R2_dehosted.fastq.gz
  >>>
  output {
    File read1_dehosted = "~{samplename}_R1_dehosted.fastq.gz"
    File read2_dehosted = "~{samplename}_R2_dehosted.fastq.gz"
    Int read1_human_spots_removed = read_int("FWD_SPOTS_REMOVED")
    Int read2_human_spots_removed = read_int("REV_SPOTS_REMOVED")
    String ncbi_scrub_docker = docker

  }
  runtime {
      docker: "~{docker}"
      memory: "8 GB"
      cpu: 4
      disks:  "local-disk " + disk_size + " SSD"
      disk: disk_size + " GB" # TES
      preemptible: 0
      maxRetries: 3
  }
}

task ncbi_scrub_se {
  input {
    File read1
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/ncbi/sra-human-scrubber:2.1.0"
    Int disk_size = 100
  }
  String r1_filename = basename(read1)
  command <<<
    # date and version control
    date | tee DATE

    # unzip fwd file as scrub tool does not take in .gz fastq files
    if [[ "~{read1}" == *.gz ]]
    then
      gunzip -c ~{read1} > r1.fastq
      read1_unzip=r1.fastq
    else
      read1_unzip=~{read1}
    fi

    # dehost reads
    /opt/scrubber/scripts/scrub.sh -n ${read1_unzip} |& tail -n1 | awk -F" " '{print $1}' > FWD_SPOTS_REMOVED

    # gzip dehosted reads
    gzip ${read1_unzip}.clean -c > ~{samplename}_R1_dehosted.fastq.gz
  >>>
  output {
    File read1_dehosted = "~{samplename}_R1_dehosted.fastq.gz"
    Int read1_human_spots_removed = read_int("FWD_SPOTS_REMOVED")
    String ncbi_scrub_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB" # TES
    preemptible: 0
    maxRetries: 3
  }
}


task ncbi_scrub_pe_v2 {
  input {
    File read1
    File read2
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/ncbi/sra-human-scrubber:2.2.1"
    Int disk_size = 100
  }
  command <<<
    # date and version control
    date | tee DATE

    # unzip read files as scrub tool does not take in .gz fastq files, and interleave them
    paste <(zcat ~{read1} | paste - - - -) <(zcat ~{read2} | paste - - - -) | tr '\t' '\n' > interleaved.fastq

    # dehost reads: -s reads are paired-end and both are to be masked/removed; -x removes reads instead of masking them
    /opt/scrubber/scripts/scrub.sh -s -x -i interleaved.fastq |& tail -n1 | awk -F" " '{print $1}' > SPOTS_REMOVED

    # split interleaved reads and compress files
    paste - - - - - - - - < interleaved.fastq.clean \
      | tee >(cut -f 1-4 | tr '\t' '\n' | gzip > ~{samplename}_R1_dehosted.fastq.gz) \
      | cut -f 5-8 | tr '\t' '\n' | gzip > ~{samplename}_R2_dehosted.fastq.gz

  >>>
  output {
    File read1_dehosted = "~{samplename}_R1_dehosted.fastq.gz"
    File read2_dehosted = "~{samplename}_R2_dehosted.fastq.gz"
    Int human_spots_removed = read_int("SPOTS_REMOVED")
    String ncbi_scrub_docker = docker
  }
  runtime {
      docker: "~{docker}"
      memory: "8 GB"
      cpu: 4
      disks:  "local-disk " + disk_size + " SSD"
      disk: disk_size + " GB" # TES
      preemptible: 0
      maxRetries: 3
  }
}

task ncbi_scrub_se_v2 {
  input {
    File read1
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/ncbi/sra-human-scrubber:2.2.1"
    Int disk_size = 100
  }
  String r1_filename = basename(read1)
  command <<<
    # date and version control
    date | tee DATE

    # unzip fwd file as scrub tool does not take in .gz fastq files
    if [[ "~{read1}" == *.gz ]]
    then
      gunzip -c ~{read1} > r1.fastq
      read1_unzip=r1.fastq
    else
      read1_unzip=~{read1}
    fi

    # dehost reads: -x removes reads instead of masking them
    /opt/scrubber/scripts/scrub.sh -x -i ${read1_unzip} |& tail -n1 | awk -F" " '{print $1}' > FWD_SPOTS_REMOVED

    # gzip dehosted reads
    gzip ${read1_unzip}.clean -c > ~{samplename}_R1_dehosted.fastq.gz
  >>>
  output {
    File read1_dehosted = "~{samplename}_R1_dehosted.fastq.gz"
    Int read1_human_spots_removed = read_int("FWD_SPOTS_REMOVED")
    String ncbi_scrub_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB" # TES
    preemptible: 0
    maxRetries: 3
  }
}