# CC0 asset library

This directory contains a small, provenance-preserving selection of Kenney
game assets for the Rhythm Dungeon prototype. The files were downloaded on
2026-08-26 through the official `kenney.nl` asset pages using the configured
HTTP proxy. No downloaded asset bytes were edited.

| Package | Intended use | Archive size | Archive SHA-256 |
| --- | --- | ---: | --- |
| [Tiny Dungeon](kenney_tiny_dungeon/) | 16x16 pixel dungeon tiles and small character/object sprites | 98,530 bytes | `c109438ab06f65fd80f9b2686a4cf9c7c11dc64444b47333ec71d602f8bb5fc7` |
| [Roguelike/RPG pack](kenney_roguelike_rpg_pack/) | 16x16 forest ground, trees, plants, paths, structures and dungeon tiles | 715,373 bytes | `8e7d2378f8f794245645f6d7dc7aeeb246791410a7e512293c594b46a5a9524b` |
| [Game Icons](kenney_game_icons/) | Rhythm, target, warning, navigation and result UI icons | 1,045,980 bytes | `7a86d8d58e0b851e22004b3c70bf90b003632bbf9ac633424daa3bb17d9e7e4e` |

## License conclusion

Each official asset page states **Creative Commons CC0** and links to the
Creative Commons public-domain dedication. Each retained package also contains
Kenney's original `License.txt`/`license.txt`. CC0 permits use, modification,
and redistribution, including in personal, educational, commercial, and public
Git repositories. Credit to Kenney or `www.kenney.nl` is welcome but explicitly
optional in the embedded notices.

The project should still keep the package-level source notes and original
archives when importing files into `assets/`, because the source page and
download URL can change over time. These assets are not wired into a scene by
this task; integration and pixel-level style review remain separate work.

## Verification

From the repository root:

```sh
shasum -a 256 assets/library/cc0/kenney_tiny_dungeon/original/kenney_tiny-dungeon.zip
shasum -a 256 assets/library/cc0/kenney_roguelike_rpg_pack/original/kenney_roguelike-rpg-pack.zip
shasum -a 256 assets/library/cc0/kenney_game_icons/original/kenney_game-icons.zip
unzip -t assets/library/cc0/kenney_tiny_dungeon/original/kenney_tiny-dungeon.zip
unzip -t assets/library/cc0/kenney_roguelike_rpg_pack/original/kenney_roguelike-rpg-pack.zip
unzip -t assets/library/cc0/kenney_game_icons/original/kenney_game-icons.zip
```

See each package's `SOURCE.md` for the exact source page, direct download URL,
author, package metadata, retrieval timestamp, retained content, and residual
risks.
