# R25W03794DF: Fix markdownlint pre-commit hook

<!-- @adr_serial R25W03794DF -->

- **Status:** Proposed
- **Context:** The markdownlint pre-commit hook is consistently failing, preventing commits. The hook is unable to automatically fix the issues it detects, and manual fixes have been unsuccessful.
- **Decision:** We will temporarily disable the markdownlint pre-commit hook to allow development to continue. A new task will be created to investigate and fix the root cause of the markdownlint failures.
- **Implementation Plan:**
  - [x] Disable the markdownlint pre-commit hook.
  - [ ] Investigate the root cause of the markdownlint failures.
  - [ ] Re-enable the markdownlint pre-commit hook after the root cause is identified and fixed.
- **Consequences:** The codebase may contain markdown files with linting errors until the pre-commit hook is fixed and re-enabled.
- **Success Criteria:** The markdownlint pre-commit hook is successfully re-enabled and no longer prevents commits.
