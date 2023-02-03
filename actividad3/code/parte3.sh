#!/usr/bin/env bash

## Creamos los ficheros que vamos a usar:
mkdir ../data/processed/FastQC_raw_reads
mkdir ../data/processed/Fastp_results
mkdir ../data/processed/kraken_db
mkdir ../data/processed/kraken_results
mkdir ../data/processed/map_results

## Estudiamos la calidad de los datos
echo ""
echo "#############################"
echo "## CALIDAD DE LAS LECTURAS ##"
echo "#############################"
echo ""

fastqc ../data/raw/*.fastq.gz
mv ../data/raw/*fastqc* ../data/processed/FastQC_raw_reads

## Hacemos ahora la limpieza de los datos:
echo ""
echo "##############"
echo "## LIMPIEZA ##"
echo "##############"
echo ""

fastp -i ../data/raw/sample1.R1.fastq.gz -I ../data/raw/sample1.R2.fastq.gz -o out1.fastq.gz -O out2.fastq.gz --detect_adapter_for_pe --cut_tail 25 --cut_front 25 --cut_mean_quality 25 --html out.fastp.html

mv *fastp* out*  ../data/processed/Fastp_results
## Realizamos un fastqc de las lecturas limpias
fastqc ../data/processed/Fastp_results/out*fastq.gz

## Limpieza usando kraken
echo ""
echo "#####################"
echo "## LIMPIEZA KRAKEN ##"
echo "#####################"
echo ""

cp  ../data/raw/kraken2_h+v_20200319-001.tar.gz ../data/processed/kraken_db
tar -zvxf ../data/processed/kraken_db/kraken2_h+v_20200319-001.tar.gz
mv *.k2d ../data/processed/kraken_db
rm ../data/processed/kraken_db/kraken2_h+v_20200319-001.tar.gz
  
## Mapeo Kraken2 a la base de datos, donde se clasifican todas las lecturas de la muestra
kraken2 --db ../data/processed/kraken_db --threads 2 --paired ../data/processed/Fastp_results/out1.fastq.gz ../data/processed/Fastp_results/out2.fastq.gz --output ../data/processed/kraken_results/sample1.kraken
echo "## Número de lecturas humanas vs lecturas de covid ##"
id=$(cut -f 3 ../data/processed/kraken_results/sample1.kraken)
seq_humano=$(echo $id | grep -o 9606 | wc -l)
seq_covid=$(echo $id | grep -o 2697049 | wc -l)
echo "=----------------------------------------------------------------------------="
echo "==> Nº de lecturas HUMANAS: $seq_humano | Nº de lecturas SARS: $seq_covid <==="
echo "=----------------------------------------------------------------------------="

## Filtramos las lecturas que no sean de Covid
awk '$3 != "9606" { print $2 }' ../data/processed/kraken_results/sample1.kraken > ../data/processed/kraken_results/sample1.kraken.nohuman.ids

## Sacamos las lecturas en un archivo comprimido
seqtk subseq ../data/processed/Fastp_results/out1.fastq.gz ../data/processed/kraken_results/sample1.kraken.nohuman.ids > ../data/processed/kraken_results/sample1.R1.nonhuman.fq
seqtk subseq ../data/processed/Fastp_results/out2.fastq.gz ../data/processed/kraken_results/sample1.kraken.nohuman.ids > ../data/processed/kraken_results/sample1.R2.nonhuman.fq
gzip ../data/processed/kraken_results/*.fq

## Mapeo de las lecturas ##
echo ""
echo "###########################"
echo "## MAPEO DE LAS LECTURAS ##"
echo "###########################"
echo ""

## Indexamos el genoma de referencia
cp ../data/raw/GCF_009858895.2_ASM985889v3_genomic.fna ../data/processed/map_results
bwa index ../data/processed/map_results/GCF_009858895.2_ASM985889v3_genomic.fna

## Mapeo de las secuencias limpias al genoma de referencia
bwa mem -Y -M -R '@RG\tID:\tSM:.' -t 2 ../data/processed/map_results/GCF_009858895.2_ASM985889v3_genomic.fna ../data/processed/kraken_results/sample1.R1.nonhuman.fq.gz ../data/processed/kraken_results/sample1.R2.nonhuman.fq.gz  | samtools sort | samtools view -F 4 -b -@ 2 -o ../data/processed/map_results/sample1.sort.bam

## Indexamos los datos BAM ordenados
bwa index ../data/processed/map_results/sample1.sort.bam

## Eliminamos los primers para que no interfieran en la determinación de las variantes
ivar trim -i ../data/processed/map_results/sample1.sort.bam -p ../data/processed/map_results/sample1.trim -m 30 -q 20 -s 4 -b ../data/raw/nCoV-2019_v4.primer.bed 

## Orden e indexado de los archivos de salida

samtools sort ../data/processed/map_results/sample1.trim.bam -o ../data/processed/map_results/sample1.trim.sort.bam 

samtools index ../data/processed/map_results/sample1.trim.sort.bam 

## Llamada de variants con iVar
samtools mpileup -A -d 0 --reference ../data/processed/map_results/GCF_009858895.2_ASM985889v3_genomic.fna -B -Q 0 ../data/processed/map_results/sample1.trim.sort.bam | ivar variants -p sample1.ivar

## Extraemos la secuencia consenso con ivar
samtools mpileup --a -A -d 0 -B -Q 0 ../data/processed/map_results/sample1.trim.sort.bam | ivar consensus -p ../data/processed/map_results/sample1.ivar -q 30 -t 0.9 -m 50 -n N

mv *ivar* ../data/processed/map_results

## Determinar el linaje
# Actualizamos primero
pangolin --update
pangolin ../data/processed/map_results/sample1.ivar.fa -o ../data/processed/map_results/sample1.pangolin --outfile sample1.csv --max-ambig 0.3
