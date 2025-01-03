#!/bin/bash -

## the image resizer script
## $1 input dir
## $2 output dir
## $3 size, e.g., 1M

# strict error handling
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialized variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value

inDir="$(realpath "$1")"
outDir="$(realpath "$2")"
size="$3"

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We will resize the images from '$inDir' to '$outDir' such that their size does not exceed size '$size'."

cd "$inDir"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We are now in directory '$inDir'."

for imgName in ./*.jpg; do
 imgPath="$(readlink -f "$inDir/$imgName")"
 if [ -f "$imgPath" ]; then
    dn="$outDir/$(basename "$imgPath")"
    if [ -f "$dn" ]; then
        echo "$(date +'%0Y-%0m-%0d %0R:%0S'): '$dn' already exists, skipping."
    else
        echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Now resizing '$imgPath' to '$dn'."
        convert "$imgPath" -define jpeg:extent="$size" "$dn"
    fi
 fi
done

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Done."
