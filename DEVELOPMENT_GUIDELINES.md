# POS System Development Guidelines

## Quick Reference for Code Quality

### ✅ Do's (Following Our Standards)

#### Async Safety
```dart
// ALWAYS use mounted checks after async operations
await someAsyncOperation();
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
  Navigator.pop(context);
}
```

#### Widget Constructors
```dart
// ALWAYS include super.key
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});
}
```

#### Modern APIs
```dart
// Use withValues() instead of withOpacity()
color: Colors.red.withValues(alpha: 0.3)

// Use initialValue instead of value
DropdownButtonFormField(
  initialValue: selectedValue,
  // ...
)

// Use activeThumbColor instead of activeColor
SwitchListTile(
  activeThumbColor: Colors.orange,
  // ...
)
```

#### Type Safety
```dart
// Prefer non-nullable types when possible
final Map<String, dynamic> data = {}; // Not Map<String, dynamic>?
```

### ❌ Don'ts (Avoid These Patterns)

#### Context Across Async Gaps
```dart
// DON'T do this
await someAsyncOperation();
ScaffoldMessenger.of(context).showSnackBar(...); // Unsafe!

// DO this instead
await someAsyncOperation();
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

#### Deprecated APIs
```dart
// DON'T use deprecated methods
color: Colors.red.withOpacity(0.3) // Deprecated
value: selectedValue // Deprecated
activeColor: Colors.orange // Deprecated

// DO use modern alternatives
color: Colors.red.withValues(alpha: 0.3)
initialValue: selectedValue
activeThumbColor: Colors.orange
```

#### Unnecessary Conversions
```dart
// DON'T add .toList() in spreads
...items.map((item) => Widget(item)).toList() // Unnecessary

// DO this instead
...items.map((item) => Widget(item))
```

### 🔧 Code Quality Checklist

#### Before Commit
- [ ] `flutter analyze` shows zero warnings/errors
- [ ] All async operations have mounted checks
- [ ] Widget constructors have super.key
- [ ] No deprecated APIs used
- [ ] Types are non-nullable where possible

#### Code Review Points
- [ ] Async safety implemented correctly
- [ ] Modern Flutter patterns used
- [ ] Code follows established conventions
- [ ] Performance considerations addressed

### 🚀 Best Practices

#### Performance
- Remove unnecessary .toList() calls in spreads
- Use const constructors where possible
- Avoid unnecessary widget rebuilds

#### Maintainability
- Follow consistent naming conventions
- Use descriptive variable names
- Keep methods focused and small

#### Testing
- Write unit tests for business logic
- Test widget behavior with golden tests
- Verify async operations handle edge cases

### 📱 Flutter Specific Guidelines

#### State Management
- Use setState appropriately
- Consider provider patterns for complex state
- Keep state minimal and focused

#### Widget Organization
- Split large widgets into smaller components
- Use composition over inheritance
- Follow single responsibility principle

#### Asset Management
- Organize assets in appropriate folders
- Use efficient image formats
- Implement lazy loading where needed

### 🔍 Debugging Tips

#### Common Issues
1. **BuildContext across async gaps** - Add mounted checks
2. **Deprecated API warnings** - Update to modern alternatives
3. **Type safety issues** - Make types non-nullable
4. **Performance problems** - Remove unnecessary conversions

#### Analyzer Output
- **Errors:** Must fix before commit
- **Warnings:** Should fix before commit
- **Info:** Consider fixing for best practices

### 📚 Resources

#### Official Documentation
- [Flutter Style Guide](https://flutter.dev/docs/development/tools/formatting)
- [Effective Dart Guide](https://dart.dev/guides/language/effective-dart)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)

#### Internal Resources
- CODE_QUALITY_IMPROVEMENT_REPORT.md - Detailed improvement summary
- Flutter analyzer configuration in analysis_options.yaml
- Team coding standards document

---

**Remember:** Clean code is maintainable code. Follow these guidelines to keep our POS system in excellent condition!
