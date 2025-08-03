import argparse
from collections.abc import Sequence
from pathlib import Path
import sys

from PIL import Image

from ccps import CCPlane, CoverImage, HiddenImage


def get_extract_ccplane(arg: str | None) -> CCPlane | bool:
    if not arg:
        return True

    try:
        ccplane = CCPlane.from_str(arg)
    except ValueError as e:
        raise argparse.ArgumentTypeError(f"Invalid extract argument received, err: {e}")
    return ccplane


def get_cover_img_from_path(arg: str) -> CoverImage:
    try:
        cover = CoverImage(Image.open(arg).convert("RGB"))
    except Exception as e:
        raise ValueError(f"Failed to open cover image file, err: {e}")
    return cover


def get_img_to_hide(arg: str) -> tuple[Path, Image.Image | HiddenImage]:
    img_path = Path(arg)
    try:
        img: Image.Image | HiddenImage
        if not img_path.is_file():
            parts = arg.split(":")
            arg = "".join(parts[:-1])
            ccplane = CCPlane.from_str(parts[-1])
            img_path = Path(arg)
            img = Image.open(img_path)
            img = HiddenImage(ccplane, img)
        else:
            img = Image.open(img_path)
        return img_path, img
    except Exception as e:
        raise ValueError(f"Failed to open image to hide from '{img_path}', err: {e}")


def hide(
    cover_img: CoverImage,
    imgs_to_hide: list[tuple[Path, Image.Image | HiddenImage]],
    output_path: Path,
):
    for img_to_hide_path, img_to_hide in imgs_to_hide:
        if isinstance(img_to_hide, HiddenImage):
            himg = cover_img.embed_img_in_ccplane(img_to_hide.img, img_to_hide.ccplane)
        else:
            himg = cover_img.embed_img(img_to_hide)

        print(f"Hid '{img_to_hide_path}' in '{himg.ccplane}'")
    cover_img.img.save(output_path)
    print(f"Hid {len(imgs_to_hide)} images in cover image")
    print(f"Saved image with hidden images to '{output_path}'")


def extract(cover_img: CoverImage, ccplane: CCPlane | bool, output_path: Path):
    """Handle extraction out of the image"""
    output_path.mkdir(parents=True, exist_ok=True)
    ccplanes: list[CCPlane] = []

    # If they specify a specific plane to extract from, we only want to use that one; otherwise, we
    # want to extract out of all the valid planes to extract from.
    if isinstance(ccplane, CCPlane):
        ccplanes.append(ccplane)
    else:
        ccplanes = CoverImage.get_all_ccplanes()

    for ccplane, img in cover_img.extract_planes(ccplanes):
        save_path = output_path / f"{ccplane}.extracted.bmp"
        img.save(save_path)
        print(f"Extracted image from plane '{ccplane}' to '{save_path}'")

def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ccps", description="Color Component Steganography Tool"
    )
    _ = parser.add_argument(
        "-c",
        "--cover",
        type=get_cover_img_from_path,
        required=True,
        help="Path to the cover file",
        metavar="FILE",
    )
    _ = parser.add_argument(
        "-o",
        "--output",
        type=Path,
        required=True,
        help="""
        Output path.

        If extracting this should be a directory to place the extracted files into. If the directory does not exist, it will be created.

        If hiding, this will be the cover image that has hidden images embedded.
        """.strip(),
        metavar="PATH",
    )
    exc_grp = parser.add_mutually_exclusive_group(required=True)

    _ = exc_grp.add_argument(
        "-e",
        "--extract",
        type=get_extract_ccplane,
        const=True,
        nargs="?",
        metavar="[R|G|B][0-7] or None",
        help="""
        Whether to extract the black & white image color component planes from the provided cover image.

        If you wish to extract only a specific component plane, it can be chosen with the format <COLOR-LETTER><0-7>.
        For example, to extract from the 0th RED color component, you would provide R0. Valid letters are R, G, B and numbers 0-7.

        If there isn't an argument specified then it will extract all of the color component planes of the cover image.


        """.strip(),
    )

    _ = exc_grp.add_argument(
        "-H",
        "--hide",
        nargs="+",
        type=get_img_to_hide,
        help="""Hide mode with paths (max 23).

            If you want to embed in a specific component plane you can suffix the given path with :<COLOR-LETTER><0-7>. For example, a path like ./my-img.bmp:R0 would embed `my-img.bmp` in the red channel at plane 0. Valid color letters are R, G, B and the number may be 0-7 inclusive.

            If you decide to embed in a specific component plane, then all the images to hide must have a component plane specified as well.
            """.strip(),
        metavar="PATH or PATH:<COLOR-LETTER><0-7>",
    )

    args = parser.parse_args(argv)
    cover_img: CoverImage = args.cover

    # Additional hidden image to hide validation
    if args.hide:
        imgs_to_hide: list[tuple[Path, Image.Image | HiddenImage]] = args.hide
        if len(imgs_to_hide) > 23:
            parser.error("--hide accepts a maximum of 23 paths")

        for img_to_hide_path, img_to_hide in imgs_to_hide:
            if not cover_img.can_fit(img_to_hide):
                parser.error(
                    f"Cannot hide '{img_to_hide_path}' in cover image, dimensions are too large. \nCover image dimensions: {cover_img.img.size}\n{img_to_hide_path} dimensions: {img_to_hide.img.size if isinstance(img_to_hide, HiddenImage) else img_to_hide.size}"
                )

        # We want to ensure that if we are passed images to hide with specific color component
        # planes to embed into, that we ensure ALL of the images to hide specify a color component
        # plane. This avoids an icky situation where the user specifies a color component plane, but
        # then has their image to hide overriden during iteration later on and seemingly their image
        # to hide in that specific plane was never hidden.
        himgs = [img for img in imgs_to_hide if isinstance(img, HiddenImage)]
        if len(himgs) > 0 and len(himgs) != len(imgs_to_hide):
            parser.error(
                "It appears you're trying to hide images in specific component planes and unspecified bit planes. If you specify a component plane for a single image to hide, you must specify the component plane to hide in for all other images to hide!"
            )
    return args

def _run(args: argparse.Namespace):
    if args.hide:
        hide(args.cover, args.hide, args.output)

    if args.extract:
        extract(args.cover, args.extract, args.output)


def run():
    argv = sys.argv[1:]
    # By default, if we don't have any arguments we want to show the full help
    if len(argv) > 1:
        _run(parse_args(argv))
    else:
        _ = parse_args(['--help'])
