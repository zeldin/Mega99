#! /usr/bin/env python

from __future__ import print_function

import argparse
import struct


BIT_PREAMBLE = b'\x00\x09\x0f\xf0\x0f\xf0\x0f\xf0\x0f\xf0\x00\x00\x01'
SYNC = b'\xaa\x99\x55\x66'


def process_packets(c, offs):
    wbstar_found = False
    while offs < len(c):
        word, = struct.unpack_from('>I', c, offs)
        type = word >> 29
        opcode = (word >> 27) & 0x3
        if type == 1:
            address = (word >> 13) & 0x1F
            word_count = word & 0x7FF
        elif type == 2:
            word_count = word & 0x07FFFFFF
        else:
            raise Exception("Bad packet type")
        if opcode == 2:  # WRITE
            if address == 0:  # CRC
                if wbstar_found:
                    raise Exception("Found WRITE CRC after WRITE WBSTAR "
                                    "but before RCRC, CRC needs updating!")
            elif address == 4:  # CMD
                if (c[offs+7] & 0x1f) == 7:  # RCRC
                    if wbstar_found:
                        return
            elif address == 16:  # WBSTAR
                wbstar_found = True
                print("Found WRITE WBSTAR at 0x%x" % (offs,))
                for i in range(0, 4*(1+word_count), 4):
                    struct.pack_into(">I", c, offs+i, 0x20000000)  # NOOP
        offs = offs + 4*(1+word_count)


def process_configuration(c):
    if len(c) < len(BIT_PREAMBLE) or c[:len(BIT_PREAMBLE)] != BIT_PREAMBLE:
        raise Exception("Not a bit file")
    offs = len(BIT_PREAMBLE)
    while offs + 3 <= len(c):
        item_type, item_length = struct.unpack_from('>BH', c, offset=offs)
        if item_type == 0xff:
            break
        offs = offs + 3 + item_length
    while offs < len(c):
        if c[offs:offs+len(SYNC)] == SYNC:
            break
        offs = offs + 1
    if offs >= len(c):
        raise Exception("Sync not found")
    process_packets(c, offs+4)


def main():
    parser = argparse.ArgumentParser(
        description="Remove the write to WBSTAR from a bitstream file")
    parser.add_argument(
        "input", metavar="INPUT", type=argparse.FileType('rb'),
        help="filename for reading bitstream"
    )
    parser.add_argument(
        "output", metavar="OUTPUT", type=str,
        help="filename for writing fixed bitstream"
    )
    args = parser.parse_args()
    configuration = bytearray(args.input.read())
    process_configuration(configuration)
    with open(args.output, 'wb') as f:
        f.write(configuration)


if __name__ == "__main__":
    main()
