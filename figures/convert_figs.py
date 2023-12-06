#!/usr/bin/env python3
import os
import re
import multiprocessing

def check_extension(path, ext):
    return path.endswith(ext)

def convert_drawio(path):
    if not check_extension(path, ".drawio"):
        print(f"Error: {path} does not have .drawio extension")
        return
    pdf_path = re.sub("\.drawio$", ".pdf", path)
    svg_path = re.sub("\.drawio$", ".svg", path)
    print(f"{path} --> {svg_path}")
    os.system(f'drawio --crop -b 5 -x -o "{pdf_path}" "{path}"')
    os.system(f'inkscape "{pdf_path}" -o "{svg_path}"')
    os.remove(pdf_path)

def convert_uml(path):
    if not check_extension(path, ".uml"):
        print(f"Error: {path} does not have .uml extension")
        return
    svg_path = re.sub("\.uml$", ".svg", path)
    print(f"{path} --> {svg_path}")
    os.system(f'java -jar ~/build/plantuml/plantuml.jar -tsvg "{path}"')

def process_file(file):
    if re.search(r'.drawio$', file):
        convert_drawio(file)
    if re.search(r'.uml$', file):
        convert_uml(file)

def main():
    files = [os.path.join(dp, f) for dp, dn, fn in os.walk(os.path.expanduser(".")) for f in fn]

    with multiprocessing.Pool(processes=8) as pool:
        pool.map(process_file, files)
    
if __name__ == "__main__":
    main()
