import sys
import pyperclip

HELP_TEXT = """Usage:
  python3 quizlet_to_yaml.py --file <path>
  python3 quizlet_to_yaml.py --paste

Options:
  --file <path>  Read Quizlet data from a file
  --paste        Read Quizlet data from clipboard
  -h, --help     Show this help message
"""

def args() -> str | None:
    args = sys.argv[1:]
    if not args or "-h" in args or "--help" in args:
        print(HELP_TEXT)
        return None

    if "--file" in args:
        file_index = args.index("--file")
        if file_index + 1 >= len(args):
            print(HELP_TEXT)
            return None
        file_path = args[file_index + 1]
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = f.read()
        except OSError as exc:
            print(f"Failed to read file: {file_path}\n{exc}")
            return None
        
        return data

    if "--paste" in args:
        # get pasteboard contents
        data = pyperclip.paste()
        # TODO: use data to convert Quizlet data
        return data

    print(HELP_TEXT)
    return None

def parse(data: str) -> str:
    entries = []
    for raw_line in data.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if "\t" in line:
            term, definition = line.split("\t", 1)
        else:
            # Fallback: split on two or more spaces
            parts = [p for p in line.split("  ") if p]
            if len(parts) < 2:
                continue
            term, definition = parts[0], "  ".join(parts[1:])
        term = term.strip()
        definition = definition.strip()
        if not term or not definition:
            continue
        entries.append((term, definition))

    lines = []
    for term, definition in entries:
        lines.append(f"- word: {term}")
        lines.append(f"  definition: \"{definition}\"")
        lines.append("  synonyms: []")
        lines.append("  antonyms: []")
    return "\n".join(lines)

def main():
    data = args()

    if data is None:
        return
    output = parse(data)
    if output:
        with open("../assets/wotd.yaml", "w", encoding="utf-8") as f:
            f.write(output)
        print("Wrote to file")

if __name__ == "__main__":
    main()