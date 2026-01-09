# Testing Philosophy

Detailed guide for testing strategy in parallel development.

## Principle: Test in Production-like State

Rather than heavy use of mocks and fake data, test in conditions close to actual environment to prevent issues after production deployment.

### Why Production-Equivalent Testing

- Prevent cases that pass with mocks but don't work in production
- Early detection of external API spec changes, rate limits, authentication errors
- Verify DB schema and data integrity with real data
- Actually confirm integration between multiple services

## Targets for Production-Equivalent Testing

| Target | Policy |
|------|------|
| External APIs | Use actual API keys (test account recommended) |
| Database | Connect to actual DB (dev/staging environment) |
| Auth/Authorization | Use actual tokens/sessions |
| File Storage | Connect to actual S3/GCS, etc. |
| Email/Notifications | Actually send to test addresses, or use sandbox mode |

## Environment Settings

Copy `.env` to each worktree and set production-equivalent secrets:

```bash
# When creating worktree (see SKILL.md environment setup)
cp .env worktree/$BRANCH/.env

# .env should include production-equivalent connection info
# - DATABASE_URL (dev/staging DB)
# - API keys (external services)
# - Authentication credentials
```

**Note**: Prepare test-specific API keys/DBs and be careful not to destroy production data.

## Test Execution Timing

Merge coordinator runs tests in production-equivalent environment before merging to integration branch:

```
1. Worker Claude creates .done
2. Merge coordinator commits
3. Merge latest from integration branch
4. ★Run production-equivalent tests★  ← Verify external API/DB integration here
5. Tests pass → Push & merge
6. Tests fail → Request fixes
```

## Test Command Examples

```bash
# Production-equivalent tests (with external API/DB connection)
DATABASE_URL=$DATABASE_URL \
API_KEY=$API_KEY \
uv run pytest tests/ -v

# Or
pnpm test:integration
```

## E2E Visual Check (Merge Coordinator)

Merge coordinator uses dev-browser skill to check actual screens in browser:

1. **Start dev server**: Start server in worktree
2. **Open browser**: Access URL with dev-browser skill
3. **Take screenshots**: Capture screenshots of main screens
4. **LLM visual confirmation**: Check UI state from screenshots

```
# Use dev-browser skill
/dev-browser

# Operation example
- Access http://localhost:{port}
- Navigate to main screens
- Take screenshots
- Check UI display, layout, no errors shown
```

### Confirmation Points

- No layout issues
- No error messages displayed
- Expected elements displayed
- No console errors

### Tasks Requiring Visual Check

- Tasks involving frontend (UI)
- Tasks affecting screen transitions/navigation
- Tasks changing layout/styling

### Tasks Not Requiring Visual Check

- Backend API only tasks
- Batch processing/CLI tool tasks

## Handling Test Data

| Type | Policy |
|------|------|
| Read tests | Use existing dev data |
| Write tests | Cleanup after test, or transaction rollback |
| Destructive tests | Use dedicated test tenant/namespace |
