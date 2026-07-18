# Claude Rules for NeoYAML

Rules files in this directory are auto-loaded by Claude Code when editing files
matching the `paths:` globs in each file's frontmatter.

## Layout

| File | Scope | Reusable? |
|------|-------|-----------|
| `pharo-syntax.md` | Pharo syntax, naming, formatting, Tonel layout, Metacello baseline convention | Yes — copy as-is |
| `testing.md` | SUnit conventions (setUp, naming, assertions) | Yes — copy as-is |
| `yaml-spec.md` | YAML 1.2 syntax knowledge (indentation, quoting, reserved words, block scalars) so Claude Code does not guess when writing a YAML emitter | Yes — copy as-is to any project that emits YAML |
| `project-conventions.md` | Everything specific to THIS project (prefix, packages, dependencies, implementation policy) | No — rewrite per project |

## Reusing in Another Smalltalk Project

1. Copy `pharo-syntax.md` and `testing.md` unchanged.
2. Copy `yaml-spec.md` if the project reads or writes YAML.
   (For an HTTP/JSON REST wrapper, use a `rest-api-patterns.md` instead; for a
   C-library wrapper, use a `uffi-patterns.md`.)
3. Write a new `project-conventions.md` for the target project, covering at least:
   - class prefixes and package layout
   - external dependencies (Metacello baselines)
   - domain-specific implementation policy
4. Adjust `paths:` globs if the source layout differs from `src/<Package>/`.

## Conventions for Editing Rules Files

- Write in **English**.
- Cite primary sources where they exist (official docs, class comments).
- No speculation — record only verified facts; write "reason unknown" or omit.
- Only include code examples that have passed local tests.
