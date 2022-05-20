#!/bin/bash

species="Chlamydomonas_reinhardtii Ostreococcus_lucimarinus Cyanidioschyzon_merolae"
cd three_algae

# import into db (using --basedir for import, but writing all into one db with --db-path)
for sp in $species
do
  import2geenuff.py --basedir $sp --species $sp --db-path three_algae.sqlite3
done
cd ..
