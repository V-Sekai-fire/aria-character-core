# ADR-001: Serial Number Factory Code Cleanup and Manufacturer Conflict Avoidance

<!-- @adr_serial R25W0014110 -->

## Status

Completed (June 27, 2025)

## Context

The AriaSerial system uses single-letter factory codes in serial numbers to identify the organization or project that created a migration tool. However, the current factory codes create conflicts with major technology manufacturers:

**Current problematic codes:**

- `A`: Aria Character Core (conflicts with Apple)
- `F`: Already taken (conflicts with Foxconn)
- `V`: V-Sekai (conflicts with various manufacturers)
- `G`: Godot Projects (conflicts with Google potentially)
- `C`: Community Projects (conflicts with various manufacturers)
- `E`: Ernest's Personal Projects (generic conflict potential)
- `S`: Would conflict with Samsung

**Additional requirements:**

- Need to add support for Fire's Personal Projects
- Maintain existing R-series for Aria Character Core
- Avoid confusion with real-world manufacturer serial numbers

## Decision

**Remove conflicting factory codes:**

- Remove `A`, `V`, `G`, `C`, `E` from all decode_factory functions
- These codes create potential confusion with major manufacturers

**Standardize on conflict-free codes:**

- Keep `R`: Aria Character Core (R-series) - minimal manufacturer conflict
- Add `Q`: Fire's Personal Projects - rarely used by major manufacturers

**Rationale for Q selection:**

- Q is rarely used by major technology manufacturers
- Distinctive and memorable
- Fits within existing allowed character set
- Avoids common manufacturer prefixes (A=Apple, F=Foxconn, S=Samsung, etc.)

## Implementation Plan

- [x] Create apps/aria_serial/decisions/ directory
- [x] Document this ADR with rationale
- [x] Update registry.ex factory decode functions
- [x] Update create_serial.ex factory decode functions
- [x] Update decode_serial.ex factory decode functions (uses registry)
- [x] Fix unused variable warning in create_serial.ex
- [x] Add support for 11-character legacy serials in decode_v1
- [x] Debug decode function hanging issue (resolved module conflict)
- [x] Test the changes with existing serial numbers
- [x] Verify R25W001GLTL still decodes correctly
- [x] Remove duplicate registry module (Mix.Tasks.Serial.Registry)
- [x] Fix module conflicts between decode.ex and decode_serial.ex
- [x] Update all Mix tasks to use AriaSerial.Registry consistently

## Consequences

**Positive:**

- Eliminates confusion with major manufacturer serial numbers
- Cleaner, more focused factory code system
- Better professional appearance
- Reduced maintenance burden
- Clear documentation of decision rationale

**Negative:**

- Breaking change for any external systems expecting old codes
- Need to update documentation and examples

**Risk Mitigation:**

- Existing registered serial numbers (R25W001GLTL series) remain valid
- Only affects decode_factory display names, not actual serial format
- Changes are backward compatible for R-series codes

## Success Criteria

- All factory decode functions updated consistently
- Existing R-series serial numbers continue to work
- Q-series ready for Fire's Personal Projects
- No manufacturer conflict warnings
- Clean compilation with no unused code warnings

## Related ADRs

None (first ADR for aria_serial app)
