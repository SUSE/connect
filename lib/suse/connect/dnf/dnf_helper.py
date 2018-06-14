import json
import argparse

def repos():
    try:
        import dnf
    except ImportError:
        print("This helper is supposed to be run only on Fedora/CentOS derivatives")
        exit(1)

    with dnf.Base() as base:
        base.read_all_repos()
        ary = []
        for alias in base.repos:
            repo = base.repos[alias]
            d = dict()
            d["alias"] = alias
            d["url"] = repo.baseurl
        d["name"] = repo.name
        d["type"] = "rpm-md"
        d["priority"] = repo.priority
        d["enabled"] = repo.enabled
        d["autorefresh"] = True
        d["gpgcheck"] = repo.gpgcheck
        ary.append(d)
        print(json.dumps(ary))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-r', '--repos', action='store_true', help="dump repos in json format")
    args = parser.parse_args()

    if args.repos:
        repos()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
