# no-provider MR Provider

Use this provider when no remote MR/PR platform is available, or when the user pasted review comments directly into the conversation.

## Provider metadata

- `provider_name`: `no-provider`
- `environment`: local / pasted comments
- `auth_check`: none
- `write_capability_rule`: remote writes unsupported

## Supported capabilities

| Capability | Support |
|---|---|
| `repo_identity` | local git only, if a repo is present |
| `branch_identity` | local git only, if a repo is present |
| `protected_branch_check` | local branch-name blacklist only; no remote protected list |
| `mr_lookup_by_branch` | unsupported |
| `mr_get` | unsupported |
| `comment_list` | supported only from pasted user text |
| `comment_reply` | unsupported |
| `comment_resolve` | unsupported |
| `comment_outdated_detection` | unsupported unless user provided metadata |

## How to use

1. Ask the user to paste the review comments or provide a local file containing them.
2. Parse each comment into the normalized fields where possible:
   - `thread_id`: synthesize stable local IDs such as `local-001`
   - `path`
   - `line`
   - `author`
   - `body`
   - `state`: `unknown`
   - `is_outdated`: `unknown`
3. Run the main classification and Stage 4.5 alignment table normally.
4. Local code edits may happen after user alignment, subject to the same protected-branch and minimal-diff rules.
5. Remote replies/resolves must be reported as `not_supported_by_provider`.

## Report requirements

When using `no-provider`, final report must include:

- `Provider: no-provider`
- Source of comments: pasted text / local file path / user summary
- Remote actions not executed:
  - replies: `not_supported_by_provider`
  - resolves: `not_supported_by_provider`
- Any uncertainty caused by missing MR metadata, especially outdated state and author type.

## Safety defaults

- Unknown author type defaults to human reviewer.
- Unknown outdated state is treated as open/non-outdated for classification, but remote actions are unsupported anyway.
- Do not claim a comment was replied/resolved remotely.
