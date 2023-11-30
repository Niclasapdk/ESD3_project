#!/usr/bin/env bash

drawios=$(find . -name "*.drawio")
for file in $drawios; do
    rawname="${file%.drawio}"
    echo "$file --> ${rawname}.svg"
    drawio --crop -b 5 -x -o "${rawname}.pdf" "$file"
    inkscape "${rawname}.pdf" -o "${rawname}.svg"
    rm "${rawname}.pdf"
done;
exit

umls=$(find . -name "*.uml")
for file in $umls; do
    newname="${file%.uml}.svg"
    echo "$file --> $newname"
    java -jar ~/build/plantuml/plantuml.jar -tsvg "$file"
done;
