#!/usr/bin/env python3
"""Validate derived first-layer art before Godot imports or renders it."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"
EFFECTS = ROOT / "assets" / "effects"
OBJECTS = ROOT / "assets" / "objects"
BACKGROUNDS = ROOT / "assets" / "backgrounds"

DIRECTIONS = ("down", "left", "right", "up")
SHEETS = (
    (SPRITES / "spit_slug_sheet.png", (128, 128), 32, 4, 4),
    (SPRITES / "venous_glutton_sheet.png", (256, 256), 64, 4, 4),
    (EFFECTS / "mud_projectile_sheet.png", (128, 32), 32, 4, 1),
    (EFFECTS / "blood_sediment_hazard_sheet.png", (128, 32), 32, 4, 1),
)
SINGLES = (
    (OBJECTS / "heart_core_v2.png", (96, 96)),
    *((SPRITES / f"spit_slug_hurt_{direction}.png", (32, 32))
      for direction in DIRECTIONS),
    *((SPRITES / f"spit_slug_death_{direction}.png", (32, 32))
      for direction in DIRECTIONS),
    *((SPRITES / f"venous_glutton_hurt_{direction}.png", (64, 64))
      for direction in DIRECTIONS),
    *((SPRITES / f"venous_glutton_death_{direction}.png", (64, 64))
      for direction in DIRECTIONS),
)


def pixels(image: Image.Image):
    getter = getattr(image, "get_flattened_data", None)
    return getter() if getter is not None else image.getdata()


def check_rgba(path: Path, expected_size: tuple[int, int]) -> Image.Image:
    if not path.exists():
        raise AssertionError(f"missing runtime asset: {path.relative_to(ROOT)}")
    image = Image.open(path)
    if image.size != expected_size:
        raise AssertionError(
            f"{path.relative_to(ROOT)} size {image.size} != {expected_size}"
        )
    if image.mode != "RGBA":
        raise AssertionError(f"{path.relative_to(ROOT)} mode {image.mode} != RGBA")
    alpha_values = set(pixels(image.getchannel("A")))
    if not alpha_values <= {0, 255} or alpha_values != {0, 255}:
        raise AssertionError(
            f"{path.relative_to(ROOT)} alpha values are not binary foreground/background"
        )
    return image


def check_palette(image: Image.Image, label: str) -> None:
    opaque_colors = {(r, g, b) for r, g, b, a in pixels(image) if a}
    if not opaque_colors:
        raise AssertionError(f"{label} has no opaque pixels")
    if len(opaque_colors) > 32:
        raise AssertionError(f"{label} has {len(opaque_colors)} opaque colors")


def main() -> int:
    failures: list[str] = []
    try:
        background_path = BACKGROUNDS / "heartcore_forest_room.png"
        if not background_path.exists():
            raise AssertionError(f"missing runtime background: {background_path.relative_to(ROOT)}")
        background = Image.open(background_path)
        if background.size != (960, 540):
            raise AssertionError(
                f"{background_path.relative_to(ROOT)} size {background.size} != (960, 540)"
            )
        if background.mode not in {"RGB", "RGBA"}:
            raise AssertionError(
                f"{background_path.relative_to(ROOT)} mode {background.mode} is not RGB/RGBA"
            )
        for path, expected_size, frame_size, columns, rows in SHEETS:
            image = check_rgba(path, expected_size)
            for row in range(rows):
                for column in range(columns):
                    frame = image.crop((
                        column * frame_size,
                        row * frame_size,
                        (column + 1) * frame_size,
                        (row + 1) * frame_size,
                    ))
                    check_palette(frame, f"{path.name}[{column},{row}]")
        for path, expected_size in SINGLES:
            check_palette(check_rgba(path, expected_size), path.name)

        view_text = (ROOT / "scripts" / "mvp" / "mvp_room_view.gd").read_text(
            encoding="utf-8"
        )
        for required in (
            "spit_slug_sheet.png",
            "venous_glutton_sheet.png",
            "mud_projectile_sheet.png",
            "blood_sediment_hazard_sheet.png",
            "heart_core_v2.png",
        ):
            if required not in view_text:
                raise AssertionError(f"MvpRoomView does not reference {required}")
        if "venous_suction_sheet.png" in view_text:
            raise AssertionError("MvpRoomView still references the retired suction effect")
        controller_text = (
            ROOT / "scripts" / "mvp" / "mvp_controller.gd"
        ).read_text(encoding="utf-8")
        if "heart_core_v2.png" not in controller_text:
            raise AssertionError("MvpController ending does not reference heart_core_v2.png")

        manifest_path = ROOT / "assets" / "generated" / "bhai" / "derived_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        generated = {entry["path"] for entry in manifest["generated"]}
        if str(background_path.relative_to(ROOT)) not in generated:
            raise AssertionError(f"manifest omits {background_path.relative_to(ROOT)}")
        for path, *_ in SHEETS:
            if str(path.relative_to(ROOT)) not in generated:
                raise AssertionError(f"manifest omits {path.relative_to(ROOT)}")
        for path, _ in SINGLES:
            if str(path.relative_to(ROOT)) not in generated:
                raise AssertionError(f"manifest omits {path.relative_to(ROOT)}")
    except (AssertionError, OSError, ValueError, KeyError) as exc:
        failures.append(str(exc))

    if failures:
        for failure in failures:
            print(f"FIRST_LAYER_ASSETS_FAIL | {failure}", file=sys.stderr)
        return 1
    print(
        "FIRST_LAYER_ASSETS_OK | sheets states effects objects binary_alpha "
        "background_960x540 manifest runtime_references retired_suction_asset_absent no_elevator_room slug_death_down"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
