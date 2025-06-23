# Tombstone: aria_png_generator

**Removed:** June 23, 2025  
**Reason:** Extracted to apps/png_generator during module reorganization  
**Migration Path:** Use `apps/png_generator` instead  

## What was removed

- `lib/aria_png_generator/png_generator.ex` - AriaEngine.PngGenerator module

## Where it went

The PNG generation functionality has been moved to:
- **New location:** `apps/png_generator/`
- **Module name:** `PngGenerator` (simplified from `AriaEngine.PngGenerator`)

## Usage

If you need PNG generation functionality:

```elixir
# Old (removed)
AriaEngine.PngGenerator.generate_timeline_png(schedule)

# New (use the app)
PngGenerator.generate_timeline_png(schedule)
```

## Related ADRs

- ADR-150: Extract lib modules to apps
