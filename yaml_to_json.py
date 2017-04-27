import yaml, json, sys, argparse

parser = argparse.ArgumentParser(description="Yaml to JSON decoder")
parser.add_argument("--source", type=str, help="Yaml file", required=True)
parser.add_argument("--dest", type=str, help="JSON file", required=True)
args = parser.parse_args()

with open(args.source, 'r') as stream:
    try:
        with open(args.dest, 'w') as outfile:
            json.dump(yaml.load(stream), outfile, indent=4, sort_keys=True)
    except yaml.YAMLError as exc:
        print(exc)
