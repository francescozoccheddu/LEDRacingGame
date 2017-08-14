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
        print("     -p (--port=) <PORT>      Set port to connect to")
        print("     -f (--format=) <STRING>  Set format string ('" + ESCAPE_CHAR + "c' by default)")
        print("     -b (--baud=) <RATE>      Set baud rate (9600 by default)")
        print("     -l (--list)              List available serial devices")
        return

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hp:f:o:m:b:l", ["help", "port=", "format=", "list"])
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
            sys.exit(2)
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

        flist = format.split(ESCAPE_CHAR)
        prefix = flist[0]
        flist = flist[1:]
        while not quitting:
            try:
                sys.stdout.write(prefix)
                for tk in flist:
                    escape = tk[0]
                    if escape == ESCAPE_CHAR:
                        sys.stdout.write(ESCAPE_CHAR)
                    elif escape == 'c':
                        sys.stdout.buffer.write(ser.read())
                    elif escape == 'b':
                        sys.stdout.write(bin(int.from_bytes(ser.read(), byteorder='big')).lstrip('0b').zfill(8))
                    elif escape == 'i':
                        sys.stdout.write(str(int.from_bytes(ser.read(), byteorder='big')))
                    elif escape == 'd':
                        lsb = bin(int.from_bytes(ser.read(), byteorder='big')).lstrip('0b').zfill(8)
                        msb = bin(int.from_bytes(ser.read(), byteorder='big')).lstrip('0b').zfill(8)
                        sys.stdout.write(msb + lsb)
                    elif escape == 't':
                        sys.stdout.write('\t')
                    elif escape == 'n':
                        sys.stdout.write('\n')
                    else:
                        sys.stdout.write("<BAD ESCAPE " + quote(ESCAPE_CHAR + escape) + ">")        
                    sys.stdout.write(tk[1:])                
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
