# Actividad de secuenciación genómica, genoma humano

Pipeline a seguir:

1) Secuenciador
    * input: genoteca
    * output: archivos FASTQ-raw

2) Análisis de calidad
    * input: archivos FASTQ-raw
    * output: archivos HTML
    * herramienta: FastQC

3) Limpieza de adaptadores y regiones de baja calidad
    * input: archivos FASTQ-raw
    * output: archivos FASTQ-clean
    * herramienta: FastP

4) Revisión de calidad post-procesado
    * input: archivos FASTQ-clean
    * output: archivos HTML
    * herramienta: FastQC

5) Mapeo a genoma referencia
    * input: archivos FASTQ-clean + genoma referencia FASTA
    * output: archivo SAM
    * herrmienta: BWA

6) Conversión de archivos y procesamiento
    * input SAM
    * output: BAM/BAI
    * herramienta: SAMTOOLS

7) Análisis de calidad del mapeo
    * input: BAM
    * output: archivo HTML/PDF
    * herramienta: Qualimap

8) Preprocesado identificadores de duplicados
    * input: BAM
    * output: VCF
    * herramienta Freebayes

9) Filtrado de SNPs/SNVs y de indels
    * input: VCF
    * output: VCF
    * herramienta: VCFTools

10) Visualización de varianetes: 
    * input VCF
    * output: visual
    * herramienta: IGV

11) Anotación de variantes
    * input VCF
    * output: informe escrito
    * herrmienta: VEP/Annovar

12)Interpretación de los resutados

