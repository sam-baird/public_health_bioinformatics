version 1.0

import "../../../tasks/utilities/task_file_handling.wdl" as file_handling
import "../../../tasks/task_versioning.wdl" as versioning

workflow concatenate_tables {
  input {
    Array[File] files_to_cat
    Array[String] samplename
    String concatenated_file_name
  }
  call file_handling.cat_files {
    input:
      files_to_cat = files_to_cat,
      samplename = samplename,
      concatenated_file_name = concatenated_file_name
  }
  call versioning.version_capture {
    input:
  }
  output {
    String concatenate_tables_version = version_capture.phb_version
    String concatenate_tables_analysis_date = version_capture.date

    File concatenated_files = cat_files.concatenated_files
  }
}