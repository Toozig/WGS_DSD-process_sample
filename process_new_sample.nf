params.inputDir= ''
params.pathFile= ''
nextflow.enable.dsl=2


log.info """
        V C F - P R O C E S S E   P I P E L I N E 
         inputDir: ${params.inputDir}
         outputDir: ${params.processedOutputDir} 
         pathFile  ${params.pathFile} 
         """
         .stripIndent()




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
   executor  'slurm'
   cpus  4
   memory  '8g'
   time  '1:00:00'
    
   
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
    errorStrategy 'ignore'
    label "small_slurm"
   
    input:
    val sampleFile_path
   
    output:
    path "${sampleFile_path.split('/')[-1]}", emit: output_vcf
    path "${sampleFile_path.split('/')[-1]}.tbi"
   
   script:
   
   sampleFileObj = file(sampleFile_path)
   sampleFileTbi = file("${sampleFile_path}.tbi")
   // println sampleFile_path.toString()
   if (!sampleFileTbi.exists()) {
   """
    ln -s "${sampleFile_path}" .
    tabix -p vcf "${sampleFileObj}"
   """
   }
   
   
   else{
   """
   ln -s "${sampleFile_path}.tbi" .
   ln -s "${sampleFile_path}" .
   echo ${sampleFile_path} have tbi
   """
   }

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
    publishDir params.processedOutputDir, mode: 'copy'
    
    input:
    path sampleFile
    
    output:
    path "processed.${sampleFile}", emit: sampleFile
    path "processed.${sampleFile}.tbi", emit: tbiFile
   
   script:
    """
    # Load necessary modules
    module load hurcs bcftools
    process_new_sample.sh ${sampleFile} ${params.processedOutputDir} ${params.all_samples}
    """
}




workflow {
//    workDir = file(params.inputDir)
//    params.sampleName = workDir.simpleName
//    listOfgz = file("${workDir}/**.vcf.gz").findAll {!isProcessed(it.Name)}
//    listOfvcf = file("${workDir}/**.vcf").findAll {!isVCFprocessed(it.Name)}
    
    
//    vcf = Channel.from(listOfvcf.collect {it})
//    gz = Channel.from(listOfgz.collect {it})
 //   if (listOfvcf.size() > 0){
 //      vcf = compressVCF(vcf)
 //   }
 
    myFile = file(params.pathFile)
    allLines = myFile.readLines()
    gz = Channel.fromList(allLines)

   // both = vcf.mix(gz)
   tbi = tbiVCF(gz)
    checked =checkHgVersion(tbi)
    processVCF(checked)
   
   //sample_file = processVCF(checkHgVersion(tbiVCF(gz).output_vcf)).sampleFile.collectFile()

    
}


