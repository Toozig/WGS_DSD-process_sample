params.inputDir = ''
params.pathFile = ''
params.sample_file  = ''
params.outputDir = ''
params.upload = false
nextflow.enable.dsl = 2





// function //

def isProcessed(fileName) {
    file_name = "processed.$fileName"
    fileContents = file(params.all_samples).text
    if (fileContents.contains(file_name)) {
        println "$fileName have already been processed"
        return true
    } else {
        return false
    }
}

def isVCFprocessed(vcfFileName){
    fileName = "${vcfFileName}.gz"
    return isProcessed(fileName)

}

// end function //



process compressVCF {
   label 'small_slurm'
    
   
   input:
   path sampleFile
   
   output:
   path "${sampleFile}.gz", emit: output_vcf
   
   script:
   """
   bgzip "$sampleFile"
   """
    
}


process tbiVCF {
    // errorStrategy 'ignore'
    label "small_slurm"
   
    input:
    path sampleFileObj
   
    output:
    path "${sampleFileObj.toString().split('/')[-1]}", emit: output_vcf
    path "${sampleFileObj.toString().split('/')[-1]}.tbi"
   
   script:

   """
    tabix -f -p vcf "${sampleFileObj}"
   """

}



process checkHgVersion {
    errorStrategy 'ignore'
    label "small_slurm"
    errorStrategy 'ignore'
    
    input:
    path sampleFile
    path tbi
    
    output:
    path sampleFile
    
    script:
    """
    # Load necessary modules
    module load hurcs bcftools

    hg38Checker.sh ${sampleFile}
    """
}


process processVCF {
    label "medium_slurm"
    publishDir params.curProcessedOutputDir, mode: 'copy'
    
    input:
    path sampleFile
    
    output:
    path "processed.${sampleFile}", emit: sampleFile
    path "processed.${sampleFile}.tbi", emit: tbiFile
   
   script:
    """
    # Load necessary modules
    module load hurcs bcftools
    process_new_sample.sh ${sampleFile} ${params.curProcessedOutputDir} ${params.all_samples}
    """
}

process uploadData {
  label "small_slurm"
   tag 'upload'
    
    input:
    path processedVCF 
    path tbiFile
    
    script:
    if (params.upload){
        println "upload files"
        """

        ${params.DBXCLI} put $processedVCF $params.processedSamplesUploadDir
        ${params.DBXCLI} put $tbiFile $params.processedSamplesUploadDir
        """
    }
    else{
        println "not uploading"
        """
            echo "not uploading"
        """
    }
}



workflow {
   workDir = file(params.inputDir)
   params.sampleName = workDir.simpleName

       // using default parameters if they werent provided
    if (params.sample_file == ''){
        sampleFile = params.all_samples
    } else {
        sampleFile = params.sample_file
    }
    if (params.outputDir == ''){
        params.curProcessedOutputDir = params.processedOutputDir
    }else {
        params.curProcessedOutputDir =  params.outputDir
    }


    
log.info """
        V C F - P R O C E S S E   P I P E L I N E 
         inputDir: ${params.inputDir}
         outputDir: ${params.curProcessedOutputDir} 
         """
         .stripIndent()

    

   // creates channel for each vcf in the input dir, only if file was not processed before
    listOfgz = file("${workDir}/**.vcf.gz").findAll {!isProcessed(it.Name)}
    listOfvcf = file("${workDir}/**.vcf").findAll {!isVCFprocessed(it.Name)}
    
    
    vcf = Channel.from(listOfvcf.collect {it})
    gz = Channel.from(listOfgz.collect {it})
    if (listOfvcf.size() > 0){
      vcf = compressVCF(vcf)
    }
 

    both = vcf.mix(gz)
    tbi = tbiVCF(both)
    checked = checkHgVersion(tbi)
    processed = processVCF(checked)
    if (params.upload){
        uploadData(processed)
    } 
}


