#!/usr/bin/env python3
"""Create deterministic hurt/death state frames from the reviewed idle atlas.

The partner-service single-frame attempts were useful for the first playable
pass, but several directions were mirrored or duplicated.  This small,
deterministic pass uses the direction-specific idle cells as identity anchors
and draws the state cue at the logical pixel size.  It deliberately writes to
an output directory supplied by the caller; the default is a temporary
preview directory so an audit can happen before replacing runtime files.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from typing import Iterable

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"
DIRECTIONS = ("down", "left", "right", "up")
DIR_INDEX = {name: index for index, name in enumerate(DIRECTIONS)}

# The palette is intentionally close to the existing atlas.  New pixels are
# limited to these colours so the state frames remain crisp at nearest-neighbor
# scale and do not introduce semi-transparent or photographic noise.
CYAN = (120, 220, 211, 255)
CYAN_BRIGHT = (196, 255, 246, 255)
CYAN_DARK = (53, 126, 131, 255)
AMBER = (218, 143, 63, 255)
AMBER_BRIGHT = (255, 207, 105, 255)
CRIMSON = (126, 47, 65, 255)
SLATE = (75, 99, 99, 255)


def neighbours(x: int, y: int) -> Iterable[tuple[int, int]]:
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            if dx or dy:
                yield x + dx, y + dy


def components(alpha: Image.Image) -> list[list[tuple[int, int]]]:
    """Return 8-connected opaque components, largest first."""

    mask = alpha.load()
    width, height = alpha.size
    seen: set[tuple[int, int]] = set()
    result: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if not mask[x, y] or (x, y) in seen:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            seen.add((x, y))
            group: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                group.append((px, py))
                for nx, ny in neighbours(px, py):
                    if (0 <= nx < width and 0 <= ny < height and
                            mask[nx, ny] and (nx, ny) not in seen):
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            result.append(group)
    result.sort(key=len, reverse=True)
    return result


def bbox(points: Iterable[tuple[int, int]]) -> tuple[int, int, int, int]:
    values = list(points)
    if not values:
        return (0, 0, -1, -1)
    return (min(x for x, _ in values), min(y for _, y in values),
            max(x for x, _ in values), max(y for _, y in values))


def _bbox_gap(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    if a[2] < b[0]:
        gx = b[0] - a[2] - 1
    elif b[2] < a[0]:
        gx = a[0] - b[2] - 1
    else:
        gx = 0
    if a[3] < b[1]:
        gy = b[1] - a[3] - 1
    elif b[3] < a[1]:
        gy = a[1] - b[3] - 1
    else:
        gy = 0
    return max(gx, gy)


def extract_idle(path: Path, frame_size: int, row: int,
                 baseline: int) -> Image.Image:
    """Extract and anchor a clean direction-specific idle silhouette."""

    atlas = Image.open(path).convert("RGBA")
    cell = atlas.crop((0, row * frame_size, frame_size, (row + 1) * frame_size))
    groups = components(cell.getchannel("A"))
    if not groups:
        raise ValueError(f"{path} row {row} has no opaque pixels")
    main = groups[0]
    main_box = bbox(main)
    # Keep nearby crown/scarf pieces, but discard detached generated particles
    # (especially the bottom particles in the side-facing Boss cells).
    keep: set[tuple[int, int]] = set(main)
    for group in groups[1:]:
        if len(group) >= 3 and _bbox_gap(main_box, bbox(group)) <= 2:
            keep.update(group)

    source = cell.load()
    left, top, right, bottom = bbox(keep)
    center = (left + right) / 2.0
    target_center = (frame_size - 1) / 2.0
    dx = int(round(target_center - center))
    dy = baseline - bottom
    out = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
    dst = out.load()
    for x, y in keep:
        nx, ny = x + dx, y + dy
        if 0 <= nx < frame_size and 0 <= ny < frame_size:
            r, g, b, _ = source[x, y]
            dst[nx, ny] = (r, g, b, 255)
    return out


def is_cyan(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    return bool(a and g >= r * 1.15 and b >= r * 1.15 and g + b > 180)


def is_red(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    return bool(a and r >= g * 1.20 and r >= b * 1.12)


def is_light(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    return bool(a and r + g + b > 330)


def scale_rgb(pixel: tuple[int, int, int, int], factor: float) -> tuple[int, int, int, int]:
    r, g, b, a = pixel
    return (max(0, min(255, round(r * factor))),
            max(0, min(255, round(g * factor))),
            max(0, min(255, round(b * factor))), a)


def put(image: Image.Image, x: int, y: int,
        color: tuple[int, int, int, int]) -> None:
    if 0 <= x < image.width and 0 <= y < image.height:
        image.putpixel((x, y), color)


def clean_components(image: Image.Image, minimum_size: int = 2) -> None:
    """Remove accidental one-pixel noise while retaining intentional bursts."""

    alpha = image.getchannel("A")
    groups = components(alpha)
    keep: set[tuple[int, int]] = set()
    for index, group in enumerate(groups):
        if index == 0 or len(group) >= minimum_size:
            keep.update(group)
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if (x, y) not in keep:
                pixels[x, y] = (0, 0, 0, 0)


def reanchor(image: Image.Image, baseline: int) -> None:
    """Align the largest intentional body to the canonical center/baseline."""

    groups = components(image.getchannel("A"))
    if not groups:
        return
    left, top, right, bottom = bbox(groups[0])
    target_center = (image.width - 1) / 2.0
    dx = int(round(target_center - (left + right) / 2.0))
    dy = baseline - bottom
    if dx == 0 and dy == 0:
        return
    source = image.copy()
    image.paste((0, 0, 0, 0), (0, 0, image.width, image.height))
    src = source.load()
    dst = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if src[x, y][3]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < image.width and 0 <= ny < image.height:
                    dst[nx, ny] = src[x, y]


def diamond(image: Image.Image, cx: int, cy: int,
            color: tuple[int, int, int, int], radius: int = 1) -> None:
    for dx in range(-radius, radius + 1):
        for dy in range(-radius, radius + 1):
            if abs(dx) + abs(dy) <= radius:
                put(image, cx + dx, cy + dy, color)


def direction_recoil(direction: str) -> tuple[int, int]:
    # The upper body leans away from the incoming hit while the feet remain on
    # the canonical baseline.
    return {"down": (0, -1), "left": (1, 0),
            "right": (-1, 0), "up": (0, 1)}[direction]


def apply_hurt(base: Image.Image, direction: str, baseline: int,
               role: str) -> Image.Image:
    size = base.width
    source = base.load()
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    dst = out.load()
    opaque = [(x, y) for y in range(size) for x in range(size)
              if source[x, y][3]]
    if not opaque:
        return out
    top = min(y for _, y in opaque)
    height = max(1, baseline - top)
    rx, ry = direction_recoil(direction)
    for x, y in opaque:
        amount = max(0.0, min(1.0, (baseline - y) / height))
        nx = x + int(round(rx * amount * (1.4 if role == "boss" else 1.0)))
        ny = y + int(round(ry * amount * (1.2 if role == "boss" else 1.0)))
        pixel = source[x, y]
        if is_light(pixel):
            pixel = scale_rgb(pixel, 0.88)
        put(out, nx, ny, pixel)
        # A one-pixel bridge prevents a diagonal shift from opening a hole in
        # the cloak/shell silhouette.
        if nx != x:
            put(out, x + (1 if nx > x else -1), y, pixel)
        if ny != y:
            put(out, x, y + (1 if ny > y else -1), pixel)

    center = size // 2
    if direction == "down":
        impact = (center, baseline - (18 if role == "boss" else 9))
        extension = [(center, impact[1] + 2), (center - 1, impact[1] + 2),
                     (center + 1, impact[1] + 2)]
    elif direction == "left":
        impact = (center - (15 if role == "boss" else 6),
                  baseline - (19 if role == "boss" else 9))
        extension = [(impact[0] - 2, impact[1]), (impact[0] - 2, impact[1] - 1)]
    elif direction == "right":
        impact = (center + (15 if role == "boss" else 6),
                  baseline - (19 if role == "boss" else 9))
        extension = [(impact[0] + 2, impact[1]), (impact[0] + 2, impact[1] - 1)]
    else:
        impact = (center, baseline - (24 if role == "boss" else 11))
        extension = [(impact[0], impact[1] - 2), (impact[0] - 1, impact[1] - 2),
                     (impact[0] + 1, impact[1] - 2)]
    diamond(out, impact[0], impact[1], CYAN_BRIGHT, 1)
    for x, y in extension:
        put(out, x, y, CYAN)
    # The heart-core/energy remains visible through the flash.
    core_y = baseline - (22 if role == "boss" else 10)
    core_x = center
    if direction == "left":
        core_x -= 2 if role == "boss" else 1
    elif direction == "right":
        core_x += 2 if role == "boss" else 1
    diamond(out, core_x, core_y, CYAN, 1)
    return out


def _hash_pixel(x: int, y: int, row: int) -> int:
    return (x * 37 + y * 61 + row * 97 + 23) % 101


def apply_death(base: Image.Image, direction: str, baseline: int,
                role: str, row: int) -> Image.Image:
    size = base.width
    source = base.load()
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    opaque = [(x, y) for y in range(size) for x in range(size)
              if source[x, y][3]]
    if not opaque:
        return out
    top = min(y for _, y in opaque)
    height = max(1, baseline - top)
    squash = 0.56 if role != "boss" else 0.64
    for x, y in opaque:
        rel = baseline - y
        # Upper/outer pixels dissolve first; lower pixels form a readable
        # collapsed body.  The deterministic pattern keeps adjacent pixels
        # together instead of producing random one-pixel noise.
        normalized = max(0.0, min(1.0, rel / height))
        edge = (abs(x - (size - 1) / 2.0) / max(1.0, size / 2.0))
        threshold = int(12 + normalized * 34 + edge * 10)
        if rel > 2 and _hash_pixel(x, y, row) < threshold:
            continue
        ny = baseline - int(round(rel * squash))
        # A subtle directional fold keeps side/back silhouettes distinct.
        if direction == "left":
            nx = x - (1 if rel > height * 0.45 else 0)
        elif direction == "right":
            nx = x + (1 if rel > height * 0.45 else 0)
        else:
            nx = x
        pixel = source[x, y]
        if is_cyan(pixel):
            pixel = CYAN_DARK
        elif is_red(pixel):
            pixel = scale_rgb(pixel, 0.62)
        else:
            pixel = scale_rgb(pixel, 0.62)
        put(out, nx, ny, pixel)

    center = size // 2
    core_y = baseline - (4 if role != "boss" else 8)
    core_x = center
    if direction == "left":
        core_x -= 3 if role == "boss" else 2
    elif direction == "right":
        core_x += 3 if role == "boss" else 2
    elif direction == "up":
        core_y -= 2 if role == "boss" else 1
    core_color = AMBER if role == "enemy" else CYAN_DARK
    core_bright = AMBER_BRIGHT if role == "enemy" else CYAN
    diamond(out, core_x, core_y, core_color, 2 if role == "boss" else 1)
    diamond(out, core_x, core_y - 1, core_bright, 1)

    # Compact fragments are grouped in pairs/triads and stay above the feet,
    # so the anchor is never determined by a stray bottom pixel.
    if role == "boss":
        fragment_offsets = [(-12, -18), (12, -16), (-8, -25), (9, -27),
                            (-16, -9), (15, -8)]
    else:
        fragment_offsets = [(-6, -9), (6, -10), (-8, -5), (8, -6)]
    for index, (ox, oy) in enumerate(fragment_offsets):
        fx, fy = center + ox, baseline + oy
        color = CYAN if index % 2 == 0 else (AMBER if role == "enemy" else CRIMSON)
        put(out, fx, fy, color)
        put(out, fx + (1 if index % 3 else -1), fy, color)
        if index % 2 == 0:
            put(out, fx, fy - 1, color)

    # Small directional tells survive the collapse: the player's scarf/blade
    # and the siphonling's leading root remain on the side or rear silhouette.
    if role == "player":
        if direction == "left":
            for point in ((center - 8, baseline - 4), (center - 7, baseline - 4),
                          (center - 7, baseline - 3)):
                put(out, point[0], point[1], CRIMSON)
        elif direction == "right":
            for point in ((center + 7, baseline - 4), (center + 8, baseline - 4),
                          (center + 7, baseline - 3)):
                put(out, point[0], point[1], CRIMSON)
        elif direction == "up":
            for point in ((center + 4, baseline - 7), (center + 5, baseline - 7),
                          (center + 5, baseline - 6)):
                put(out, point[0], point[1], CRIMSON)
    elif role == "enemy":
        if direction == "left":
            put(out, center - 8, baseline - 2, CRIMSON)
            put(out, center - 9, baseline - 2, CRIMSON)
        elif direction == "right":
            put(out, center + 8, baseline - 2, CRIMSON)
            put(out, center + 9, baseline - 2, CRIMSON)
        elif direction == "up":
            put(out, center - 3, baseline - 7, CRIMSON)
            put(out, center + 3, baseline - 7, CRIMSON)
    return out


def generate(output_root: Path) -> list[Path]:
    output_root.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    jobs = [
        ("player", SPRITES / "player_sheet.png", 32, 30, "player"),
        ("enemy", SPRITES / "enemy_siphonling_sheet.png", 32, 30, "enemy"),
        ("boss", SPRITES / "venous_glutton_sheet.png", 64, 61, "venous_glutton"),
    ]
    for role, atlas, size, baseline, prefix in jobs:
        for direction in DIRECTIONS:
            row = DIR_INDEX[direction]
            base = extract_idle(atlas, size, row, baseline)
            for state in ("hurt", "death"):
                image = (apply_hurt(base, direction, baseline, role)
                         if state == "hurt" else
                         apply_death(base, direction, baseline, role, row))
                clean_components(image, minimum_size=2)
                reanchor(image, baseline)
                clean_components(image, minimum_size=2)
                # Force binary alpha and black RGB in transparent pixels.
                px = image.load()
                for y in range(size):
                    for x in range(size):
                        r, g, b, a = px[x, y]
                        if a:
                            px[x, y] = (r, g, b, 255)
                        else:
                            px[x, y] = (0, 0, 0, 0)
                if role == "enemy":
                    name = f"enemy_siphonling_{state}_{direction}.png"
                else:
                    name = f"{role}_{state}_{direction}.png"
                path = output_root / name
                image.save(path, "PNG", optimize=False)
                outputs.append(path)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output-root", type=Path,
        default=Path("/tmp/rhythm-directional-states"),
        help="directory for generated previews/runtime files",
    )
    args = parser.parse_args()
    paths = generate(args.output_root.resolve())
    print(f"DIRECTIONAL_STATES_GENERATED | {len(paths)} files | {args.output_root}")


if __name__ == "__main__":
    main()
