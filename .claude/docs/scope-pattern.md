# Standard SCOPE Pattern

> This is the default parallel exploration pattern. Commands may adapt agent descriptions to their context.

```
Launch parallel (sonnet):
  1. Explore related files/module structure → `path/file — reason`
  2. Check existing patterns/conventions   → `path/file — which pattern`
  3. Analyze dependencies/impact scope     → `path/file — impact direction`
```

- Use 2 agents minimum, 3 maximum.
- Each agent returns bullets only (`path/file — reason`), max 15.
- Consolidate results before writing to PLAN or spec.
