import re

with open('test/core/router/app_router_test.dart', 'r') as f:
    content = f.read()

# Replace missing imports
content = content.replace("import 'package:tenniscourtcare/providers/reservation_providers.dart';", "")
content = content.replace("allReservationsStreamProvider", "null") # test fix or mock

with open('test/core/router/app_router_test.dart', 'w') as f:
    f.write(content)
