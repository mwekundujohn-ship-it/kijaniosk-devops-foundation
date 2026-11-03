# kijanikiosk-payments

Small payment calculation service used by the KijaniKiosk CI pipeline lab.

## Commands

- `npm run lint` checks every source file for syntax, tab characters, trailing whitespace, and long lines.
- `npm run build` copies `src/` into `dist/` and writes `dist/build-info.json`.
- `npm test` runs the calculation tests and writes JUnit output to `test-results/`.

## Layout

```
src/          application code
test/         test harness and cases
scripts/      lint, build and test entry points
dist/         generated at build time (not committed)
```
