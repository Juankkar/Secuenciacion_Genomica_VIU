#!/usr/bin/env bash

## Reseteamos los directorios con los resultados
rm -rf ../data/FastQC_raw_reads/*
rm -rf ../data/Fastp_results/*
rm -rf ../data/map_results/*

###############################
## CALIDAD DE LAS SECUENCIAS ##
###############################
echo ""
echo "##########################################"
echo "#        CALIDAD DE LAS SECUENCIAS       #"
echo "##########################################"
echo ""
fastqc ../data/*.gz

## Movemos las lecturas html a una carpeta en concreto
mv ../data/*fastqc* ../data/FastQC_raw_reads
##############
## LIMPIEZA ##
##############
echo ""
echo "##########################################"
echo "#                LIMPIEZA                #"
echo "##########################################"
echo ""

fastp -i ../data/S15_L001_R1_001.fastq.gz -I ../data/S15_L001_R2_001.fastq.gz -o out1.clean.fq.gz -O out2.clean.fq.gz --cut_tail 25 --cut_front 25 --cut_mean_quality 25 -l 100 -h out_FastP.html

## Movemos los resultados a la carpeta de resultados FastP
mv *.json  *clean* *FastP* ../data/Fastp_results/

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
bwa index ../data/Homo_sapiens.GRCh37.dna.chromosome.16.fa

## Lo siguiente es mapear el genoma de referencia:
bwa mem -a ../data/Homo_sapiens.GRCh37.dna.chromosome.16.fa ../data/Fastp_results/out1.clean.fq.gz ../data/Fastp_results/out2.clean.fq.gz -o chr16.sam 2> chr16.out

mv chr16.sam chr16.out ../data/*.amb ../data/*.ann ../data/*.bwt ../data/*.pac ../data/*.sa ../data/map_results

##################################
## PASAR DE FORMATO .sam A .BAM ##
##################################
echo ""
echo "##########################################"
echo "#    PASAR DE FORMATO .sam A .BAM        #"
echo "##########################################"
echo ""

## Pasamos en ese entonces el archivo .sam a .bam
samtools view -bS ../data/map_results/chr16.sam > ../data/map_results/chr16.bam
## Y lo ordenamos
samtools sort ../data/map_results/chr16.bam > ../data/map_results/chr16_sorted.bam
## Indexamos el archivo
samtools index ../data/map_results/chr16_sorted.bam
## Y Observamos unas estadísticas básicas del archivo
samtools flagstats ../data/map_results/chr16_sorted.bam
