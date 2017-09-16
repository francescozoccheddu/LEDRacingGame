import pygame, pygame.sndarray
import numpy
import scipy.signal
import sys

sample_rate = 44100
sampling = 4096

fosc = 16000000
pscl = 256

def play(cy, ms):
    hz = 16000000 / (256 * cy) 
    t = numpy.linspace(0, 1, 500 * 440/hz)
    wave = scipy.signal.square(2 * numpy.pi * 5 * t, duty=.5)
    wave = numpy.resize(wave, (sample_rate,))
    wave = (4096 / 2 * wave.astype(numpy.int16))
    sound = pygame.sndarray.make_sound(wave.astype(int))
    sound.play(-1)
    pygame.time.delay(ms)
    sound.stop()

def main():
    pygame.mixer.init(sample_rate, -16, 1)
    args = sys.argv[1:]
    argi = 0
    while argi < len(args):
        tonenum = int(argi / 2 + 1)

        argcy = args[argi]
        if argcy == "mute":
            cy = None
        else:
            if not argcy.endswith("cy"):
                raise ValueError("Missing cycles argument for tone " + str(tonenum))
            try:
                cy = int(argcy.rstrip("cy"))
            except ValueError:
                raise ValueError("Bad cycles argument for tone " + str(tonenum))
            if cy < 1 or cy > 255:
                raise ValueError("Bad cycles value for tone " + str(tonenum))

        if len(args) == argi:
            raise ValueError("Missing duration argument for tone " + str(tonenum))
        argms = args[argi + 1]
        if not argms.endswith("ms"):
            raise ValueError("Missing duration argument for tone " + str(tonenum))
        try:
            ms = int(argms.rstrip("ms"))
        except ValueError:
            raise ValueError("Bad duration argument for tone " + str(tonenum))
        if ms < 10 or ms > 1000:
            raise ValueError("Bad duration value for tone " + str(tonenum))
        if cy is None:
            print("Muted for " + str(ms) + "ms")
            pygame.time.delay(ms)
        else:
            print("Playing " + str(cy) + "cy for " + str(ms) + "ms")
            play(cy, ms)
        argi +=2
    print("End")

if __name__ == '__main__':
    main()