Excellent! Here's the finalized implementation plan:

## Final Implementation Plan

### Phase 1: Create ADR Serial Generation System

**New Mix Task: `apps/aria_serial/lib/mix/tasks/generate_adr_serial.ex`**

**Core functionality:**

1. **Git history analysis**: Extract creation date for each ADR file
2. **Content-based tool codes**: Generate 4-char hash from ADR title (SHA256 → validate chars → 4 chars)
3. **Week calculation**: Convert creation date to ISO week, fallback to current week (W26)
4. **Serial generation**: Format as `R[YY][W][UUU][HASH]` where UUU is sequence within that week

**Tool code generation algorithm:**

```elixir
def generate_adr_tool_code(title) do
  title
  |> String.downcase()
  |> String.replace(~r/[^a-z0-9]/, "")
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16()
  |> String.slice(0, 4)
  |> ensure_valid_chars()  # Replace forbidden chars (I,O,U,Z) with allowed ones
end
```

### Phase 2: Batch Process All 195 ADRs

**Execution sequence:**

1. **Scan decisions/ directory** for all ADR files
2. **Extract git creation dates** using `git log --follow --format="%ai" --diff-filter=A`
3. **Generate serials** with historical weeks and content-based tool codes
4. **Create mapping file** (`adr_migration_map.json`) for reference tracking
5. **Rename files** to `R[YY]W[UUU][HASH]-original-name.md` format

**Example transformations:**

- `R25W0013716-state-architecture-migration.md` → `R25W001A3F2-state-architecture-migration.md`
- `195-hybrid-planner-execution.md` → `R25W195B7C4-hybrid-planner-execution.md`

### Phase 3: Update All Cross-References

**Reference update patterns:**

- `ADR-001` → `ADR-R25W001A3F2`
- `decisions/001-` → `decisions/R25W001A3F2-`
- `ADR-001:` → `ADR-R25W001A3F2:`
- Any numeric ADR references

**Validation script:**

- Parse all `.md` files in project
- Find ADR reference patterns using regex
- Update using the mapping file
- Verify all references resolve to existing files

### Phase 4: Update ADR Rules

**Modify `.clinerules/Process ADRs.instructions.md`:**

- Require `mix generate.serial.adr` for new ADRs
- Update naming convention examples
- Change cross-reference format guidelines
- Update ADR creation workflow

**New ADR creation workflow:**

1. Create ADR with descriptive filename
2. Run `mix generate.serial.adr --file path/to/new-adr.md`
3. Rename file to include generated serial prefix
4. Use serial-based references in content

### Phase 5: Implementation Steps

**Step 1: Extend aria_serial**

- Add ADR-specific Mix task
- Implement git history analysis
- Add content-based tool code generation
- Add markdown file injection logic

**Step 2: Generate mapping**

- Process all 195 ADRs
- Create comprehensive old→new mapping
- Generate validation report

**Step 3: Execute migration**

- Rename all ADR files
- Update all cross-references
- Update .clinerules documentation
- Commit changes with comprehensive message

**Step 4: Validation**

- Run validation script
- Verify all cross-references work
- Test new ADR creation workflow
- Update any tooling that depends on ADR names

## Ready to Implement

This plan provides:

- ✅ Git history-based backdating with current week fallback
- ✅ Content-based tool codes to avoid aliasing
- ✅ Serial prefix naming: `R25W001HASH-original-name.md`
- ✅ Comprehensive cross-reference updates
- ✅ Validation script for verification
- ✅ Git history as rollback mechanism

The implementation will maintain the industrial-grade serial system while providing proper historical tracking and avoiding naming conflicts.

Ready to proceed? Please toggle to Act mode and I'll implement this system step by step.
