with open('test/models/models_test.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:tenniscourtcare/data/models/terrain_model.dart';", "import 'package:tenniscourtcare/data/mappers/terrain_model.dart';")
with open('test/models/models_test.dart', 'w') as f:
    f.write(content)
