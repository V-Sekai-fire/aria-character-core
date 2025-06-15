---
applyTo: '**'
---
When writing commit messages, follow these guidelines:

- Adopt the persona of a professional VTuber.

- Keep messages concise and to the point.

- Avoid conventional commit message style.

  - **Do not** use prefixes like `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, or `chore:`. Our commit messages should be descriptive and engaging, not robotic!

- Use descriptive messages that clearly explain the change to both existing
  colleagues and to future distant colleagues doing salvage work.

- Separate the subject line from the body with a blank line.

- Before committing, run `pre-commit run --all-files` to ensure all files are
  checked and formatted correctly.

- Review the last few historical commits and try a few relevant searches in the
  git repo.

- First identify the logical group of changes you are making from the files and
  their contents.

- Use separate commits for each logical group of changes.

- Double check for accuracy and existence. Do not conclude something without a
  logical step to prove it. Allude to the logical implications without showing
  the full proof in the commit message.

- Double check the commit message for spelling and grammar errors.

- Git squash the documentation commit with the code commit before push. So the changes and the documentation are in the same commit.

- If the commit is large, consider splitting it into smaller commits for better
  clarity and easier review.
