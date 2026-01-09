# .env.local Template

Template for `.env.local` file to be placed in each worktree.
Defines environment variables other than secrets, such as port numbers.

---

## Basic Template

```bash
# .env.local - worktree-specific settings (except secrets)
# This file overrides values in .env

# Backend server port
PORT={PORT_BE}

# Frontend development server port (Vite)
VITE_PORT={PORT_FE}

# Frontend development server port (Next.js)
# NEXT_DEV_PORT={PORT_FE}

# Frontend development server port (CRA/react-scripts)
# REACT_APP_PORT={PORT_FE}
```

---

## Port Number Assignment Rules

Assign unique ports to each worktree:

```
Base port + worktree index

Backend: 3000 + index
Frontend: 5173 + index (Vite default base)
```

| index | worktree | PORT (BE) | VITE_PORT (FE) |
|-------|----------|-----------|----------------|
| 0 | (project root) | 3000 | 5173 |
| 1 | worktree/task-1 | 3001 | 5174 |
| 2 | worktree/task-2 | 3002 | 5175 |
| 3 | worktree/task-3 | 3003 | 5176 |
| 4 | worktree/task-4 | 3004 | 5177 |
| ... | ... | ... | ... |

---

## Framework-Specific Configuration

### Vite (React, Vue, Svelte)

```bash
# .env.local
PORT=3001
VITE_PORT=5174
```

Reference the port in `vite.config.ts`:
```typescript
export default defineConfig({
  server: {
    port: parseInt(process.env.VITE_PORT || '5173'),
  },
});
```

### Next.js

```bash
# .env.local
PORT=3001
NEXT_DEV_PORT=5174
```

Reference in `package.json`:
```json
{
  "scripts": {
    "dev": "next dev -p ${NEXT_DEV_PORT:-3000}"
  }
}
```

### FastAPI / Uvicorn

```bash
# .env.local
PORT=3001
```

Startup command:
```bash
uvicorn main:app --port ${PORT:-8000}
```

### Express.js

```bash
# .env.local
PORT=3001
```

Reference in code:
```javascript
const port = process.env.PORT || 3000;
app.listen(port);
```

---

## Generation Script Example

Automatically generate .env.local when creating a worktree:

```bash
#!/bin/bash
# generate-env-local.sh

WORKTREE_NAME=$1
INDEX=$2

PORT_BE=$((3000 + INDEX))
PORT_FE=$((5173 + INDEX))

cat > worktree/$WORKTREE_NAME/.env.local << EOF
# .env.local - for $WORKTREE_NAME
# Generated for parallel development

PORT=$PORT_BE
VITE_PORT=$PORT_FE
EOF

echo "Created .env.local for $WORKTREE_NAME (BE:$PORT_BE, FE:$PORT_FE)"
```

Usage example:
```bash
./generate-env-local.sh recommendation-api 1
./generate-env-local.sh notification-api 2
./generate-env-local.sh project-card-enhance 3
```

---

## Notes

### Adding to .gitignore

Do not commit `.env.local` to the repository:

```gitignore
# .gitignore
.env.local
.env*.local
```

### Priority Order of .env and .env.local

Most frameworks follow this priority order:

```
.env.local > .env.development.local > .env.development > .env
```

Since `.env.local` values override `.env`, you can separate secrets (.env) and port settings (.env.local).

### Copying Secrets

`.env` (secrets) needs to be copied to each worktree:

```bash
cp .env worktree/$WORKTREE_NAME/.env
```

**Important**: `.env` contains secrets such as API keys and database connection strings.
Make sure that `.env` in the worktree is also excluded by `.gitignore`.
