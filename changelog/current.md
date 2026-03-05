# Changelog (Unreleased)

Record image-affecting changes to `manager/`, `worker/`, `openclaw-base/` here before the next release.

---

- feat(manager): add model-switch skill with `update-manager-model.sh` script for runtime model switching ([00cbaa5](https://github.com/higress-group/hiclaw/commit/00cbaa5))
- feat(manager): add task-management skill (extracted from AGENTS.md) covering task workflow and state file spec ([00cbaa5](https://github.com/higress-group/hiclaw/commit/00cbaa5))
- feat(manager): add `manager/scripts/lib/builtin-merge.sh` — shared library for idempotent builtin section merging ([00cbaa5](https://github.com/higress-group/hiclaw/commit/00cbaa5))
- fix(manager): fix `upgrade-builtins.sh` duplicate-insertion bug — awk now uses exact line match, preventing repeated marker injection on re-run ([00cbaa5](https://github.com/higress-group/hiclaw/commit/00cbaa5))
- fix(manager): detect and auto-repair corrupted AGENTS.md when marker count != 1 or heading is duplicated ([47c5578](https://github.com/higress-group/hiclaw/commit/47c5578), [c28f82d](https://github.com/higress-group/hiclaw/commit/c28f82d), [078f3f8](https://github.com/higress-group/hiclaw/commit/078f3f8))
- feat(manager): expand worker-management skill and `lifecycle-worker.sh` with improved worker lifecycle handling ([00cbaa5](https://github.com/higress-group/hiclaw/commit/00cbaa5))
- fix(manager): `setup-higress.sh` — multiple route/consumer/MCP init fixes ([d259177](https://github.com/higress-group/hiclaw/commit/d259177))
- fix(manager): `start-manager-agent.sh` — wait for Tuwunel Matrix API ready before proceeding, add detailed logging for token acquisition ([d259177](https://github.com/higress-group/hiclaw/commit/d259177), [1a9e1d8](https://github.com/higress-group/hiclaw/commit/1a9e1d8))
- fix(manager): support Podman by replacing hardcoded `docker` commands with runtime detection; fix `jq` availability inside container; fix provider switch menu text ([9d57ef8](https://github.com/higress-group/hiclaw/commit/9d57ef8))
- fix(manager): force rewrite corrupted AGENTS.md without preserving user content ([639d0c6](https://github.com/higress-group/hiclaw/commit/639d0c6))
- feat(manager): add `TOOLS.md` for Manager — management skills quick-reference cheat sheet, extracted from AGENTS.md ([905294f](https://github.com/higress-group/hiclaw/commit/905294f))
- feat(manager): add `TOOLS.md` for Worker — find-skills priority guidance for unknown problems ([905294f](https://github.com/higress-group/hiclaw/commit/905294f))
- feat(manager): add post-worker-creation onboarding tips to TOOLS.md ([aa694fc](https://github.com/higress-group/hiclaw/commit/aa694fc))
- feat(manager): add project-management mandatory rule to TOOLS.md ([0c7d437](https://github.com/higress-group/hiclaw/commit/0c7d437))
- feat(manager): `upgrade-builtins.sh` deploys Worker `TOOLS.md` to MinIO and all registered worker workspaces ([905294f](https://github.com/higress-group/hiclaw/commit/905294f))
- fix(manager): `worker-openclaw.json.tmpl` — add admin to `dm.allowFrom` so admin can DM workers directly ([406d249](https://github.com/higress-group/hiclaw/commit/406d249))
- fix(manager): `builtin-merge.sh` — add `|| true` to `grep -v` to prevent `set -e` exit on empty user content ([d8b1cf7](https://github.com/higress-group/hiclaw/commit/d8b1cf7))
- fix(manager): `builtin-merge.sh` — add explicit ERROR logging on all write/move failures so startup failures are visible in logs ([bf35d5a](https://github.com/higress-group/hiclaw/commit/bf35d5a))
- fix(manager): `builtin-merge.sh` — replace `[ -n ] && printf` with `if/fi` to avoid exit 1 when user_content is empty ([df134fd](https://github.com/higress-group/hiclaw/commit/df134fd))
- fix(manager): `upgrade-builtins.sh` — replace silent `|| true` with WARNING log when worker-skill MinIO publish fails ([bf35d5a](https://github.com/higress-group/hiclaw/commit/bf35d5a))
- ci: release workflow now opens a PR (`chore/archive-changelog-vX.Y.Z`) instead of pushing directly to main ([f07de3a](https://github.com/higress-group/hiclaw/commit/f07de3a))
- ci: release workflow supports `workflow_dispatch` with version input for manual release trigger ([64f25cb](https://github.com/higress-group/hiclaw/commit/64f25cb))
