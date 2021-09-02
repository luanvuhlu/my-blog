#!/bin/bash

for i in *.webp; do name=`echo "$i" | cut -d'.' -f1`; echo "$name"; convert "$i" "${name}.jpg"; done
