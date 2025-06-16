---
applyTo: "**"
textId: "INST-031"
---

## Pre-commit markdown linting workflow

Ensure all markdown files pass linting checks before committing by integrating markdown linting into the development workflow. This maintains consistent documentation quality and prevents formatting issues from entering the repository.

### The principle

All markdown files must pass linting validation before commits are accepted. This ensures consistent formatting, proper structure, and professional documentation quality across the entire project.

### Workflow integration

**Required sequence for all commits:**

1. **Make code/documentation changes**
2. **Run test suite** (if applicable)
3. **Run coverage checks** (if applicable)
4. **Run markdown linting** (mandatory for markdown changes)
5. **Fix any linting issues** before proceeding
6. **Stage changes** (`git add`)
7. **Commit with complete message** (following INST-015)

### OS-specific installation

**macOS (using Homebrew):**

```bash
# Install markdownlint-cli
brew install markdownlint-cli

# Verify installation
markdownlint --version
```

**Linux (using npm):**

```bash
# Install Node.js if not present
sudo apt update && sudo apt install nodejs npm  # Ubuntu/Debian
# or
sudo yum install nodejs npm  # CentOS/RHEL

# Install markdownlint-cli globally
npm install -g markdownlint-cli

# Verify installation
markdownlint --version
```

**Windows (using npm):**

```powershell
# Install Node.js from https://nodejs.org first
# Then install markdownlint-cli globally
npm install -g markdownlint-cli

# Verify installation
markdownlint --version
```

### Running markdown linting

**Lint all markdown files:**

```bash
markdownlint **/*.md
```

**Lint specific directories:**

```bash
markdownlint decisions/*.md
markdownlint .github/instructions/*.md
```

**Lint with auto-fix (when possible):**

```bash
markdownlint --fix **/*.md
```

### Configuration

**Create `.markdownlint.json` in project root:**

```json
{
  "default": true,
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false
  },
  "MD033": false,
  "MD041": false,
  "MD024": {
    "siblings_only": true
  }
}
```

**Configuration explanation:**

- **MD013**: Allow longer lines for code blocks and tables
- **MD033**: Allow inline HTML (for GitHub-specific features)
- **MD041**: Don't require H1 as first line (allows front matter)
- **MD024**: Allow duplicate headers in different sections

### Integration with existing workflow

**For documentation-heavy commits:**

```bash
# 1. Complete your documentation changes
# 2. Run tests if applicable
mix test

# 3. Check coverage if applicable
mix test --cover

# 4. Run markdown linting (NEW STEP)
markdownlint **/*.md

# 5. Fix any linting issues
markdownlint --fix **/*.md

# 6. Verify all issues resolved
markdownlint **/*.md

# 7. Stage and commit
git add .
git commit -m "Update ADR documentation with enhanced analysis

- Expand uncertainty analysis in ADR-087
- Remove MCP integration references across multiple ADRs
- Update strategic focus documentation
- Fix markdown formatting issues"
```

### Common linting issues and fixes

**Line length violations (MD013):**

```markdown
# Bad
This is a very long line that exceeds the configured line length limit and should be broken into multiple lines for better readability.

# Good
This is a very long line that exceeds the configured line length limit
and should be broken into multiple lines for better readability.
```

**Trailing whitespace (MD009):**

```bash
# Auto-fix trailing whitespace
markdownlint --fix **/*.md
```

**Missing blank lines (MD012, MD022):**

```markdown
# Bad
## Header
Content immediately follows

# Good
## Header

Content follows with proper spacing
```

**Inconsistent list formatting (MD004, MD007):**

```markdown
# Bad
- Item 1
* Item 2
  - Nested item

# Good
- Item 1
- Item 2
  - Nested item
```

### Automation integration

**Add to shell profile for convenience:**

```bash
# Add to ~/.zshrc or ~/.bashrc
alias mdlint='markdownlint **/*.md'
alias mdfix='markdownlint --fix **/*.md'
```

**Pre-commit hook (optional):**

```bash
#!/bin/sh
# .git/hooks/pre-commit
markdownlint **/*.md
if [ $? -ne 0 ]; then
    echo "Markdown linting failed. Please fix issues before committing."
    exit 1
fi
```

### Error handling

**When linting fails:**

1. **Review the error output** - markdownlint provides specific line numbers and rule violations
2. **Fix issues manually** or use `--fix` flag for auto-fixable issues
3. **Re-run linting** to verify all issues are resolved
4. **Proceed with commit** only after clean linting results

**Common workflow recovery:**

```bash
# If linting fails after staging
git reset  # Unstage changes
markdownlint --fix **/*.md  # Fix issues
markdownlint **/*.md  # Verify fixes
git add .  # Re-stage
git commit -m "..."  # Proceed with commit
```

### Benefits

- **Consistent formatting:** All markdown files follow the same style guidelines
- **Professional appearance:** Documentation maintains high quality standards
- **Reduced review friction:** Formatting issues are caught before code review
- **Automated quality control:** Linting catches issues humans might miss
- **Better readability:** Consistent formatting improves documentation usability

### Integration with ADR workflow

**When updating ADRs (following INST-004):**

1. **Create or update ADR content**
2. **Run markdown linting on the ADR**
3. **Fix any formatting issues**
4. **Update ADR progress documentation** (INST-026)
5. **Run final linting check**
6. **Commit with complete message** (INST-015)

This ensures all ADR documentation maintains professional quality while supporting the established development workflow.
