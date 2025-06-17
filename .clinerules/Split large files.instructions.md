---
applyTo: "**"
textId: "INST-009"
---

## Split large files

When a code file becomes too large, it should be split into smaller, more manageable logical units that each serve a specific purpose.

### The principle

Large files violate the single responsibility principle and become difficult to maintain. Split them into focused, logical units.

### Implementation approach

1. **Back up or disable the original file:**
   - **Backing up**: Rename with `.bak` extension (already in `.gitignore`) for complete replacement
   - **Disabling**: Rename with `.disabled` extension to preserve for reference
2. **Identify logical units** and create stubs with type annotations
3. **Create new files** for each logical unit  
4. **Update the original file** to reference the new files
5. **Test the changes** to ensure everything works as expected
6. **Remove or finalize the original file** based on your backup choice
7. **Commit the changes** with a descriptive message
8. **Verify the changes** by testing and compiling again
9. **Document the changes** in relevant documentation files
10. **Commit the documentation changes**

### Benefits

- **Better maintainability:** Each file has a clear, focused purpose
- **Easier debugging:** Problems are isolated to specific functional areas  
- **Improved readability:** Smaller files are easier to understand
- **Better testing:** Individual units can be tested independently

This approach aligns with the targeted solutions principle - each file should solve one specific problem or provide one logical unit of functionality.
