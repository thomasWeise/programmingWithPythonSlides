#!/bin/bash -

# This script applies the pdfsizeopt compressor to a pdf.
# The pdfsizeopt compressor is open source and available at https://github.com/pts/pdfsizeopt.
# We include it here in a single archive.

# strict error handling
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialized variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory is '$scriptDir'."

currentDir="$(pwd)"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We are working in directory: '$currentDir'."

fileIn="$(readlink -f "$1")"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): The full input document path is '$fileIn'."

fileOut="$2"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We will filter the input document '$fileIn' to '$fileOut'."

tempDir="$(mktemp -d)"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We will use the temporary directory '$tempDir'."

cd "$tempDir"

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Unpacking pdfsizeopt to '$tempDir'."
tar -C "$tempDir" -xf "$scriptDir/pdfsizeopt.tar.xz"
pdfsizeoptdir="$tempDir/pdfsizeopt"
chmod 777 -R "$pdfsizeoptdir"

export PATH="$pdfsizeoptdir:$PATH"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): PATH is now '$PATH'."

pdfsizeopttemp="$pdfsizeoptdir/pdft"
mkdir "$pdfsizeopttemp"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): pdfsizeopt will use temp dir '$pdfsizeopttemp'."

"$pdfsizeoptdir/pdfsizeopt.single" --do-double-check-type1c-output=yes --tmp-dir="$pdfsizeopttemp" "$fileIn" "$fileOut"

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Now deleting temporary directory '$tempDir'."
rm -rf "$tempDir"

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Successfully finished filtering '$fileIn' to '$fileOut using pdfsizeopt."
