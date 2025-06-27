# AST Migrate TODO

## Current Status: Clean Foundation ✅

The ast_migrate application has been cleaned up and simplified to provide a solid foundation for future AST transformation rules.

## What Was Removed

- ❌ All broken transformation rules (7 rules removed)
- ❌ Rule-specific tests that were failing
- ❌ Complex rule discovery and registration logic
- ❌ Hardcoded rule mappings

## What Was Kept

- ✅ Core Git integration (`AstMigrate.Git`)
- ✅ Clean behaviour interface (`AstMigrate.Rules.Behaviour`)
- ✅ Main module with proper API structure
- ✅ Basic test coverage for the foundation
- ✅ Project structure and dependencies

## Current Capabilities

The ast_migrate tool now provides:

1. **Clean API**: `AstMigrate.apply_rule/2` with proper options
2. **Git Integration**: Safe transformations with commit support
3. **Dry Run Mode**: Preview changes before applying
4. **Behaviour Interface**: Clear contract for future rules
5. **Proper Logging**: Structured logging for operations
6. **Error Handling**: Graceful failure modes

## Future Development

When transformation rules are needed:

1. **Implement the behaviour**: Use `AstMigrate.Rules.Behaviour`
2. **Add proper tests**: Test both transformation logic and edge cases
3. **Register the rule**: Add to the rule discovery mechanism
4. **Validate thoroughly**: Ensure rules work on real codebase patterns

## Benefits of This Approach

- **No broken tools**: Removed unreliable transformation logic
- **Clean foundation**: Ready for properly designed rules
- **Single responsibility**: Each future rule will have a clear purpose
- **Git safety**: All transformations are reversible
- **Professional quality**: Maintains high standards for code tools

The ast_migrate application is now a reliable foundation rather than a collection of broken transformation rules.
