#!/usr/bin/env bash

pdfs=$(find . -name "*.pdf")
for file in $pdfs; do
    newname="${file%.pdf}.svg"
    echo "$file --> $newname"
    inkscape "$file" -o "$newname"
done;

umls=$(find . -name "*.uml")
for file in $umls; do
    newname="${file%.uml}.svg"
    echo "$file --> $newname"
    java -jar ~/build/plantuml/plantuml.jar -tsvg "$file"
done;
