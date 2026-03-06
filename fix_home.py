import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r') as f:
    content = f.read()

# remove unused import
content = content.replace("import 'package:tenniscourtcare/domain/enums/role.dart';\n", "")

with open('lib/features/home/presentation/screens/home_screen.dart', 'w') as f:
    f.write(content)
