#!/bin/sh
/usr/local/cwb-3.4.13/bin/cwb-encode -d cbf/ -f cbfinputfiles.xml -R /usr/local/share/cwb/registry/cbf -c utf8 -xsB -P pos -P lemma -S s:0 -S text:0+id+gender+decade
echo "/usr/local/bin/cwb-make -V CBF"
echo "HOME /home/jarlee/data/cwb/corpora/cbf"
