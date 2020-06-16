#!/usr/bin/env python


import argparse

import argparse

def parse_cli_arguments():
    parser = argparse.ArgumentParser(
        prog="jeodpp_batch_runner",
        description="Run estation procedures on JEO-Batch"
    )
    parser.add_argument(
        "my_integer",
        type=int,
        help="An integer"
    )
    parser.add_argument(
        "my_float",
        type=float,
        help="A float"
    )
    parser.add_argument(
        "my_string",
        default='yo!',
        help="A string"
    )

    args = parser.parse_args()
    return args


def main(args):
    print(args)
    print("The answer is 42")


if __name__ == "__main__":
    args = parse_cli_arguments()
    main(args=args)
