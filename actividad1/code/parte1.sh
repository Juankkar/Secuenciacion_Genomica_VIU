#!/usr/bin/env bash

rm ../data/processed/README.txt

## Creamos los directorios que vamos a usar
mkdir ../data/processed/FastQC_raw_reads
mkdir ../data/processed/Fastp_results
mkdir ../data/processed/map_results


###############################
## CALIDAD DE LAS SECUENCIAS ##
###############################
echo ""
echo "##########################################"
echo "#        CALIDAD DE LAS SECUENCIAS       #"
echo "##########################################"
echo ""

fastqc ../data/raw/*.gz

## Movemos las lecturas html a una carpeta en concreto
mv ../data/raw/*fastqc* ../data/processed/FastQC_raw_reads

##############
## LIMPIEZA ##
##############
echo ""
echo "##########################################"
echo "#                LIMPIEZA                #"
echo "##########################################"
echo ""

fastp -i ../data/raw/S15_L001_R1_001.fastq.gz -I ../data/raw/S15_L001_R2_001.fastq.gz -o out1.clean.fq.gz -O out2.clean.fq.gz --cut_tail 25 --cut_front 25 --cut_mean_quality 25 -l 100 

## Movemos los resultados a la carpeta de resultados FastP
mv *.json  *clean* fastp.html ../data/processed/Fastp_results/

fastqc ../data/processed/Fastp_results/*.gz

###########
## MAPEO ##
###########
echo ""
echo "##########################################"
echo "#                  MAPEO                 #"
echo "##########################################"
echo ""

## Primero indexamos el genoma de referencia, en nuestro 
## caso se trata del cromosoma 16 humano
bwa index ../data/raw/Homo_sapiens.GRCh37.dna.chromosome.16.fa

## Lo siguiente es mapear el genoma de referencia:
bwa mem -a ../data/raw/Homo_sapiens.GRCh37.dna.chromosome.16.fa ../data/processed/Fastp_results/out1.clean.fq.gz ../data/processed/Fastp_results/out2.clean.fq.gz -o chr16.sam 2> chr16.out

mv chr16.sam chr16.out ../data/raw/*.fa.* ../data/processed/map_results

##################################
## PASAR DE FORMATO .sam A .BAM ##
##################################
echo ""
echo "##########################################"
echo "#    PASAR DE FORMATO .sam A .BAM        #"
echo "##########################################"
echo ""

## Pasamos en ese entonces el archivo .sam a .bam
samtools view -bS ../data/processed/map_results/chr16.sam > ../data/processed/map_results/chr16.bam
## Y lo ordenamos
samtools sort ../data/processed/map_results/chr16.bam > ../data/processed/map_results/chr16_sorted.bam
## Indexamos el archivo
samtools index ../data/processed/map_results/chr16_sorted.bam
## Y Observamos unas estadísticas básicas del archivo
samtools flagstats ../data/processed/map_results/chr16_sorted.bam

#########################
## ELIMINAR DUPLICADOS ##
#########################
echo ""
echo "################################"
echo "#     ELIMINAR DUPLICADOS      #"
echo "################################"
echo ""

## Marcamos los duplicados
picard MarkDuplicates --INPUT ../data/processed/map_results/chr16_sorted.bam --OUTPUT ../data/processed/map_results/chr16_dedup.bam --METRICS_FILE markDuplicatesMetrics.txt --ASSUME_SORTED True

#addReadGroups (porque no los incluimos en el mapeo, y si no, nos da problemas en el siguiente paso
picard AddOrReplaceReadGroups -I ../data/processed/map_results/chr16_dedup.bam -O ../data/processed/map_results/chr16_dedup_RG.bam -RGID M02899 -RGLB lib1 -RGPL ILLUMINA -RGPU unit1 -RGSM S15

## Indexamos de nuevo el bam de duplicados en este caso
samtools index ../data/processed/map_results/chr16_dedup_RG.bam

mv markDuplicatesMetrics.txt ../data/processed/map_results/
##################################
## EXTRACCIÓN DE VARIANTES .VCF ##
##################################
echo ""
echo "##################################"
echo "## EXTRACCIÓN DE VARIANTES .VCF ##"
echo "##################################"
echo ""

## Lamada de variantes, el mínimo de lecturas que se deben mapear son 100 (C=100)
freebayes -C 100 -f ../data/raw/Homo_sapiens.GRCh37.dna.chromosome.16.fa ../data/processed/map_results/chr16_dedup_RG.bam > ../data/processed/map_results/chr16.vcf

## Vemos las estadísticas sobre las variantes encontradas
rtg vcfstats ../data/processed/map_results/chr16.vcf > ../data/processed/map_results/chr16.vcfstats
