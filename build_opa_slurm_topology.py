import argparse
import fileinput

from hostlist import collect_hostlist
from collections import defaultdict


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="Build Slurm topology file"
                                     "from the output of opaextractsellinks.")
    parser.add_argument(
            "-w", action='store', dest='node_filter',
            help="Prefix of compute nodes names.",
            default="")
    parser.add_argument(
            "-f", action='store', dest='file',
            help="Name of the file to parse. If not specified, STDIN is used.",
            default="-")
    args = parser.parse_args()

    cables = defaultdict(dict)
    leaves = defaultdict(set)
    spines = defaultdict(set)

    for line in fileinput.input(args.file):
        line = line.strip()

        _, port1, type1, name1, _, port2, type2, name2 = line.split(';')

        if type1 == 'FI':
            name1 = name1.split(" ")[0]
            if type2 == 'SW':
                cables[name2].update({port2: (name1, port1)})
                leaves[name2].add(name1)
        else:
            cables[name1].update({port1: (name2, port2)})
            spines[name1].add(name2)

    for switch, nodes in leaves.items():
        nodenames = filter(lambda x: args.node_filter in x, nodes)
        nodenames = collect_hostlist(nodenames)
        print "SwitchName=%s Nodes=%s" % (switch, nodenames)
    for switch, nodes in spines.items():
        print "SwitchName=%s Switches=%s" % (switch, ",".join(nodes))
