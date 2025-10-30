---
description: Create descriptive commit message and commit changes in staged files
allowed-tools: [Bash]
---

# Commit Changes

Analyze changes in staged files, create a descriptive commit message following the project's conventions, and commit the changes.

IMPORTANT: do not add unstaged files.

Steps:
1. Run `git status` to see current state
2. Run `git diff` to analyze staged and unstaged changes
3. If there are unstaged changes, ask if need to add them
4. Run `git log --oneline -5` to understand recent commit message patterns
5. Create a descriptive commit message that:
   - Uses emoji prefixes (➕ for features, ✍️ for changes, 🐞 for fixes, etc.)
   - Focuses on "why" rather than "what"
   - Follows existing project patterns
   - Do not include footer "Generated with Claude Code" or any similar
6. Commit the changes
7. Run `git status` to confirm commit succeeded

Execute these git operations to complete the commit process with proper analysis and message formatting.
