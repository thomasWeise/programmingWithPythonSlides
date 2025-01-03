#!/bin/bash

# Make a single slide.

# strict error handling
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialized variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Welcome to the book building script."

currentDir="$(pwd)"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We are working in directory: '$currentDir'."
scriptDir="$currentDir/shared/scripts"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): The script directory is '$scriptDir'."

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We setup a virtual environment in a temp directory."
venvDir="$(mktemp -d)"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Got temp dir '$venvDir', now creating environment in it."
python3 -m venv --upgrade-deps --copies "$venvDir"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Activating virtual environment in '$venvDir'."
source "$venvDir/bin/activate"
export PYTHON_INTERPRETER="$venvDir/bin/python3"
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Setting python interpreter to '$PYTHON_INTERPRETER'."
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We install all required Python packages from requirements.txt to virtual environment in '$venvDir'."
"$PYTHON_INTERPRETER" -m pip install --no-input --timeout 360 --retries 100 -r requirements.txt
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Finished installing the requirements, now printing all installed packages."
pip freeze
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Finished printing all installed packages."

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We now build the slide."

slidesDir="$currentDir/slides"
dirName="$1"
lastLatexGit=""
theDir="$slidesDir/$dirName"
if [ -d "$theDir" ]; then        
    docName="$dirName.tex"
    if [ -f "$theDir/$docName" ]; then
        echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Found directory '$theDir' with document '$docName'."
        
        curDirGit="$theDir/__git__"
        rm -rf "$curDirGit"
        if [ -n "$lastLatexGit" ]; then
            mv "$lastLatexGit" "$theDir"
            lastLatexGit=""
        fi
        
        cd "$theDir"
        "$scriptDir/pdflatex.sh" "$docName"

        if [ -d "$curDirGit" ]; then
            echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Git directory is $curDirGit."
            lastLatexGit="$(realpath "$curDirGit")"
            echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Canonicalized git directory is $lastLatexGit."
        fi
        cd "$currentDir"
    else
        echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Error! Found directory '$theDir', but it does not contain a corresponding LaTeX document."
    fi
else
    echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Error! Directory '$dirName' does not exist!"
fi

if [ -d "$lastLatexGit" ]; then
    echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Cleaning up '$lastLatexGit'."
    rm -rf "$lastLatexGit"
fi

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Deactivating virtual environment."
deactivate
echo "$(date +'%0Y-%0m-%0d %0R:%0S'): Deleting virtual environment."
rm -rf "$venvDir"

echo "$(date +'%0Y-%0m-%0d %0R:%0S'): We have finished the slide building process."
evince "$theDir/$dirName.pdf"
