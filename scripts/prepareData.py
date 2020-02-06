#! /usr/bin/env python3

import argparse
import json


def arg_parse():
    opt = argparse.ArgumentParser(description="Prepare JSON to run snakemake_nanometh")
    opt.add_argument(
        '-f',
        '--fastq',
        dest="fastq",
        nargs="+",
        help="Fastqs to take into account when running this pipeline"
    )
    opt.add_argument(
        "-5",
        "--fast5",
        help="Path to fast5",
        dest="fast5"
    )
    opt.add_argument(
        '-r',
        '--reference',
        help="Assembly fasta file",
        dest="reference"
    )
    opt.add_argument(
        "-s",
        "--summary",
        dest="summary",
        help="Sequencing summary file"
    )
    opt.add_argument(
        "-o", 
        "--output",
        dest="out",
        help="Output path (default: current directory)"
    )
    opt.add_argument(
        '--split',
        help="Specify that fastq input are same sample and "\
            "frequency should be computed joined",
        dest="splitted",
        action="store_true",
        default=False
    )

    return opt.parse_args()



def config_maker(args):
    """
    Create configuration to run snakemake_nanometh pipeline
    """

    dico = dict()
    dico['fastq'] = args.fastq
    dico['path_fast5'] = args.fast5
    if args.summary:
        dico['summary'] = args.summary
    else:
        dico['summary'] = False
    dico['splitted'] = args.splitted
    dico['reference'] = args.reference
    if args.out:
        dico['output'] = args.out

    return dico

if __name__ == "__main__":
    args = arg_parse()
    cfg = config_maker(args)
    print(
        json.dumps(
            cfg,
            indent=4
        )
    )
