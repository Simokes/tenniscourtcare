import os
import glob
import json
import subprocess

targets = ['lib/presentation/**/*.dart', 'lib/utils/**/*.dart', 'lib/infrastructure/**/*.dart', 'lib/widgets/**/*.dart', 'lib/services/**/*.dart']

unlisted = []
for t in targets:
    files = glob.glob(t, recursive=True)
    for f in files:
        if not f.endswith('.g.dart') and not f.endswith('.freezed.dart') and not os.path.isdir(f):
            unlisted.append(f)

print(f"Found {len(unlisted)} unlisted files")
moves = {}
for f in unlisted:
    filename = os.path.basename(f)
    moves[f] = f"lib/shared/{filename}"

with open('unlisted.json', 'w') as out:
    json.dump(moves, out)
