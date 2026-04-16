# MikuFiesta Pages Launch Lock

This project publishes a locked landing page to GitHub Pages until `2026-04-17T17:00:00Z`, which is `17 April 2026 at 12:00 PM` in `America/Lima`.

## How it works

- `index.html` is the public locked page and contains no launch content.
- `private/open/index.html` is your local source for the unlocked page and is ignored by git.
- `secure/open-site.tar.enc` is the encrypted launch bundle committed to the public repo.
- `scripts/build-pages.sh` builds `dist/index.html` in either `locked` or `open` mode.
- `scripts/seal-open-site.sh` refreshes the encrypted launch bundle from `private/open/` and `private/assets/`.
- `.github/workflows/pages.yml` deploys the Pages artifact on every push to `main`, on manual dispatch, and every 5 minutes.

## Required GitHub secret

Create a repository secret named `OPEN_SITE_PASSPHRASE` with the passphrase used to decrypt `secure/open-site.tar.enc`.

The helper below creates or reuses a local passphrase file at `private/.open-site-passphrase`, then rebuilds the encrypted launch bundle:

```bash
./scripts/seal-open-site.sh
```

If you ever need to sync the secret manually, use:

```bash
gh secret set OPEN_SITE_PASSPHRASE --repo jeffangeloss/MikuFiesta < private/.open-site-passphrase
```

`SITE_OPEN_HTML_B64` is kept only as a legacy fallback and is no longer the primary release path.

## GitHub Pages setup

1. Create a new public GitHub repository and push this project to `main`.
2. In GitHub, go to `Settings` -> `Pages` and set `Source` to `GitHub Actions`.
3. Add the `OPEN_SITE_PASSPHRASE` repository secret and keep `secure/open-site.tar.enc` up to date with `./scripts/seal-open-site.sh`.
4. Push to `main` to publish the locked page immediately.
5. Use `Actions` -> `Deploy GitHub Pages` -> `Run workflow` with `force_state=open` or `force_state=locked` to validate both states before launch.

## Local validation

Run the build script directly:

```bash
./scripts/build-pages.sh
cat dist/build-state.txt
```

To force a state locally:

```bash
FORCE_STATE=locked ./scripts/build-pages.sh
FORCE_STATE=open ./scripts/build-pages.sh
```

## Private local preview

Keep GitHub Pages on the locked countdown while you preview the unlocked site only on your own computer:

```bash
./scripts/preview-site.sh open
```

Then open:

```text
http://127.0.0.1:4173
```

Useful variations:

```bash
./scripts/preview-site.sh locked
PORT=8080 ./scripts/preview-site.sh open
```

The preview server binds to `127.0.0.1`, so it is not exposed as a public internet URL.

If you need local-only media for the unlocked page, keep it in `private/assets/`.
Those files stay out of git and are copied into `dist/assets/` only when you preview the `open` state locally.
