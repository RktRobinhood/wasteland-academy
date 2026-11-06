# Repository instructions

## Keep GitHub issues current

- Read the relevant issue and its acceptance criteria before working on it. Check existing code, documentation and linked pull requests so already completed work is recognized.
- As part of finishing work, reconcile the related issues. The owner has authorized closing issues when their requirements are verified as resolved; do not ask for routine confirmation each time.
- For implementation delivered through a pull request, include `Closes #<number>` in the PR body only when that PR completes the issue. This lets GitHub close the issue when the PR merges into the default branch. Describe the behavior delivered and the relevant verification.
- For partial work, use `Refs #<number>`, update the remaining work on the issue, and leave it open. Deferred work and work in an unmerged PR are not completed work.
- If an issue is already satisfied on the default branch, close it with a concise comment linking the implementation or documentation and explaining how it meets the request. For a creative-direction issue, durable adopted guidance can satisfy the request; distinguish that from unfinished implementation requirements.
- If the owner confirms an issue has been superseded, close it with a comment linking the replacement plan or issues and identifying any remaining work. Do not treat superseded work as fully implemented.
- Keep umbrella issues open until all their requirements are accounted for. Preserve unresolved decisions and follow-up work explicitly rather than closing an umbrella because one part landed.
- Include issue updates and closures in the final report. Never close issues solely because they are old or have matching keywords.

## Keep completed work on main

- The owner wants pull requests open only while work is actively in flight, under review, or under testing. Do not leave completed PRs idle while they fall behind `main`.
- For authorized implementation work, review the final diff, resolve conflicts while preserving newer changes, run the relevant checks, and merge promptly when ready. Keep failed checks and unresolved requirements visible; do not bypass branch protections or merge unfinished work to reduce the PR count.
- Close duplicate or superseded PRs with a link to the work that replaced them. For a genuine external blocker, record the concrete blocker and next action instead of leaving the status ambiguous.
