import sys
import argparse
import serial
import serial.tools.list_ports

class SerialStream:
    def __init__(self, port, baudrate, bytesize, parity, stopbits, timeout, swflowctl, rtscts, dsrdtr):
        

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
    oGroup.add_argument("-om", "--olimit", type=checkPositive, default=default, help="output to file characters limit")

    #Format group
    fGroup = parser.add_argument_group("format settings")    
    #Format string
    fGroup.add_argument("-fs", "--formats", type=str, action='append', help="custom format strings")
    #Escape char
    default = "\\"
    fGroup.add_argument("-fe", "--escapec", type=checkChar, default=default, help="format escape char")
    #Help
    fGroup.add_argument("-fh", "--fhelp", action="store_true", help="show format help message")

    #Connection group
    cGroup = parser.add_argument_group("connection settings")
    #List
    cGroup.add_argument("-l", "--list", action="store_true", help="list available ports")    
    #Port
    cGroup.add_argument("-cp", "--port", type=str, help="port to connect to")
    #Baud rate
    default = 9600
    cGroup.add_argument("-cbr", "--baudrate", type=checkPositive, default=default, help="set baud rate")
    #Byte size
    default = 8
    choices = [5, 6, 7, 8]
    cGroup.add_argument("-cbs", "--bytesize", type=int, choices=choices, default=default, help="set byte size")    
    #Parity bits
    default = "NONE"
    choices = ["NONE", "EVEN", "ODD", "SPACE", "MARK"]
    cGroup.add_argument("-cpb", "--parbits", choices=choices, default=default, help="set parity bits")
    #Stop bits
    default = "ONE"
    choices = ["ONE", "ONE_POINT_FIVE", "TWO"]
    cGroup.add_argument("-csb", "--stopbits", choices=choices, default=default, help="set stop bits")
    #Timeout
    default = 1
    cGroup.add_argument("-ct", "--timeout", type=checkPositive, default=default, help="set timeout")
    #Software flow control 
    cGroup.add_argument("-csfc", "--swfctl", action="store_true", help="enable software flow control")
    #RTS/CTS
    cGroup.add_argument("-crc", "--rtscts", action="store_true", help="enable RTS/CTS")
    #DSR/DTR
    cGroup.add_argument("-cdd", "--dsrdtr", action="store_true", help="enable DSR/DTR")
    print(parser.parse_args())

def main():
    print()
    print("Serial monitor")
    print("Copyright (c) 2017 Francesco Zoccheddu")
    print()
    parseArgs()

if __name__ == "__main__":
    main()