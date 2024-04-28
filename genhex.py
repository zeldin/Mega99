#! /usr/bin/env python

from __future__ import print_function

import argparse
import struct
import sys

def make_filename(template, n):
    if '%' in template:
        return template % n
    pos = template.index('.')
    return template[:pos]+str(n)+template[pos:]

def hexify(f):
    while True:
        val = f.read(4)
        if len(val) < 4:
            return
        val, = struct.unpack('>I', val)
        yield '%08x' % val

def main():
    parser = argparse.ArgumentParser(
        description="Convert binary to hex file for Verilog $readmemh")
    parser.add_argument(
        "--output", "-o", metavar="HEXFILE",
        help="filename of target hex file"
    )
    parser.add_argument(
        "--num", "-n", type=int, default=1,
        help="number of output files to generate"
    )
    parser.add_argument(
        "input", metavar="BINFILE",
        help="binary file to convert"
    )
    args = parser.parse_args()
    if args.num > 1:
        if args.output is None:
            raise ValueError("Can't use -n without -o")
        filenames = [make_filename(args.output, n) for n in range(args.num)]
    else:
        filenames = None if args.output is None else [args.output]
    cnt = 0
    chunk = 8 // args.num
    with open(args.input, 'rb') as f:
        dest = ([sys.stdout] if filenames is None else
                [open(fn, 'w') for fn in filenames])
        for v in hexify(f):
            for i, d in enumerate(dest):
                print(" "+v[i*chunk:(i+1)*chunk], file=d, end='')
            cnt = cnt + 1
            if cnt == 4:
                for d in dest:
                    print("", file=d)
                cnt = 0
        if cnt != 0:
            for d in dest:
                print("", file=d)
        if filenames is not None:
            for d in dest:
                d.close()

if __name__ == "__main__":
    main()
