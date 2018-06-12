#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function

import os, re

rootdir = '.'
startdir = 'prepdata/'


print ("#!/bin/sh", end="\n")
for subdir, dirs, files in os.walk(startdir):
    for file in files:
        if re.search('\_prepped.txt', file):
            name = file
#            name = re.sub('_prepped.txt', '', name)
#            name += "_tagged.txt"
            print('../CLAWS/run_claws ', end="")
            print(startdir, end="")
            print(file, end="\n")
#           print(os.path.join(subdir, file), end=" ")
#           print('>tagged/', end="")
#           print(name, end="")
#           print('', end="\n")
