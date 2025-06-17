---
applyTo: "**"
textId: "INST-007"
---

## Zipfian emoji distribution in commit messages

Apply Zipf's law distribution patterns to emoji usage in commit messages, creating natural frequency patterns that maintain professional appearance while adding personality.

### The principle

Emoji usage should follow a power law distribution where the most common emoji appears frequently, the second most common appears roughly half as often, the third appears one-third as often, and so on. This creates organic, natural-feeling communication patterns.

### Implementation approach

**Before writing commit messages:**

1. **Review recent history:** Run `git log --oneline -20` to analyze the last 20 commits
2. **Count emoji frequency:** Track which emojis have been used and how often
3. **Apply Zipfian distribution:** Follow the natural frequency pattern for emoji selection
4. **Maintain quality threshold:** Never use emojis if they would compromise message clarity

### Zipfian frequency guidelines

**Rank 1 (Most frequent):** 🔧 (Technical work, fixes, implementations)

- **Target frequency:** ~30% of commits with emojis
- **Use for:** Core functionality, major implementations, technical improvements

**Rank 2:** 📋 (Documentation, planning, organization)

- **Target frequency:** ~15% of commits with emojis  
- **Use for:** Documentation updates, ADR work, project organization

**Rank 3:** 🌟 (Achievements, completions, milestones)

- **Target frequency:** ~10% of commits with emojis
- **Use for:** Major completions, successful implementations, milestones

**Rank 4+:** Other contextual emojis (🐛🚀📝⚡️🎯🔍)

- **Target frequency:** ≤7% each of commits with emojis
- **Use sparingly:** Bug fixes, performance, testing, research, etc.

### Distribution rules

**Natural frequency targets:**

- **Overall emoji usage:** 25-35% of all commits (maintaining professional majority)
- **Rank-based selection:** Choose emojis based on current frequency gaps in recent history
- **Avoid clustering:** Don't use emojis in consecutive commits unless different ranks
- **Quality over quantity:** Skip emojis entirely if they don't add meaningful context

### Benefits

- **Natural communication patterns:** Mirrors how humans naturally use language
- **Professional balance:** Maintains appropriate emoji-to-text ratio
- **Consistent personality:** Creates recognizable but not overwhelming patterns
- **Improved readability:** High-frequency emojis become familiar navigation aids

This approach ensures emoji usage feels organic and professional while supporting clear project communication.
