#!/bin/bash
# To get Osirix Plugin Generator

svn co https://osirixplugins.svn.sourceforge.net/svnroot/osirixplugins/_help
cd _help
unzip Osirix\ Plugin\ Generator.zip
mv Osirix\ Plugin\ Generator.app ../
cd ../
rm -rf _help
