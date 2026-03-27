# Web Browsing

## Use agent-browser instead of WebFetch

When you need to fetch or read web pages, use the `agent-browser` CLI via Bash instead of the built-in WebFetch tool.

### Fetching a page

```bash
agent-browser open <url>
agent-browser snapshot -i  # get page content with interactive element refs
```

### Reading page text

```bash
agent-browser open <url>
agent-browser snapshot     # text-only snapshot (no interactive refs)
```

### Taking screenshots

```bash
agent-browser screenshot output.png
```

### Interacting with elements

```bash
agent-browser click @e1
agent-browser fill @e2 "search query"
```

### When to fall back to WebFetch

- `agent-browser` command is not found
- Simple URL content extraction where CLI overhead isn't justified
