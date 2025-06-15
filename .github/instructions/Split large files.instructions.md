---
applyTo: "**"
textId: "INST-009"
---

When a code file becomes too large, it should be split into smaller, more
manageable logical units. Follow these steps:

1. **Back up or disable the original file:**
    - **Backing up**: Rename the file with a `.bak` extension (already in `.gitignore`, so it won't be committed). Use this when the file will be completely replaced and you want a local backup during development.
    - **Disabling**: Rename the file with a `.disabled` extension to keep it in the repository for reference. Use this when you want to preserve the original file for comparison or future reference.
2. **Identify logical units** and create stubs with type annotations.
3. **Create new files** for each logical unit.
4. **Update the original file** to reference the new files.
5. **Test the changes** to ensure everything works as expected.
6. **Remove or finalize the original file** based on your backup/disable choice from step 1.
7. **Commit the changes** with a descriptive message.
8. **Double-check the commit message** for spelling and grammar errors.
9. **Verify the changes** by testing and compiling the code again.
10. **Document the changes** in the relevant documentation files.
11. **Commit the documentation changes.**
