from PIL import Image
import glob
import math
import os
import sys

def convertImage(filename):
    imgf = Image.open(filename)
    img = imgf.convert("L")
    imgf.close()

    sx = img.size[0]
    sy = img.size[1]

    out = ".db "
    
    for x in range(sx):
        for by in range(math.ceil(sy / 8)):
            bout = "0b"
            for bi in range(8):
                y = by * 8 + bi
                bout += "1" if y < sy and img.getpixel((x,y)) > 127 else "0"
            out += bout + ","

    out = out.rstrip(",") + "\r\n"

    return out

def main():
    for file in glob.glob(os.path.join(sys.argv[1], "*.png")):
        outfile = open(os.path.splitext(file)[0] + ".asm", 'w')
        outfile.write(convertImage(file))
        outfile.close()

     
if __name__ == "__main__":
    main()