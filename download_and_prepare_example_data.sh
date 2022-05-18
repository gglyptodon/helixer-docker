mkdir three_algae
cd three_algae

# download all the data
for pth in http://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/chlamydomonas_reinhardtii/dna/Chlamydomonas_reinhardtii.Chlamydomonas_reinhardtii_v5.5.dna_sm.toplevel.fa.gz \
           http://ftp.ensemblgenomes.org/pub/plants/release-47/gff3/chlamydomonas_reinhardtii/Chlamydomonas_reinhardtii.Chlamydomonas_reinhardtii_v5.5.47.gff3.gz \
http://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/ostreococcus_lucimarinus/dna/Ostreococcus_lucimarinus.ASM9206v1.dna.toplevel.fa.gz \
           http://ftp.ensemblgenomes.org/pub/plants/release-47/gff3/ostreococcus_lucimarinus/Ostreococcus_lucimarinus.ASM9206v1.47.gff3.gz \
           http://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/cyanidioschyzon_merolae/dna/Cyanidioschyzon_merolae.ASM9120v1.dna.toplevel.fa.gz \
           http://ftp.ensemblgenomes.org/pub/plants/release-47/gff3/cyanidioschyzon_merolae/Cyanidioschyzon_merolae.ASM9120v1.47.gff3.gz
do
  wget $pth
  sleep 0.4s
done

gunzip *.gz

species="Chlamydomonas_reinhardtii Ostreococcus_lucimarinus Cyanidioschyzon_merolae"

for sp in $species
do
  spdir=$sp/input
  mkdir -p $spdir
  mv ${sp}.* $spdir/
done

# import into db (using --basedir for import, but writing all into one db with --db-path)
for sp in $species
do
  import2geenuff.py --basedir $sp --species $sp --db-path three_algae.sqlite3
done
cd ..
