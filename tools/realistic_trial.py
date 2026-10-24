#!/usr/bin/env python3
"""The AI trial of the realistic mode (milestone R5, docs/realistic/research.md
section 6): a few pictures of the player's own Keen 1 graphics redrawn as
photographs by a diffusion model, each shown next to the original.

The input is the original pictures (enlarged by whole pixels, the user's
choice: not xBRZ), exported first with tools/export_graphics.gd into
exported/. A ControlNet "tile" model keeps the shapes, colours and places of
the original; img2img with a high strength lets the model replace the pixels
with real materials. Animation frames of one sprite go into one picture, so
that they get the same details (the flicker risk of section 10).

Everything it writes is derived from the game files: it goes to
exported/realistic_trial/ (ignored by git) and is never shared.

Usage (after `godot --headless --path . --script res://tools/export_graphics.gd`):
    python3 tools/realistic_trial.py [--only NAME] [--steps 6] [--device cpu|mps|cuda]

Needs: torch, diffusers, transformers, accelerate, peft, safetensors, pillow,
and the models from Hugging Face (downloaded once, about 4 GB):
Realistic Vision 5.1 (a photographic Stable Diffusion 1.5), its VAE, the
ControlNet tile model and the LCM LoRA (few steps, so it runs on a CPU).
"""

import argparse
import sys
import time
from pathlib import Path

from PIL import Image

BASE_MODEL = "SG161222/Realistic_Vision_V5.1_noVAE"
VAE_MODEL = "stabilityai/sd-vae-ft-mse"
CONTROLNET_MODEL = "lllyasviel/control_v11f1e_sd15_tile"
LCM_LORA = "latent-consistency/lcm-lora-sdv1-5"

EXPORTED = Path("exported")
OUT = EXPORTED / "realistic_trial"
TILE = 16
# Sizes the model works in are multiples of this.
MODEL_STEP = 64
# Sprites are laid on this grey, which the model reads as a studio backdrop.
SPRITE_BACKDROP = (128, 128, 128, 255)
SEED = 1234

NEGATIVE = (
    "pixel art, cartoon, drawing, illustration, painting, 3d render, video game, "
    "blurry, lowres, jpeg artifacts, text, watermark, signature"
)

# Each trial picture: a crop of a level (x, y, width, height in game pixels)
# or a row of sprites, a prompt, and how strongly the model may change it.
ITEMS = {
    "level01_start": {
        "level": "level01.png",
        "crop": (0, 144, 384, 192),
        "prompt": (
            "photograph of an abandoned alien outpost on Mars at night, chrome pillars, "
            "a stack of steel barrels, red rocky ground, starry sky, cinematic lighting, "
            "highly detailed, photorealistic, 35mm"
        ),
    },
    "level05_lamp": {
        "level": "level05.png",
        "crop": (0, 368, 384, 192),
        "prompt": (
            "photograph of a dark stone cave, a ceiling lamp casting a cone of light on a "
            "pyramid of steel barrels, a magenta metal door, dramatic light, photorealistic, "
            "highly detailed"
        ),
    },
    "level11_fire": {
        "level": "level11.png",
        "crop": (0, 176, 384, 192),
        "prompt": (
            "photograph of a dark brick dungeon, real fire burning on a ledge, studded steel "
            "blocks, red stone floor, warm firelight, photorealistic, highly detailed"
        ),
    },
    "world_map": {
        "level": "level80.png",
        "crop": (120, 330, 384, 192),
        "prompt": (
            "aerial photograph of the red desert of Mars, canyons, dry riverbeds, small domed "
            "buildings, satellite photo, photorealistic, highly detailed"
        ),
    },
    "keen_walking": {
        "sprites": ["000_KEENWALKR1", "001_KEENWALKR2", "002_KEENWALKR3", "003_KEENWALKR4"],
        "prompt": (
            "photograph of the same eight year old boy four times, yellow american football "
            "helmet, purple t-shirt, blue jeans, red sneakers, walking to the right, full "
            "body, grey studio backdrop, photorealistic"
        ),
    },
    "yorp": {
        "sprites": ["048_YORPSTAND1", "052_YORPRIGHT1", "053_YORPRIGHT2", "056_YORPSTUN1"],
        "prompt": (
            "photograph of the same small green alien creature four times, one big eye on a "
            "stalk, round body, short legs, rubbery skin, grey studio backdrop, photorealistic"
        ),
    },
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--only", help="make only this item (" + ", ".join(ITEMS) + ")")
    parser.add_argument("--steps", type=int, default=6)
    parser.add_argument("--strength", type=float, default=0.75, help="how much may change")
    parser.add_argument("--control", type=float, default=0.8, help="how close to the shapes")
    parser.add_argument("--scale", type=int, default=2, help="game pixel -> model pixels")
    parser.add_argument("--device", default="cpu")
    parser.add_argument("--tag", default="", help="added to the file names, to keep variants")
    args = parser.parse_args()

    names = [args.only] if args.only else list(ITEMS)
    for name in names:
        if name not in ITEMS:
            print(f"Unknown item {name}", file=sys.stderr)
            return 1
    if not (EXPORTED / "levels").is_dir():
        print("Export the graphics first: tools/export_graphics.gd", file=sys.stderr)
        return 1
    pipe = load_pipeline(args.device)
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names:
        started = time.time()
        original, mask = trial_input(ITEMS[name], args.scale)
        result = redraw(pipe, original, ITEMS[name]["prompt"], args)
        if mask is not None:
            backdrop = Image.new("RGB", result.size, SPRITE_BACKDROP[:3])
            result = Image.composite(result, backdrop, mask)
        path = OUT / f"{name}{args.tag}.png"
        side_by_side(original, result).save(path)
        print(f"{name}: {time.time() - started:.0f} s -> {path}")
    return 0


def load_pipeline(device: str):
    import torch
    from diffusers import (
        AutoencoderKL,
        ControlNetModel,
        LCMScheduler,
        StableDiffusionControlNetImg2ImgPipeline,
    )

    dtype = torch.float32 if device == "cpu" else torch.float16
    controlnet = ControlNetModel.from_pretrained(CONTROLNET_MODEL, torch_dtype=dtype)
    vae = AutoencoderKL.from_pretrained(VAE_MODEL, torch_dtype=dtype)
    pipe = StableDiffusionControlNetImg2ImgPipeline.from_pretrained(
        BASE_MODEL, controlnet=controlnet, vae=vae, torch_dtype=dtype, safety_checker=None
    )
    pipe.scheduler = LCMScheduler.from_config(pipe.scheduler.config)
    pipe.load_lora_weights(LCM_LORA)
    pipe.fuse_lora()
    pipe.set_progress_bar_config(disable=True)
    return pipe.to(device)


def trial_input(item: dict, scale: int):
    """The original picture of [item] enlarged by whole pixels, and for
    sprites the mask of what is drawn (None for a level)."""
    if "level" in item:
        level = Image.open(EXPORTED / "levels" / item["level"]).convert("RGB")
        x, y, width, height = item["crop"]
        picture = level.crop((x, y, x + width, y + height))
        return fit(picture.resize((width * scale, height * scale), Image.NEAREST)), None
    frames = [Image.open(EXPORTED / "sprites" / f"{name}.png").convert("RGBA") for name in item["sprites"]]
    cell = (max(f.width for f in frames) + TILE, max(f.height for f in frames) + TILE)
    sheet = Image.new("RGBA", (cell[0] * len(frames), cell[1]), SPRITE_BACKDROP)
    alpha = Image.new("L", sheet.size, 0)
    for index, frame in enumerate(frames):
        place = (index * cell[0] + (cell[0] - frame.width) // 2, (cell[1] - frame.height) // 2)
        sheet.alpha_composite(frame, place)
        alpha.paste(frame.getchannel("A"), place)
    sprite_scale = scale * 4
    size = (sheet.width * sprite_scale, sheet.height * sprite_scale)
    picture = fit(sheet.convert("RGB").resize(size, Image.NEAREST))
    mask = fit(alpha.resize(size, Image.NEAREST))
    return picture, mask


def fit(picture: Image.Image) -> Image.Image:
    """[picture] grown to the next multiple of MODEL_STEP, filled at the edge."""
    width = -(-picture.width // MODEL_STEP) * MODEL_STEP
    height = -(-picture.height // MODEL_STEP) * MODEL_STEP
    if (width, height) == picture.size:
        return picture
    grown = Image.new(picture.mode, (width, height))
    grown.paste(picture, (0, 0))
    return grown


def redraw(pipe, picture: Image.Image, prompt: str, args) -> Image.Image:
    import torch

    generator = torch.Generator("cpu").manual_seed(SEED)
    return pipe(
        prompt=prompt,
        negative_prompt=NEGATIVE,
        image=picture,
        control_image=picture,
        strength=args.strength,
        controlnet_conditioning_scale=args.control,
        num_inference_steps=args.steps,
        guidance_scale=1.5,
        width=picture.width,
        height=picture.height,
        generator=generator,
    ).images[0]


def side_by_side(original: Image.Image, result: Image.Image) -> Image.Image:
    both = Image.new("RGB", (original.width * 2, original.height))
    both.paste(original.convert("RGB"), (0, 0))
    both.paste(result.convert("RGB").resize(original.size), (original.width, 0))
    return both


if __name__ == "__main__":
    sys.exit(main())
