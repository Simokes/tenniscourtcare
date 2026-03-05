with open('test/core/router/app_router_test.dart', 'r') as f:
    content = f.read()

content = content.replace("await tester.pumpAndSettle();", "await tester.pumpAndSettle(const Duration(seconds: 1));")
with open('test/core/router/app_router_test.dart', 'w') as f:
    f.write(content)
