# MR Provider Contract

`fix-mr-comments` is a review-comment handling workflow. A provider is the backend used to query and mutate MR/PR review state in a specific environment.

The main skill owns classification, risk judgment, user alignment, local code edits, and reporting. Providers only define how to access platform data and how to perform approved remote actions.

## Provider Selection

Choose exactly one provider per run:

1. User-specified provider, if present.
2. Environment default when available. In ByteDance internal repos targeting `code.byted.org`, this is usually `bytedcli`.
3. `no-provider` fallback when no MR provider is available or the user pasted comments manually.

Write the selected provider into the final report.

## Provider Metadata

Every provider reference should define:

- `provider_name`
- `environment`
- `auth_check`
- `capabilities`
- `write_capability_rule`
- `failure_handling`

## Capability Contract

| Capability | Purpose | Typical inputs | Output expected by main skill |
|---|---|---|---|
| `repo_identity` | Identify repo slug/name/url | repo root | provider repo id + display URL |
| `branch_identity` | Identify current source branch | repo root | branch name + upstream/push target |
| `protected_branch_check` | Check whether branch is protected | repo id, branch | protected yes/no + evidence |
| `mr_lookup_by_branch` | Find open MR/PR for source branch | repo id, source branch | candidate MR list |
| `mr_get` | Fetch MR/PR details | repo id, mr id | source branch, target branch, URL, state |
| `comment_list` | List review threads/comments | repo id, mr id | normalized thread/comment list |
| `comment_reply` | Reply to a thread/comment | repo id, mr id, thread id, body | reply success + persisted evidence |
| `comment_resolve` | Resolve/close a thread | repo id, mr id, thread id | resolve success + persisted evidence |
| `comment_outdated_detection` | Determine if thread is outdated | thread metadata, current diff | outdated yes/no/unknown + evidence |
| `provider_discovery` | Discover provider-specific commands/capabilities | user/platform terms | discovered capability + safety classification |

Providers may expose additional capabilities. The main skill must record provider-specific gaps instead of inventing behavior.

## Normalized Comment Fields

Providers should map platform-specific comment data into:

- `thread_id`
- `comment_id` when available
- `path`
- `line` or range when available
- `author`
- `author_type_hint` when available
- `state`: `open | resolved | unknown`
- `body`
- `replies`
- `created_at` / `updated_at`
- `commit_id` or diff position metadata when available
- `is_outdated`: `true | false | unknown`
- `url` when available

If a field is unavailable, set it to `unknown` and let the main skill make the conservative choice.

## Write Capability Rule

Remote writes are allowed only after the Stage 4.5 user alignment gate:

- `comment_reply` is a write.
- `comment_resolve` is a write.
- provider-specific approve/merge/push/status APIs are forbidden in this skill unless explicitly added to the contract later.

Before any provider write:

1. Confirm Stage 4.5 final plan explicitly marks that action.
2. Re-run protected branch checks from the main skill.
3. Use provider-native safe argument passing. Do not shell-concatenate user text.
4. After the write, read back the thread/comment when supported.

If a provider cannot prove a write happened, report it as unverified.

## Failure Handling

Classify provider failures before acting:

| Failure | Examples | Handling |
|---|---|---|
| Auth failure | 401, token expired, not logged in | Stop; ask user to authenticate manually; do not invent tokens |
| Tool/version failure | unknown command, update required | Stop or skip provider path; ask user to update manually |
| Permission failure | permission denied, missing scope | Stop that remote action; report permission gap |
| Capability missing | provider has no resolve API | Mark action `not_supported_by_provider` |
| Data ambiguity | multiple MRs, branch mismatch, unknown outdated state | Stop and ask user or choose conservative default |
| Write confirmation required | provider requires explicit yes/confirm | Ask user; never bypass silently |

Provider failures are environment/platform facts, not review-comment conclusions.

## Provider Discovery

Use discovery when:

- the user names a provider/platform not covered by references;
- a provider reference is missing;
- a provider likely supports the needed capability but command names are unknown.

Discovery rules:

1. Prefer provider-native command discovery (`help`, `list commands`, schema lookup).
2. Classify candidate commands as read-only or write-capable.
3. Do not run write-capable commands during discovery.
4. Record discovery terms, found commands, and safety classification in the final report.

## no-provider Fallback

`no-provider` is valid when comments are pasted by the user or no remote MR platform is accessible. It can support:

- comment parsing from pasted text;
- classification;
- local code changes after user alignment;
- local report/archive.

It cannot support:

- remote MR lookup;
- remote comment listing;
- remote replies;
- remote resolves.

Remote actions under `no-provider` must be reported as `not_supported_by_provider`.
