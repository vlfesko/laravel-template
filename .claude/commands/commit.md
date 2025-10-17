---
description: Create descriptive commit message and commit changes in staged files
allowed-tools: [Bash]
---

# Commit Changes

Add all untracked files to git staging, analyze changes, create a descriptive commit message following the project's conventions, and commit the changes.

Steps:
1. Run `git status` to see current state
2. Run `git diff` to analyze staged and unstaged changes
3. Run `git log --oneline -5` to understand recent commit message patterns
4. Create a descriptive commit message that:
   - Uses emoji prefixes (➕ for features, ✍️ for changes, 🐞 for fixes, etc.)
   - Focuses on "why" rather than "what"
   - Follows existing project patterns
   - Do not include footer "Generated with Claude Code" or any similar
5. Commit the changes
6. Run `git status` to confirm commit succeeded

Execute these git operations to complete the commit process with proper analysis and message formatting.
