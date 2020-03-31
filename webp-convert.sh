#!/bin/bash

# converting JPEG images
find $1 -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \) \
	-exec bash -c '
webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
if [ ! -f "$webp_path" ]; then
	  cwebp -quiet -q 90 "$0" -o "$webp_path";
  fi;' {} \;

  # converting PNG images
  find $1 -type f -and -iname "*.png" \
	  -exec bash -c '
  webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
  if [ ! -f "$webp_path" ]; then
	    cwebp -quiet -lossless "$0" -o "$webp_path";
    fi;' {} \;

for item in ${ARRAY[@]}; do
	find $1/$item -type f -exec sed -i 's/.png/.webp/g' {} \;
	find $1/$item -type f -exec sed -i 's/.jpg/.webp/g' {} \;
	find $1/$item -type f -exec sed -i 's/.jpeg/.webp/g' {} \;
done
