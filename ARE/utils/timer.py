import sys

propf16 = 15625
propf8 = 4000000

def toProp16(ms):
    return round(ms * propf16)

def toProp8(ms):
    return round(ms * propf8)

def toCs(prop):
    if prop < 64:
        return 1
    if prop < 512:
        return 2
    if prop < 4096:
        return 3
    if prop < 16384:
        return 4
    if prop < 65536:
        return 5
    raise ValueError("Too long")

def toTop16(prop, cs):
    if cs == 1:
        return prop << 10
    if cs == 2:
        return prop << 7
    if cs == 3:
        return prop << 4
    if cs == 4:
        return prop << 2
    if cs == 5:
        return prop
    return 0

def toTop8(prop, cs):
    if cs == 1:
        return prop << 2
    if cs == 2:
        return prop >> 1
    if cs == 3:
        return prop >> 4
    if cs == 4:
        return prop >> 6
    if cs == 5:
        return prop >> 8
    return 0
    
ms = float(sys.argv[1]) / 1000
prop = toProp16(ms)
cs = toCs(prop)
top = toTop16(prop, cs)
print("16 bit")
print("prop: " + str(prop) + " cs: " + str(cs) + " top: " + str(top))
prop = toProp8(ms)
cs = toCs(prop)
top = toTop8(prop, cs)
print("8 bit")
print("prop: " + str(prop) + " cs: " + str(cs) + " top: " + str(top))