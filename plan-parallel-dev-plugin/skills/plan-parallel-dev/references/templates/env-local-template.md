# .env.local テンプレート

各worktreeに配置する `.env.local` ファイルのテンプレート。
ポート番号など、secrets以外の環境変数を定義する。

---

## 基本テンプレート

```bash
# .env.local - worktree固有の設定（secrets以外）
# このファイルは .env の値を上書きする

# バックエンドサーバーポート
PORT={PORT_BE}

# フロントエンド開発サーバーポート（Vite）
VITE_PORT={PORT_FE}

# フロントエンド開発サーバーポート（Next.js）
# NEXT_DEV_PORT={PORT_FE}

# フロントエンド開発サーバーポート（CRA/react-scripts）
# REACT_APP_PORT={PORT_FE}
```

---

## ポート番号の割り当てルール

worktreeごとにユニークなポートを割り当てる:

```
ベースポート + worktreeインデックス

バックエンド: 3000 + index
フロントエンド: 5173 + index (Vite デフォルト基準)
```

| index | worktree | PORT (BE) | VITE_PORT (FE) |
|-------|----------|-----------|----------------|
| 0 | (プロジェクトルート) | 3000 | 5173 |
| 1 | worktree/task-1 | 3001 | 5174 |
| 2 | worktree/task-2 | 3002 | 5175 |
| 3 | worktree/task-3 | 3003 | 5176 |
| 4 | worktree/task-4 | 3004 | 5177 |
| ... | ... | ... | ... |

---

## フレームワーク別の設定

### Vite (React, Vue, Svelte)

```bash
# .env.local
PORT=3001
VITE_PORT=5174
```

`vite.config.ts` でポートを参照:
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

`package.json` で参照:
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

起動コマンド:
```bash
uvicorn main:app --port ${PORT:-8000}
```

### Express.js

```bash
# .env.local
PORT=3001
```

コードで参照:
```javascript
const port = process.env.PORT || 3000;
app.listen(port);
```

---

## 生成スクリプト例

worktree作成時に.env.localを自動生成:

```bash
#!/bin/bash
# generate-env-local.sh

WORKTREE_NAME=$1
INDEX=$2

PORT_BE=$((3000 + INDEX))
PORT_FE=$((5173 + INDEX))

cat > worktree/$WORKTREE_NAME/.env.local << EOF
# .env.local - $WORKTREE_NAME 用
# Generated for parallel development

PORT=$PORT_BE
VITE_PORT=$PORT_FE
EOF

echo "Created .env.local for $WORKTREE_NAME (BE:$PORT_BE, FE:$PORT_FE)"
```

使用例:
```bash
./generate-env-local.sh recommendation-api 1
./generate-env-local.sh notification-api 2
./generate-env-local.sh project-card-enhance 3
```

---

## 注意事項

### .gitignore への追加

`.env.local` はリポジトリにコミットしない:

```gitignore
# .gitignore
.env.local
.env*.local
```

### .env と .env.local の優先順位

多くのフレームワークでは以下の優先順位:

```
.env.local > .env.development.local > .env.development > .env
```

`.env.local` の値が `.env` を上書きするため、secrets（.env）とポート設定（.env.local）を分離できる。

### secrets のコピー

`.env`（secrets）は各worktreeにコピーが必要:

```bash
cp .env worktree/$WORKTREE_NAME/.env
```

**重要**: `.env` には APIキー、データベース接続文字列などの secrets が含まれる。
worktree内の `.env` も `.gitignore` で除外されていることを確認する。
