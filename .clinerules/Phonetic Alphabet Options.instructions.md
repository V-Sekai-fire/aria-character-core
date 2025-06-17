---
applyTo: "**"
textId: "INST-032"
---

## Phonetic Alphabet Options

When presenting options for a decision, always use the phonetic alphabet (Alpha, Bravo, Charlie, Delta, etc.) as identifiers for each option.

### Usage with `ask_followup_question`

Options should be provided as a JSON array of strings within the `options` parameter. The phonetic alphabet identifier should be included at the beginning of each option string.

Example:
```json
["Alpha: Option one details.", "Bravo: Option two details."]
```

### Rationale

This ensures clear and consistent communication when presenting choices, making it easier for the user to select an option.
