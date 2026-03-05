import glob
import os

# We deleted `lib/data/models/` because the prompt said it was a duplicate of `lib/data/mappers/`.
# However, the database and mappers were importing the files from `lib/data/models/`.
# Let's fix imports in `lib/data/database/app_database.dart`, `lib/data/mappers/*.dart`, and tests.

files = glob.glob('lib/**/*.dart', recursive=True) + glob.glob('test/**/*.dart', recursive=True)

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content
    # Replace package:tenniscourtcare/data/models/* with package:tenniscourtcare/data/mappers/*
    new_content = new_content.replace(
        "import 'package:tenniscourtcare/data/models/",
        "import 'package:tenniscourtcare/data/mappers/"
    )
    # The mappers were actually named *_mapper.dart, but the imports were looking for *_model.dart.
    # We should probably see what mappers are named. Let's just fix the imports if they say model.dart -> mapper.dart.
    # Wait, in the mappers directory, there are the mapper classes. But what about the model classes?
    # Ah, the prompt said "data/models/ duplicates data/mappers/". Wait, were the classes IN the mapper files?

    if new_content != content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)

print("Updated imports for models -> mappers")
