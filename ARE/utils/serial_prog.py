
eeprom_start = 0
eeprom_end = 2048
act_write = "w"
act_read = "r"
act_double_suffix = "d"
act_addr_assign = "a"
act_addr_incr = "a+"
ret_ok = 0
ret_err = 1

try:
    import sys
    import time
    import argparse
    import re
    import serial
    import serial.tools.list_ports

except ImportError as err:
    sys.stderr.write("module import error")
    sys.stderr.write("you may need to install '%s' module" % err.name)
    raise SystemExit()

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def parseArgs():

    act_w_pat = re.compile("%s(0x|0b|)[0-9]+[%s]?" % (re.escape(act_write), re.escape(act_double_suffix)))
    act_r_pat = re.compile("%s[%s]?" % (re.escape(act_read), re.escape(act_double_suffix)))
    act_a_pat = re.compile("(%s|%s)[0-9]+" % (re.escape(act_addr_assign), re.escape(act_addr_incr)))

    def checkRegex(value):
        try:
            cval = re.compile(value)
            return cval
        except:
            raise argparse.ArgumentTypeError("'%s' is an invalid port expression" % value)            

    def checkAction(value):
        if act_w_pat.fullmatch(value) is not None:
            double = value.endswith(act_double_suffix)
            try:
                wval = value.lstrip(act_write)
                if double:
                    wval = wval.rstrip(act_double_suffix)
                wvali = int(wval, 0)
            except:
                raise argparse.ArgumentTypeError("'%s' is an invalid integer" % wval)
            if wvali < 0 or wvali >= ((1 << 16) if double else (1 << 8)):
                raise argparse.ArgumentTypeError("'%s' is an invalid %s" % (wval, "word" if double else "byte"))
            def act_f(serial, address, verb):
                serialWrite(serial, address, wvali & 0xFF)
                if double:
                    serialWrite(serial, address + 1, wvali >> 8)
                if verb:
                    print("@%s <-- %s" % (address, wvali))
                return address
            return act_f  
        elif act_r_pat.fullmatch(value) is not None:
            def act_f(serial, address, verb):
                data = serialRead(serial, address)
                if value.endswith(act_double_suffix):
                    data = data | (serialRead(serial, address + 1) << 8)
                if verb:
                    print("@%s = %s" % (address, data))
                else:
                    print(str(data))
                return address
            return act_f
        elif act_a_pat.fullmatch(value) is not None:
            inc = value.startswith(act_addr_incr)
            try:
                aval = value.lstrip(act_addr_incr if inc else act_addr_assign)
                avali = int(aval, 0)
            except:
                raise argparse.ArgumentTypeError("'%s' is an invalid integer" % aval)
            if avali < eeprom_start or avali >= eeprom_end:
                raise argparse.ArgumentTypeError("'%s' is an invalid eeprom address" % aval)
            def act_f(serial, address, verb):
                if inc:
                    address += avali
                    if address >= eeprom_end:
                        raise RuntimeError("address overflow")
                else:
                    address = avali
                return address
            return act_f            
        else:
            raise argparse.ArgumentTypeError("'%s' is an invalid action" % value)                            

    parser = argparse.ArgumentParser()
    parser.add_argument("action", metavar="ACTION", type=checkAction, help="specify next action", nargs="*")
    parser.add_argument("-p", "--port", action="append", type=checkRegex, help="specify port")
    parser.add_argument("-l", "--list", action="store_true", help="print available ports")
    parser.add_argument("-c", "--choose", action="store_true", help="choose first matching port ")
    parser.add_argument("-t", "--test", action="store_true", help="validate command only, do not connect")
    parser.add_argument("-v", "--verb", action="store_true", help="verbose")
    return parser.parse_args()

def matchPort(mports, aports):
    out = []
    for mp in mports:
        for ap in aports:
            if mp.fullmatch(ap.device):
                out += [ap]
    return out

def toByte(num):
    return chr(num)

def serialRead(serial, address):
    serial.write(int.to_bytes(address & 0xFF, length=1, byteorder="little"))
    serial.read()
    serial.write(int.to_bytes(address >> 8, length=1, byteorder="little"))
    data = serial.read()
    if data == b'':
        raise RuntimeError("Read error")
    return int.from_bytes(data, byteorder="little")

def serialWrite(serial, address, data):
    serial.write(int.to_bytes(address & 0xFF, length=1, byteorder="little"))
    serial.read()
    serial.write(int.to_bytes((address >> 8) | (1 << 7), length=1, byteorder="little"))
    serial.read()
    serial.write(int.to_bytes(data, length=1, byteorder="little"))
    serial.read()

def main():
    args = parseArgs()

    aports = serial.tools.list_ports.comports()
    if len(aports) == 0:
        eprint("No port available")
        return ret_err

    if args.list:
        print("Available ports:")
        for ap in aports:
            print(ap.device)
    
    ports = matchPort(args.port if args.port is not None else [re.compile(".*")], aports)
    if len(ports) == 0:
        eprint("No port matching given constraints")
        return ret_err
    
    if len(ports) > 1 and not args.choose:
        eprint("Multiple ports matching given constraints")
        return ret_err

    if not args.test:
        ser = serial.Serial(ports[0].device, 9600, timeout=2)
        ser.read()
        address = 0
        for act in args.action:
            address = act(ser, address, args.verb)
        ser.close()

    return ret_ok

if __name__ == "__main__":
    sys.exit(main())
