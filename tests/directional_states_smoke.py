#!/usr/bin/env python3
"""Regression checks for the four-direction hurt/death runtime sprites."""

from __future__ import annotations

import hashlib
import sys
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ("down", "left", "right", "up")
# The player and first-layer regular enemy use the deterministic directional
# state generator.  The first-layer Boss has its own BHai-derived hurt/death
# audit in tests/first_layer_assets_smoke.py, so it is intentionally not
# duplicated here.
TARGETS = (
    ("player", "player", 32, 30, "player_sheet.png", (0,)),
    ("enemy", "enemy_siphonling", 32, 30,
     "enemy_siphonling_sheet.png", (0,)),
)

# A reviewed idle atlas contains roughly thirty opaque colours.  State cues
# may add a few deliberate highlight/shading colours, but a photographic or
# anti-aliased replacement would be much larger.  This is intentionally a
# generous upper bound (rather than an exact palette assertion) so valid
# hand-authored revisions are not rejected.
MAX_OPAQUE_COLORS = 48

# Colours used by the deterministic state generator.  They are documented as
# an allow-list for diagnostics; source-derived colours remain valid, so the
# test enforces the count bound above instead of requiring exact membership.
KNOWN_STATE_COLORS = frozenset({
    (120, 220, 211), (196, 255, 246), (53, 126, 131),
    (218, 143, 63), (255, 207, 105), (126, 47, 65), (75, 99, 99),
})


def _components(image: Image.Image) -> list[list[tuple[int, int]]]:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = alpha.size
    seen: set[tuple[int, int]] = set()
    groups: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if not pixels[x, y] or (x, y) in seen:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            seen.add((x, y))
            group: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                group.append((px, py))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        if not dx and not dy:
                            continue
                        nx, ny = px + dx, py + dy
                        if (0 <= nx < width and 0 <= ny < height and
                                pixels[nx, ny] and (nx, ny) not in seen):
                            seen.add((nx, ny))
                            queue.append((nx, ny))
            groups.append(group)
    groups.sort(key=len, reverse=True)
    return groups


def _bbox(points: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    """Return an inclusive pixel bounding box for a non-empty component."""

    return (min(x for x, _ in points), min(y for _, y in points),
            max(x for x, _ in points), max(y for _, y in points))


def _bbox_gap(first: tuple[int, int, int, int],
              second: tuple[int, int, int, int]) -> int:
    """Chebyshev gap between two inclusive boxes (0 when they overlap)."""

    if first[2] < second[0]:
        gap_x = second[0] - first[2] - 1
    elif second[2] < first[0]:
        gap_x = first[0] - second[2] - 1
    else:
        gap_x = 0
    if first[3] < second[1]:
        gap_y = second[1] - first[3] - 1
    elif second[3] < first[1]:
        gap_y = first[1] - second[3] - 1
    else:
        gap_y = 0
    return max(gap_x, gap_y)


def _normalise_idle(atlas: Image.Image, row: int, column: int,
                    size: int, baseline: int) -> Image.Image | None:
    """Extract one atlas cell and put its body on the state-frame anchor.

    The generated single-cell states use a centred pivot and a common foot
    baseline.  Applying the same deterministic translation to the idle cell
    makes the pixel-difference check meaningful; otherwise a harmless atlas
    frame offset could masquerade as a hurt/death cue.  Detached Boss spark
    particles are excluded using the same small-gap rule as the generator.
    """

    left = column * size
    top = row * size
    cell = atlas.crop((left, top, left + size, top + size)).convert("RGBA")
    groups = _components(cell)
    if not groups:
        return None
    main_box = _bbox(groups[0])
    keep: set[tuple[int, int]] = set(groups[0])
    for group in groups[1:]:
        group_box = _bbox(group)
        if len(group) >= 3 and _bbox_gap(main_box, group_box) <= 2:
            keep.update(group)
    keep_box = _bbox(list(keep))
    target_center = (size - 1) / 2.0
    dx = int(round(target_center - (keep_box[0] + keep_box[2]) / 2.0))
    dy = baseline - keep_box[3]
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    src = cell.load()
    dst = out.load()
    for x, y in keep:
        nx, ny = x + dx, y + dy
        if 0 <= nx < size and 0 <= ny < size:
            r, g, b, _ = src[x, y]
            dst[nx, ny] = (r, g, b, 255)
    return out


def _body_metrics(image: Image.Image) -> tuple[int, int] | None:
    """Return (opaque area, inclusive height) of the largest component."""

    groups = _components(image)
    if not groups:
        return None
    left, top, right, bottom = _bbox(groups[0])
    return len(groups[0]), bottom - top + 1


def _opaque_colors(image: Image.Image) -> set[tuple[int, int, int]]:
    return {(r, g, b) for r, g, b, a in _pixel_data(image) if a}


def _pixel_data(image: Image.Image):
    """Read pixels without Pillow's ``getdata`` deprecation warning."""

    getter = getattr(image, "get_flattened_data", None)
    return getter() if getter is not None else image.getdata()


def _pixel_difference(first: Image.Image, second: Image.Image) -> int:
    """Return the number of changed RGBA channels between two equal frames."""

    if first.size != second.size:
        return -1
    return sum(a != b for a, b in zip(first.tobytes(), second.tobytes()))


def _digest(image: Image.Image) -> str:
    return hashlib.sha256(image.tobytes()).hexdigest()


def _flip_bytes(image: Image.Image, horizontal: bool, vertical: bool) -> bytes:
    out = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT if horizontal
                           else Image.Transpose.FLIP_TOP_BOTTOM if vertical
                           else Image.Transpose.FLIP_LEFT_RIGHT)
    if horizontal and vertical:
        out = image.transpose(Image.Transpose.ROTATE_180)
    return out.tobytes()


def main() -> int:
    failures: list[str] = []
    count = 0
    for role, prefix, size, baseline, atlas_name, idle_columns in TARGETS:
        # Build direction-specific, canonically anchored idle references once
        # per role.  Missing/invalid references are reported, while the basic
        # runtime-file checks below remain useful on their own.
        idle_by_direction: dict[str, list[Image.Image]] = {}
        atlas_path = ROOT / "assets" / "sprites" / atlas_name
        atlas: Image.Image | None = None
        if not atlas_path.exists():
            failures.append(f"missing_idle_atlas:{atlas_name}")
        else:
            try:
                with Image.open(atlas_path) as opened_atlas:
                    atlas = opened_atlas.convert("RGBA")
            except (OSError, ValueError) as exc:
                failures.append(f"idle_atlas_error:{atlas_name}:{exc}")
        if atlas is not None:
            expected_atlas_size = (size * 4, size * 4)
            if atlas.size != expected_atlas_size:
                failures.append(
                    f"idle_atlas_size:{atlas_name}:{atlas.size}:expected={expected_atlas_size}")
            for row, direction in enumerate(DIRECTIONS):
                candidates: list[Image.Image] = []
                for column in idle_columns:
                    frame = _normalise_idle(atlas, row, column, size, baseline)
                    if frame is not None:
                        candidates.append(frame)
                if not candidates:
                    failures.append(f"empty_idle:{role}:{direction}")
                idle_by_direction[direction] = candidates

        state_images: dict[str, Image.Image] = {}
        for state in ("hurt", "death"):
            for direction in DIRECTIONS:
                name = (f"{prefix}_{state}_{direction}.png")
                path = ROOT / "assets" / "sprites" / name
                count += 1
                if not path.exists():
                    failures.append(f"missing:{name}")
                    continue
                try:
                    with Image.open(path) as opened:
                        # Check the on-disk mode before converting for analysis;
                        # otherwise an RGB/greyscale replacement would be
                        # silently accepted by ``convert("RGBA")``.
                        if opened.mode != "RGBA":
                            failures.append(f"mode:{name}:{opened.mode}")
                        image = opened.convert("RGBA")
                except (OSError, ValueError) as exc:
                    failures.append(f"decode:{name}:{exc}")
                    continue
                state_images[f"{state}:{direction}"] = image
                if image.size != (size, size):
                    failures.append(f"size:{name}:{image.size}")
                alpha_values = set(_pixel_data(image.getchannel("A")))
                if not alpha_values <= {0, 255}:
                    failures.append(f"alpha:{name}:{sorted(alpha_values)[:5]}")
                for r, g, b, a in _pixel_data(image):
                    if not a and (r, g, b) != (0, 0, 0):
                        failures.append(f"transparent_rgb:{name}")
                        break
                opaque_colors = _opaque_colors(image)
                if len(opaque_colors) > MAX_OPAQUE_COLORS:
                    unknown = len(opaque_colors - KNOWN_STATE_COLORS)
                    failures.append(
                        f"palette_size:{name}:{len(opaque_colors)}:"
                        f"max={MAX_OPAQUE_COLORS}:unknown={unknown}")
                groups = _components(image)
                if not groups:
                    failures.append(f"empty:{name}")
                    continue
                main_group = groups[0]
                left = min(x for x, _ in main_group)
                right = max(x for x, _ in main_group)
                bottom = max(y for _, y in main_group)
                center = (left + right) / 2.0
                target_center = (size - 1) / 2.0
                if abs(center - target_center) > 1.0:
                    failures.append(f"pivot:{name}:{center:.1f}")
                if bottom != baseline:
                    failures.append(f"baseline:{name}:{bottom}")
                if any(len(group) < 2 for group in groups[1:]):
                    failures.append(f"singleton_component:{name}")

        # A state must not silently fall back to a byte-identical idle frame.
        # Compare to every active idle phase; Boss has phase 1 and phase 2
        # references, while the player/enemy each have one.
        for direction in DIRECTIONS:
            idle_candidates = idle_by_direction.get(direction, [])
            if not idle_candidates:
                continue
            for state in ("hurt", "death"):
                image = state_images.get(f"{state}:{direction}")
                if image is None or image.size != (size, size):
                    continue
                for phase_index, idle in enumerate(idle_candidates, start=1):
                    difference = _pixel_difference(image, idle)
                    if difference == 0:
                        phase_label = f":phase{phase_index}" if len(idle_candidates) > 1 else ""
                        failures.append(
                            f"same_as_idle:{role}:{state}:{direction}{phase_label}")

            # Death semantics are evaluated on the largest connected body;
            # detached sparks/fragments are intentionally ignored.  Requiring
            # both metrics to be lower than every active phase keeps a death
            # frame visibly collapsed without imposing a subjective ratio.
            death = state_images.get(f"death:{direction}")
            if death is None or death.size != (size, size):
                continue
            death_metrics = _body_metrics(death)
            idle_metrics = [_body_metrics(idle) for idle in idle_candidates]
            idle_metrics = [metrics for metrics in idle_metrics if metrics is not None]
            if death_metrics is None or not idle_metrics:
                continue
            death_area, death_height = death_metrics
            idle_area = min(metrics[0] for metrics in idle_metrics)
            idle_height = min(metrics[1] for metrics in idle_metrics)
            if death_area >= idle_area:
                failures.append(
                    f"death_body_area:{role}:{direction}:{death_area}"
                    f">={idle_area}")
            if death_height >= idle_height:
                failures.append(
                    f"death_body_height:{role}:{direction}:{death_height}"
                    f">={idle_height}")

        # State and directional identity checks: no exact duplicate state pair,
        # and no direction may be only a horizontal/vertical mirror of another.
        for direction in DIRECTIONS:
            hurt = state_images.get(f"hurt:{direction}")
            death = state_images.get(f"death:{direction}")
            if hurt is not None and death is not None and _digest(hurt) == _digest(death):
                failures.append(f"same_hurt_death:{role}:{direction}")
        for state in ("hurt", "death"):
            for i, first in enumerate(DIRECTIONS):
                a = state_images.get(f"{state}:{first}")
                if a is None:
                    continue
                for second in DIRECTIONS[i + 1:]:
                    b = state_images.get(f"{state}:{second}")
                    if b is None:
                        continue
                    if a.tobytes() == b.tobytes():
                        failures.append(f"duplicate_direction:{role}:{state}:{first}:{second}")
                    if a.tobytes() == _flip_bytes(b, True, False):
                        failures.append(f"mirror_direction:{role}:{state}:{first}:{second}:h")
                    if a.tobytes() == _flip_bytes(b, False, True):
                        failures.append(f"mirror_direction:{role}:{state}:{first}:{second}:v")

    if failures:
        print("DIRECTIONAL_STATES_SMOKE_FAIL | " + "; ".join(failures))
        return 1
    print(
        f"DIRECTIONAL_STATES_SMOKE_OK | {count} files | "
        "binary_alpha pivot baseline state_identity idle_difference "
        "death_compression palette_bound")
    return 0


if __name__ == "__main__":
    sys.exit(main())
