#!/usr/bin/env bash

rm -f ../data/processed/README.txt

## Creamos los direcotrios a usar 
mkdir ../data/processed/FastQC_raw_reads
mkdir ../data/processed/Fastp_results
mkdir ../data/processed/ensamblaje


echo ""
echo "###############################"
echo "## CALIDAD DE LAS SECUENCIAS ##"
echo "###############################"
echo ""

## Realizamos un análisis de la calidad de los datos crudos
fastqc ../data/raw/*.gz

## Movemos las lecturas html a la carpeta processed
mv ../data/raw/*fastqc* ../data/processed/FastQC_raw_reads

echo ""
echo "##############"
echo "## LIMPIEZA ##"
echo "##############"
echo ""

## Realizamos la limpieza de los datos
fastp -i ../data/raw/DRR021837_1.fastq.gz -I ../data/raw/DRR021837_2.fastq.gz -o out1.clean.fq.gz -O out2.clean.fq.gz --cut_tail 25 --cut_front 25 --cut_mean_quality 25  -l 151

## Movemos los resultados a la carpeta correspondiente
mv *.json *clean* fastp.html ../data/processed/Fastp_results

## Hacemos el mísmo análisis de calidad
fastqc ../data/processed/Fastp_results/*.gz

echo ""
echo "########################"
echo "## ENSAMBLAJE DE NOVO ##"
echo "########################"
echo ""

## Usamos el comando spades.py para hacer el ensamblaje de novo
spades.py -1 ../data/processed/Fastp_results/out1.clean.fq.gz -2 ../data/processed/Fastp_results/out2.clean.fq.gz --careful -k auto -o ../data/processed/ensamblaje

## Evaluamos la calidad del esamblaje
quast.py -o ../data/processed/ensamblaje/quast_result -m 0 -t 2 -k --k-mer-size 127 --circos --pe1 ../data/processed/Fastp_results/out1.clean.fq.gz --pe2 ../data/processed/Fastp_results/out2.clean.fq.gz ../data/processed/ensamblaje/contigs.fasta ../data/processed/ensamblaje/scaffolds.fasta

echo ""
echo "#####################################"
echo "## ANOTACIÓN DEL GENOMA ENSAMBLADO ##"
echo "#####################################"
echo ""

prokka --outdir ../data/processed/ensamblaje/prokka_pseudomonas --addgenes --addmrna --genus Pseudomonas --species aeruginosa --kingdom Bacteria --usegenus --proteins ../data/raw/ref_prots_PAO1.faa --mincontiglen 0  ../data/processed/ensamblaje/contigs.fasta

echo ""
echo "###############################"
echo "## RESISTENCIA/VIRULENCIA... ##"
echo "###############################"
echo ""

## Actualizamos amrfinder
amrfinder --update

## Y utilizamos el comando para  crear un csv en el que podemos ver las bacterias que generan resistencia antibióticos
amrfinder --organism Pseudomonas_aeruginosa -n ../data/processed/ensamblaje/prokka_pseudomonas/PROKKA_02052023.ffn -c 0.8 -i 0.9 --plus --log ../data/processed/ensamblaje/prokka_pseudomonas/amrfinder.log > ../data/processed/ensamblaje/prokka_pseudomonas/amrfinder_out.csv
