# Skills exported by sync_cfg() into this template repo.
# Add new skill names here instead of editing ~/.zshrc sync logic.

typeset -ga SYNC_SKILLS=(
  gotchas
  spec-opti-workflow
  spec-opti-workflow-v2
  spec-plan-revise
  spec-trouble-resolve
  spec-e2e-debug
  spec-code-review
  spec-commit-push
  fix-mr-comments
  hello-spec-start
  hello-spec-next
  hello-spec-advance
  gw-worktree
  git-worktree-converter
  summary
)

# Space-separated rsync excludes per skill. Excluded target files are removed
# after sync so stale private files do not remain in skill_template.
typeset -gA SYNC_SKILL_EXCLUDES
SYNC_SKILL_EXCLUDES[spec-e2e-debug]="references/bytedcli-debug-map.md references/providers/bytedcli.md"
SYNC_SKILL_EXCLUDES[fix-mr-comments]="references/providers/bytedcli.md"
