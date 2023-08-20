# VCF File Analysis Pipeline

This pipeline processes new VCF files to assess and analyze them for suspicious variants.

## Input

- `inputDir`: The directory containing VCF / VCF.bgz files. These files can be located in subfolders.
- `pathFile` (optional): A text file containing the path to each processed VCF file.
- `outputDir` (optional): The directory where the processed VCF files will be saved.
- `upload`: Specifies whether to upload the processed file to Dropbox.

(Note: Optional parameters can be defined in the pipeline JSON file.)

## Pipeline Steps

1. **BGZip Unzipped VCF Files:** Unzips and BGZips VCF files that are not already compressed.
2. **TBI VCF Without Index File:** Generates index files (TBI) for VCF files without an existing index.
3. **Version Check:** Verifies whether the VCF is in the hg38 version. The pipeline will drop files that are not the correct version.
4. **VCF Processing:** Processes the VCF files for analysis.
5. **Upload Processed VCF:** Uploads the processed VCF files if the `upload` parameter is set to true.

## Pipeline Configuration (JSON File)

- `all_samples`: A text file containing the path to each processed VCF file.
- `processedOutputDir`: The default directory where processed VCF files will be saved.
- `processedSamplesUploadDir`: Directory path for uploading processed VCF files to Dropbox.
- `DBXCLI`: Path to [dbxcli](https://github.com/dropbox/dbxcli) for Dropbox uploads.

## Running the Pipeline

```bash
~/nextflow run process_new_sample.nf --inputDir NEW/VCF/FILES/DIR --params-file process_new_sample.json --upload true -c process-selector.config
```

Replace `NEW/VCF/FILES/DIR` with the actual path to the directory containing your VCF files. Adjust other parameters and options as needed.
