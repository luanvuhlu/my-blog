#!/bin/bash

for i in assets/static/img/covers/*.webp; do name=`echo "$i" | cut -d'.' -f1`; echo "$name"; convert "$i" "${name}.jpg"; done
