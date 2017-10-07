from PIL import Image
import sys
import os
import math

byteSize = 16
xRegex = "%x"
yRegex = "%y"
bRegex = "%b"

def printUsage():
    print("Usage:")
    print("python " + sys.argv[0] + " <IMG_FILE> <FORMAT>")
    print("Use '" + xRegex + "' and '" + yRegex + "' to format coordinates")
    print("Use '" + bRegex + "' to format byte")

def main():

    if len(sys.argv) != 3:
        print("Wrong argument number")
        printUsage()
        return 2

    filename = sys.argv[1]
    label = sys.argv[2]

    if not os.path.isfile(filename):
        print("Bad file argument")
        printUsage()
        return 2
   
    img = Image.open(filename)
    img = img.convert("L")

    sx = img.size[0]
    sy = img.size[1]

    for x in range(0, sx):
        for by in range(0, math.ceil(sy / byteSize)):
            bout = ""
            for y in range(by * byteSize, (by + 1) * byteSize):
                bout += "1" if y < sy and img.getpixel((x,y)) > 127 else "0"
            out = label.replace(xRegex, str(x)).replace(yRegex, str(by)).replace(bRegex, bout)
            print(out)

    return 0

     
if __name__ == "__main__":
    main()