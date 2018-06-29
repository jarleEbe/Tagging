#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function

import os, re

rootdir = '.'
startdir = 'tokenized/'

#filestotag = re.compile('filestotag', flags=re.IGNORECASE)
#tagged = re.compile('tagged', flags=re.IGNORECASE)
#horizontal = re.compile('horizontal', flags=re.IGNORECASE)
print ("#!/bin/sh", end="\n")
for subdir, dirs, files in os.walk(startdir):
    for file in files:
        if re.search('\_tokenized.txt', file):
            name = file
            name = re.sub('_tokenized.txt', '', name)
            name += "_tagged.txt"
            print('../TreeTagger/cmd/tree-tagger-english ', end="")
            print(os.path.join(subdir, file), end=" ")
#            print(os.path.join(subdir, file), end=" ")
#            print(subdir, end="")
            print('>tagged/', end="")
            print(name, end="")
            print('', end="\n")
#            print(' >>tagging.log 2>&1', end="\n")
