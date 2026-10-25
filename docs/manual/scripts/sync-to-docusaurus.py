#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 optiMEAS GmbH
"""Sync the manual from docs/manual/{de,en,fr,it,es} into the native-i18n
layout of the optiMEAS Docusaurus site.

  DE  docs/manual/de/X  ->  <target>/docs/software/opticloud/13_sensor_app/X
  EN  docs/manual/en/X  ->  <target>/i18n/en/docusaurus-plugin-content-docs/current/software/opticloud/13_sensor_app/X
  FR, IT, ES the same as EN under i18n/fr, i18n/it, i18n/es

German is the site's default locale; every other locale lives under i18n/.
This repository is the source for all of them: the target's pages are
overwritten. .md files are clean-replaced; other files are additive
(overwrite same-named files, never delete target-only files).
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

DEFAULT_LOCALE = "de"
# Locales besides German. A target site that does not have one of the
# OPTIONAL_LOCALES at all (no i18n/<locale> directory) is synced without it.
I18N_LOCALES = ("en", "fr", "it", "es")
OPTIONAL_LOCALES = ("fr", "it", "es")

SUBTREE = Path("software/opticloud/13_sensor_app")


def src_dir(locale: str) -> Path:
    """Source tree of a locale, relative to the repository root."""
    return Path("docs/manual") / locale


def dst_dir(locale: str) -> Path:
    """Target subtree of a locale, relative to the Docusaurus checkout."""
    if locale == DEFAULT_LOCALE:
        return Path("docs") / SUBTREE
    return Path("i18n") / locale / "docusaurus-plugin-content-docs/current" / SUBTREE


def iter_files(root: Path):
    """Yield every file under ``root`` as a path relative to ``root``."""
    for p in sorted(root.rglob("*")):
        if p.is_file():
            yield p.relative_to(root)


def sync_locale(src: Path, dst: Path, *, create: bool, dry_run: bool) -> dict:
    """Sync one locale tree. Clean-replace .md, additive other files. Returns a tally."""
    if not dst.is_dir():
        if not create:
            raise SystemExit(
                f"target subtree does not exist: {dst}\n"
                "Pass --create for the first sync, after checking the target path."
            )
        if not dry_run:
            dst.mkdir(parents=True)
    tally = {"md": 0, "other": 0, "removed_md": 0}

    # 1. Clean-replace: drop existing .md under the target subtree.
    if dst.is_dir():
        for p in sorted(dst.rglob("*.md")):
            if not dry_run:
                p.unlink()
            tally["removed_md"] += 1

    # 2. Copy the source files.
    for rel in iter_files(src):
        if not dry_run:
            (dst / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src / rel, dst / rel)
        tally["md" if rel.suffix == ".md" else "other"] += 1
    return tally


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Sync the manual into the optiMEAS Docusaurus site.")
    ap.add_argument("target", type=Path, help="root of the optimeas-documentation checkout")
    ap.add_argument("--create", action="store_true", help="create missing target subtrees")
    ap.add_argument("--dry-run", action="store_true", help="print actions, write nothing")
    ap.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[3],
        help="root of this repository (default: inferred from this script)",
    )
    args = ap.parse_args(argv)

    if not args.target.is_dir():
        raise SystemExit(f"target is not a directory: {args.target}")

    mode = "DRY-RUN" if args.dry_run else "SYNCED"
    for locale in (DEFAULT_LOCALE, *I18N_LOCALES):
        if locale in OPTIONAL_LOCALES and not (args.target / "i18n" / locale).is_dir():
            print(f"[SKIPPED] {locale.upper()}: the target site has no i18n/{locale}")
            continue
        t = sync_locale(
            args.repo_root / src_dir(locale),
            args.target / dst_dir(locale),
            create=args.create,
            dry_run=args.dry_run,
        )
        print(f"[{mode}] {locale.upper()}: {t['md']} md ({t['removed_md']} removed), {t['other']} other")
    return 0


if __name__ == "__main__":
    sys.exit(main())
