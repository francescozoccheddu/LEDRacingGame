import serial
import serial.tools.list_ports
import sys
import getopt
import signal
import os.path

quitting = False

def main():

    def quitByKeyboard(signal, frame):
        print()
        print("Aborted by keyboard")
        print()
        sys.exit(0)

    signal.signal(signal.SIGINT, quitByKeyboard)
    signal.signal(signal.SIGTERM, quitByKeyboard)

    ESCAPE_CHAR = '\\'

    def quote(string):
        return "'" + str(string) + "'"

    print()
    print("######## Python serial reader ##########")
    print("by Francesco Zoccheddu")
    print()
    
    def printUsage():
        print("Usage:")
        print(__file__)
        print("     -h (--help)              Show this message")
        print("     -g (--guide)             Show format string guide")
        print("     -p (--port=) <PORT>      Set port to connect to")
        print("     -f (--format=) <STRING>  Set format string ('" + ESCAPE_CHAR + "c' by default)")
        print("     -b (--baud=) <RATE>      Set baud rate (9600 by default)")
        print("     -l (--list)              List available serial devices")
        return

    def printGuide():
        print("Format string guide:")
        print("     " + ESCAPE_CHAR + "b      Print next byte (eg. '01101000')")
        print("     " + ESCAPE_CHAR + "c      Print next ascii character (eg. 'p')")
        print("     " + ESCAPE_CHAR + "d      Print next 16-bit integer (eg. '2850')")
        print("     " + ESCAPE_CHAR + "e      Interpret next byte as escape char")
        print("     " + ESCAPE_CHAR + "h      Print next byte in hexadecimal base (eg. '7F')")
        print("     " + ESCAPE_CHAR + "i      Print next 8-bit integer (eg. '126')")
        print("     " + ESCAPE_CHAR + "n      New line")
        print("     " + ESCAPE_CHAR + "t      Tabulation")
        print("     " + ESCAPE_CHAR + "q      Ignore next byte")
        return

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hgp:f:o:m:b:l", ["help", "guide", "port=", "format=", "list"])
    except getopt.GetoptError as err:
        print(err)
        print()           
        printUsage()
        print()
        sys.exit(2)

    port = None
    format = ESCAPE_CHAR + "c"
    baud = 9600

    for o, a in opts:
        if o in ("-h", "--help"):
            printUsage()
            print()
        elif o in ("-g", "--guide"):
            printGuide();
            print()
        elif o in ("-p", "--port"):
            ports = serial.tools.list_ports.comports()
            for p in ports:
                if p.device == a:
                    port = a
                    break
            if port == None:
                print("Unavailable port " + quote(a))
                print()
        elif o in ("-f", "--format"):
            format = a
        elif o in ("-b", "--baud"):
            try:
                baud = int(a)
                if not baud > 0:
                    print("Baud rate value must be positive")
                    print()
                    sys.exit(2)
            except ValueError as err:
                print("Error while parsing baud rate value " + quote(a) + ":")
                print(err)
                print()
                sys.exit(2)
        elif o in ("-l", "--list"):
            ports = serial.tools.list_ports.comports()
            if len(ports) > 0:
                print("Available ports:")
                for p in ports:
                    print(p.device + " (" + p.description + ")")
            else:
                print("No available port")
            print()
        else:
            assert False, "unhandled option"

    if port != None:

        global quitting
        buffer = []
        
        def saveAndQuit(signal, frame):
            global quitting
            quitting = True
            return

        signal.signal(signal.SIGINT, saveAndQuit)
        signal.signal(signal.SIGTERM, saveAndQuit)
        
        ser = None

        print("Trying to connect to port " + quote(port))

        try:
            ser = serial.Serial(port, baud, timeout=1)
            print("Connection with port " + quote(port) + " opened")
            print()
        except Exception as err:
            print()
            print("Error while opening connection with port " + quote(port) + ":")
            print(err)
            print()
            quitting = True

        if not quitting:
            print("Data:")

        def byteToInt(byte):
            return int.from_bytes(byte, byteorder='big')

        def intToBinStr(integer):
            return bin(integer).lstrip('0b').zfill(8)

        def printEscape(escape, recursionEnabled):
            if escape == ESCAPE_CHAR:
                sys.stdout.write(ESCAPE_CHAR)
            elif escape == 'c':
                sys.stdout.write(str(chr(byteToInt(ser.read()))))
            elif escape == 'b':
                sys.stdout.write(intToBinStr(byteToInt(ser.read())))
            elif escape == 'e':
                if recursionEnabled:
                    printEscape(str(chr(byteToInt(ser.read()))), False)
                else:
                    sys.stdout.write("<RECURSIVE ESCAPE>")
            elif escape == 'i':
                sys.stdout.write(str(byteToInt(ser.read())))
            elif escape == 'h':
                sys.stdout.write(str(hex(byteToInt(ser.read())).lstrip('0x').zfill(2)))
            elif escape == 'd':
                lsb = byteToInt(ser.read())
                msb = byteToInt(ser.read())
                sys.stdout.write(str((msb << 8) | lsb))
            elif escape == 't':
                sys.stdout.write('\t')
            elif escape == 'n':
                sys.stdout.write('\n')
            elif escape == 'q':
                ser.read()
            else:
                sys.stdout.write("<BAD ESCAPE " + quote(ESCAPE_CHAR + escape) + ">")
            return

        flist = format.split(ESCAPE_CHAR)
        prefix = flist[0]
        flist = flist[1:]
        while not quitting:
            try:
                sys.stdout.write(prefix)
                for token in flist:
                    printEscape(token[0], True)
                    sys.stdout.write(token[1:])
                sys.stdout.flush()
            except Exception as err:
                print()                
                print("Error while reading from port " + quote(port) + ":")
                print(err)
                break

        print()

        if ser != None:
            ser.close()
            print("Connection with port " + quote(port) + " closed")
            print()

    return

if __name__ == "__main__":
    main()
