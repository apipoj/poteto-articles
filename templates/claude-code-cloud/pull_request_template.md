Fixes #

<!-- Template for .github/pull_request_template.md. Replace <verify-skill> and the check commands,
     and edit the Risk list to the areas where your project needs human sign-off.
     Delete the Fixes line if there is no issue. Comments like this one are hidden. -->

## Intent

<!-- What this change is for, in 1–3 sentences (bug: the root cause, not the symptom), then the
     scenarios that prove it works. Each scenario appears again under Live validation. -->

Scenarios:

-

## Change

<!-- Bullets: what changed and where. Say "No product code changed" when true. -->

-

## Evidence

<!-- Required for any behaviour or UI change: prove it in the running app with <verify-skill>.
     Bug fix: before and after. Say "Not applicable: <reason>" only for docs, CI, or test-only
     changes. -->

Run `<run-id>`, commit `<sha>`:

```bash
# the exact <verify-skill> commands you ran
```

### Live validation

<!-- One row per Intent scenario. Result: ✅ pass / ❌ fail / ⏸️ untested. Live: "live" only when
     the scenario was driven in the running app; unit tests are "no". Untested or not-live rows say
     why in Evidence. -->

| Scenario | Result | Live | Evidence |
| --- | --- | --- | --- |
|  |  |  |  |

<!-- Screenshots: ![what it shows](link). Factory workers: link images by commit SHA (see worker brief). -->

## Verification

- [ ] Lint (0 errors)
- [ ] Tests
- [ ] Build (skip only if no app code changed, and say so)

## Risk

This PR touches (check all that apply):

- [ ] Auth, permissions, or route protection
- [ ] Money, billing, or personal data
- [ ] A database migration (say whether it drops or rewrites data)
- [ ] User-facing text (updated in every supported language)
- [ ] None of the above

Blast radius: <!-- who or what breaks if this is wrong -->

## Needs owner decision

<!-- Questions the issue does not settle and that change what the product does. Don't guess: list
     them here, open the PR as a draft, and ask on the issue. Write "None" when there are none. -->

## Noticed, not fixed

<!-- Out-of-scope bugs or debt you saw. File an issue or write "None". -->

<!-- factory:author model=<model> attempt=<n> -->
