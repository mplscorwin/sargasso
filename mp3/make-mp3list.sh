#!/bin/sh
find ../ -name '*.mp3'  -exec mp3info -p "%m:%s" {} \; -exec echo " {}" \; | perl -pe 's|../|http://|'
