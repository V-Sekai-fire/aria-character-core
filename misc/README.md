# Misc Folder

This folder contains backup copies of important scripts and utilities for the Aria character system.

## Contents

### post-commit

Backup copy of the git post-commit hook that provides a regular "clock tick" for Aria's commentary randomness system. This hook:

- Updates the commentary state file `.git/info/aria_commentary_state` on each commit
- Increments the accumulated probability by +3 points per commit
- Tracks git commits in the current session
- Provides timing regularity for the commentary system even when cron jobs are unavailable

**Installation Instructions:**
If you need to restore this hook, copy it to `.git/hooks/post-commit` and make it executable:

```bash
cp misc/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

The hook is automatically installed and working in the current repository.
