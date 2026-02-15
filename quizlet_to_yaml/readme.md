# Quizlet to YAML

Not much here. Just a basic converter. Converts quizlet data (the WOTD set) to YAML format.
Not required unless you want to put new data in.

## Putting new data in the questions

If you want to put a new dataset in the questions, follow these steps.

1. Make sure your data is in the right format
- Tab between term and definition
- Newline between terms
- Example:
```txt
term    definition
other term  other definition
```
2. Put your data in a file (or you could just copy it and not supply a file)
3. Run python
```sh
python3 quizlet_to_yaml.py --file filename.txt
# or if you want to supply from clipboard
python3 quizlet_to_yaml.py --paste
```