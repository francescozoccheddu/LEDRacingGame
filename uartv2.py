import sys
import argparse
import serial
import serial.tools.list_ports

class SerialStream:
    def __init__(self):
        self.ptr = 0

    def read(self, ser):
        byte = ser.peek(self.ptr)
        self.ptr += 1
        return byte

    def trim(self, index):
        self.ptr -= index

    def getIndex(self):
        return self.ptr

class SerialWrapper:
    def __init__(self, port, baudrate, bytesize, parity, stopbits, timeout, swflowctl, rtscts, dsrdtr):
        self.ser = serial.Serial(port, baudrate, bytesize, parity, stopbits, timeout, swflowctl, rtscts, dsrdtr)
        self.buf = []

    def push(self):
        byte = self.ser.read()
        self.buf += [byte]

    def peek(self, index):
        while index >= len(self.buf):
            self.push()
        return self.buf[index]

    def pop(self, count):
        self.buf = self.buf[count:]

    def close(self):
        if (self.ser is not None):
            self.ser.close()
            self.ser = None
            return True
        return False

class EscapeHandler:
    def __init__(self, char, processFunc):
        self.char = char
        self.processFunc = processFunc

    def process(self, stream, session):
        return self.processFunc(stream, session)

    def getChar(self):
        return self.char

def proc(stream, session):
    return str(session.byteToInt(stream.read(session.ser)))

class Session:

    escapeHandlers = [EscapeHandler("c", proc)]    

    def __init__(self, ser, escape, byteorder, formats):
        self.formats = formats
        self.ser = ser
        self.escape = escape
        self.byteorder = byteorder
        self.streams = []
        for f in formats:
            stream = SerialStream()
            self.streams += [stream]

    def byteToInt(self, byte):
        return int.from_bytes(byte, byteorder=self.byteorder)

    def processEscape(self, escape, stream):
        for eh in Session.escapeHandlers:
            if eh.getChar() == escape:
                return eh.process(stream, self)
        return "<BADESC>"

    def read(self):
        buf = ""
        for f, s in zip(self.formats, self.streams):
            toks = f.split(self.escape)
            buf += toks[0]
            toks = toks[1:]
            for t in toks:
                if len(t) > 0:
                    buf += self.processEscape(t[0], s)
                    buf += t[1:]
                else:
                    buf += self.processEscape(self.escape, s)
        minInd = None
        for s in self.streams:
            if minInd is None or minInd > s.getIndex():
                minInd = s.getIndex()
        for s in self.streams:
            s.trim(minInd)
        self.ser.pop(minInd)
        return buf
                
                
def qt(msg):
    return "'" + str(msg) + "'"

def parseArgs():
    
    def checkPositive(value):
        ivalue = int(value)
        if ivalue <= 0:
            raise argparse.ArgumentTypeError("%s is an invalid positive int value" % value)
        return ivalue

    def checkChar(value):
        svalue = str(value)
        if len(svalue) != 1:
            raise argparse.ArgumentTypeError("%s is an invalid char value" % value)
        return svalue
    
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    #Output group
    oGroup = parser.add_argument_group("output file settings")
    #File
    oGroup.add_argument("-of", "--ofile", type=argparse.FileType('w'), action="append", help="output to file")
    #Char limit
    default = 65535
    oGroup.add_argument("-om", "--omax", type=checkPositive, default=default, help="output to file characters limit")

    #Format group
    fGroup = parser.add_argument_group("format settings")    
    #Format string
    fGroup.add_argument("-f", "--format", type=str, action='append', help="custom format strings")
    #Escape char
    default = "\\"
    fGroup.add_argument("-e", "--escape", type=checkChar, default=default, help="format escape char")
    #Escape char
    default = "big"
    choices = "big", "little"
    fGroup.add_argument("-bo", "--byteorder", type=str, default=default, choices=choices, help="format byte order")
    #Help
    fGroup.add_argument("-fh", "--fhelp", action="store_true", help="show format help message")

    #Connection group
    cGroup = parser.add_argument_group("connection settings")
    #List
    cGroup.add_argument("-l", "--list", action="store_true", help="list available ports")    
    #Port
    cGroup.add_argument("-p", "--port", type=str, help="port to connect to")
    #Baud rate
    default = 9600
    cGroup.add_argument("-b", "--baudrate", type=checkPositive, default=default, help="set baud rate")
    #Byte size
    default = 8
    choices = [5, 6, 7, 8]
    cGroup.add_argument("-bs", "--bytesize", type=int, choices=choices, default=default, help="set byte size")    
    #Parity bits
    default = "NONE"
    choices = ["NONE", "EVEN", "ODD", "SPACE", "MARK"]
    cGroup.add_argument("-pb", "--parbits", choices=choices, default=default, help="set parity bits")
    #Stop bits
    default = "ONE"
    choices = ["ONE", "ONE_POINT_FIVE", "TWO"]
    cGroup.add_argument("-sb", "--stopbits", choices=choices, default=default, help="set stop bits")
    #Timeout
    default = 1
    cGroup.add_argument("-t", "--timeout", type=checkPositive, default=default, help="set timeout")
    #Software flow control 
    cGroup.add_argument("-sfc", "--swfctl", action="store_true", help="enable software flow control")
    #RTS/CTS
    cGroup.add_argument("-rc", "--rtscts", action="store_true", help="enable RTS/CTS")
    #DSR/DTR
    cGroup.add_argument("-dd", "--dsrdtr", action="store_true", help="enable DSR/DTR")
    return parser.parse_args()

def main():
    print()
    print("Serial monitor")
    print("Copyright (c) 2017 Francesco Zoccheddu")
    print()
    args = parseArgs()
    print(args.port)

if __name__ == "__main__":
    main()