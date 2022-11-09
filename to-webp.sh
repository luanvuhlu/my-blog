#!/bin/bash

echo "converting JPEG images..."
FOLDER="."
find $FOLDER -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \) \
	-exec bash -c '
webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
if [ ! -f "$webp_path" ]; then
	  cwebp -quiet -q 90 "$0" -o "$webp_path";
  fi;' {} \;

echo "converting PNG images..."
  find $FOLDER -type f -and -iname "*.png" \
	  -exec bash -c '
  webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
  if [ ! -f "$webp_path" ]; then
	    cwebp -quiet -lossless "$0" -o "$webp_path";
    fi;' {} \;

echo "Replacing in content files..."
ARRAY=(content)

for item in ${ARRAY[@]}; do
	find $FOLDER/$item -type f -exec sed -i 's/.png/.webp/g' {} \;
	find $FOLDER/$item -type f -exec sed -i 's/.jpg/.webp/g' {} \;
	find $FOLDER/$item -type f -exec sed -i 's/.jpeg/.webp/g' {} \;
done
