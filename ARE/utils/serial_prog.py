
eeprom_start = 0
eeprom_end = 2048
act_write = "w"
act_read = "r"
act_double_suffix = "d"
act_addr_assign = "a"
act_addr_incr = "a+"

try:
    import sys
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
        elif act_r_pat.fullmatch(value) is not None:
            double = value.endswith(act_double_suffix)
        elif act_a_pat.fullmatch(value) is not None:
            inc = value.startswith(act_addr_incr)
            try:
                aval = value.lstrip(act_addr_incr if inc else act_addr_assign)
                avali = int(aval, 0)
            except:
                raise argparse.ArgumentTypeError("'%s' is an invalid integer" % aval)
            if avali < eeprom_start or avali >= eeprom_end:
                raise argparse.ArgumentTypeError("'%s' is an invalid eeprom address" % aval)
        else:
            raise argparse.ArgumentTypeError("'%s' is an invalid action" % value)                            
        return value

    parser = argparse.ArgumentParser()
    parser.add_argument("ACTION", type=checkAction, help="specify next action", nargs="+")
    parser.add_argument("-p", "--port", action="append", type=checkRegex, help="specify port")
    parser.add_argument("-v", "--verb", action="store_true", help="print every action")
    parser.add_argument("-l", "--list", action="store_true", help="print available ports")
    return parser.parse_args()

def matchPort(mports, aports):
    for mp in mports:
        for ap in aports:
            if mp.fullmatch(ap.device):
                return ap
    return None

def main():
    args = parseArgs()

    aports = serial.tools.list_ports.comports()
    if len(aports) == 0:
        eprint("No port available")
        return

    if args.list:
        print("Available ports:")
        for ap in aports:
            print(ap.device)
        print()
    
    port = matchPort(args.port if len(args.port) > 0 else [re.compile(".*")], aports)
    if port is None:
        eprint("No port matching given constraints")
        return

    return

if __name__ == "__main__":
    main()
