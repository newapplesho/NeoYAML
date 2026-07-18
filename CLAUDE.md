# NeoYAML

See [README.md](README.md) for the project overview, usage examples, package
layout, and `make` commands. This file covers only what Claude Code needs
beyond that.

## Working with sources

`scripts/load-project.st` is the single source of truth for the Metacello load
expression (paste into a Playground with Ctrl+D to load manually). CI uses
[smalltalkCI](https://github.com/hpi-swa/smalltalkCI):

```bash
smalltalkci -s Pharo64-13 .smalltalk.ston   # Pharo 12 or 13
```

After editing a `.class.st` file, reload it into the image (`make load`,
re-run the Metacello load, or use Iceberg), otherwise the change is not
reflected in tests.

## Documentation style

- In Japanese text, do not put a space between Japanese characters and Latin
  characters (English words, code, numbers) — e.g. `NeoJSONで`, `YAMLを`.
- Do not use `→`. Express references with `：` and connections with words like
  `と` / `して`.

## Detailed rules

The rules are split into "generic (copyable to other Smalltalk projects)" and
"specific to this project". See `.claude/rules/README.md` for how they are
organized.

- Pharo syntax & naming (generic): `.claude/rules/pharo-syntax.md` (auto-loaded for `.st` files)
- YAML syntax knowledge (generic): `.claude/rules/yaml-spec.md` (auto-loaded for `src/NeoYAML-*/`)
- Testing conventions (generic): `.claude/rules/testing.md` (auto-loaded for `*-Tests/`)
- Project-specific conventions: `.claude/rules/project-conventions.md` (prefix, packages, dependencies, implementation policy)

## Conventions for writing rules files

- **Language: English.**
- **Cite sources:** point to a primary source where one exists (official docs, class comments).
- **No speculation:** record only verified facts. If a reason is unknown, write "reason unknown" or omit it.
- **Only verified code:** include code examples only for patterns that have passed local tests.
