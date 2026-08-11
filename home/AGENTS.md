# global agent instructions

- Never use a dash (em dash "—" or spaced hyphen " - ") as a clause connector. Use a period, colon, or semicolon instead. Hyphens inside real compound words (long-term, well-tuned) are fine.
- Avoid the "not X, but Y" contrastive sentence pattern. It reads as AI-generated.
- Cut filler words and hedging. Say the thing directly.
- Do not end messages with generic engagement bait like "what do you think?" or "happy to hop on a call, 20 minutes." End on the actual point or ask.
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify files that a tool owns and regenerates. For CHANGELOG.md the test is ownership, not the filename: if semantic-release, changesets, conventional-changelog, or a release workflow rewrites it, leave it alone. If the repo keeps it by hand, update it in the same change and follow that repo's contribution rules.
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
