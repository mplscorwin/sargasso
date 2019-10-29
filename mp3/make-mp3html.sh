#!/bin/sh
cat mp3list.txt | perl -ne'chomp;/^(.*?\d+)\s+(.*)$/; $t=$1;$f=$u=$2;$f=~s/^.*\.com\///;$u=~s/\s/%20/g;print qq($t <a href="$u">$f</a><br />\n)'
