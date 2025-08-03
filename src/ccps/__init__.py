from collections.abc import Generator, Iterable
from PIL import Image
from dataclasses import dataclass, field
from enum import Enum
import itertools
import typing
from typing import NamedTuple, Self, override

from ccps.bitmanip import embed_bit, extract_bit


class ColorComponent(Enum):
    RED = "R"
    GREEN = "G"
    BLUE = "B"

    @classmethod
    def from_str(cls, component: str) -> Self:
        component = component.upper()
        if component == "R" or component == "RED":
            return cls(cls.RED)
        elif component == "G" or component == "GREEN":
            return cls(cls.GREEN)
        elif component == "B" or component == "BLUE":
            return cls(cls.BLUE)
        else:
            raise ValueError(f"Component must be of R, G, or B, received: {component}")

    @override
    def __str__(self) -> str:
        return self.value


@dataclass()
class CCPlane:
    """A Color Component Plane"""

    color: ColorComponent
    plane: int

    def validate(self):
        if self.plane < 0 or self.plane > 7:
            raise ValueError(
                f"Plane must between 0 and 7 inclusive, received: '{self.plane}'"
            )

    @classmethod
    def from_str(cls, input: str) -> Self:
        if len(input) != 2:
            raise ValueError(
                f"Invalid input string to convert into CCPlane, received: '{input}'"
            )

        letter = input[0]
        try:
            color_component = ColorComponent.from_str(letter)
        except ValueError as e:
            raise ValueError(
                f"Invalid first letter for plane color component, err: {e}"
            )

        plane = input[1]
        if not plane.isdecimal() or int(plane) < 0 or int(plane) > 7:
            raise ValueError(
                f"Invalid second letter for plane number, expected a number from 0-7 inclusive, received: '{plane}'"
            )
        plane = int(plane)

        return cls(color_component, plane)

    def __post_init__(self):
        self.validate()

    @override
    def __str__(self) -> str:
        return f"{self.color}{self.plane}"


def extract_bits_from_component_plane(
    img: Image.Image, component: ColorComponent | str, plane: int
) -> list[int]:
    if isinstance(component, str):
        component = ColorComponent.from_str(component)

    if img.mode != "RGB":
        raise ValueError("Image mode must be 'RGB")

    pixels = img.load()  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
    if not pixels:
        raise RuntimeError("Unable to get pixels for image to extract from!")

    bits: list[int] = []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = typing.cast(tuple[int, int, int], pixels[x, y])
            if component == ColorComponent.RED:
                extracted_bit = extract_bit(r, plane)
            elif component == ColorComponent.GREEN:
                extracted_bit = extract_bit(g, plane)
            elif component == ColorComponent.BLUE:
                extracted_bit = extract_bit(b, plane)
            bits.append(extracted_bit)

    return bits


def convert_img_to_bw(img: Image.Image, bw_threshold: int = 384) -> Image.Image:
    # Convert to RGB first to ensure we have a valid Red, Green, and Blue channel to evaluate
    img = img.convert("RGB")

    pixels = img.load()  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
    if not pixels:
        raise RuntimeError("Unable to get pixels for image to extract from!")

    bw_bits: list[int] = []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = typing.cast(tuple[int, int, int], pixels[x, y])
            bw_bits.append(int(r + g + b > bw_threshold))

    new_img = Image.new("1", img.size)
    new_img.putdata(bw_bits)  # pyright: ignore[reportUnknownMemberType]
    return new_img


def embed_bw_in_cover(
    cover_img: Image.Image, img_to_embed: Image.Image, ccplane: CCPlane
):
    if (
        cover_img.size[0] < img_to_embed.size[0]
        or cover_img.size[1] < img_to_embed.size[1]
    ):
        raise ValueError(
            f"The image to be embedded has dimensions that exceed the cover image. Cover image dimensions: '{cover_img.size}' | Image to embed dimensions: '{img_to_embed.size}'"
        )

    if img_to_embed.mode != "1":
        raise ValueError("Image to embed mode must be '1' (black and white)")

    if cover_img.mode != "RGB":
        raise ValueError("Cover image mode must be 'RGB'")

    cover_img_pixels = cover_img.load()  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
    if not cover_img_pixels:
        raise RuntimeError("Unable to get pixels for cover image!")

    img_to_embed_pixels = img_to_embed.load()  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
    if not img_to_embed_pixels:
        raise RuntimeError("Unable to get pixels for image to embed!")

    for y in range(img_to_embed.height):
        for x in range(img_to_embed.width):
            cover_R, cover_G, cover_B = typing.cast(
                tuple[int, int, int], cover_img_pixels[x, y]
            )
            bw_pixel: int = typing.cast(int, img_to_embed_pixels[x, y])
            if ccplane.color == ColorComponent.RED:
                cover_R = embed_bit(cover_R, ccplane.plane, bw_pixel)
            elif ccplane.color == ColorComponent.GREEN:
                cover_G = embed_bit(cover_G, ccplane.plane, bw_pixel)
            elif ccplane.color == ColorComponent.BLUE:
                cover_B = embed_bit(cover_B, ccplane.plane, bw_pixel)
            cover_img_pixels[x, y] = (cover_R, cover_G, cover_B)


def extract_from_cover_image(cover_img: Image.Image, ccplane: CCPlane) -> Image.Image:
    ext_data = extract_bits_from_component_plane(
        cover_img, ccplane.color, ccplane.plane
    )
    ext_img = Image.new("1", cover_img.size)
    ext_img.putdata(ext_data)  # pyright: ignore[reportUnknownMemberType]
    return ext_img


class HiddenImage(NamedTuple):
    ccplane: CCPlane
    img: Image.Image


@dataclass()
class CoverImage:
    """A Cover image class to help with embedding and extracting images

    Attributes:
        img: The cover image
        ccplanes: The list of color component planes that can be embedded into. Embedding will start from the first element in the list. If unspecified, a reasonable default is provided.
    """

    img: Image.Image
    ccplanes: list[CCPlane] = field(default_factory=list)

    def __post_init__(self):
        if len(self.ccplanes) == 0:
            self.ccplanes = self.get_embeddable_ccplanes()

        dups = [dup for dup in self.ccplanes if self.ccplanes.count(dup) >= 2]
        if len(dups) != 0:
            raise ValueError("Provided ccplanes had duplicate entries!")

    @classmethod
    def get_embeddable_ccplanes(cls) -> list[CCPlane]:
        embeddable_component_planes = list(
            itertools.product(
                (0, 1, 2, 3, 4, 5, 6, 7),
                # Doing this weird ordering below ensures the last green color component plane comes
                # last so it's easy to remove
                #
                # We don't want to embed into the last green color component plane as the human eye
                # responds most strongly to green
                (ColorComponent.RED, ColorComponent.BLUE, ColorComponent.GREEN),
            )
        )[:-1]

        embeddable_component_planes = [
            CCPlane(ccp[1], ccp[0]) for ccp in embeddable_component_planes
        ]
        return embeddable_component_planes

    @classmethod
    def get_all_ccplanes(cls) -> list[CCPlane]:
        embeddable_component_planes = list(
            itertools.product(
                (0, 1, 2, 3, 4, 5, 6, 7),
                (ColorComponent.RED, ColorComponent.GREEN, ColorComponent.BLUE),
            )
        )

        embeddable_component_planes = [
            CCPlane(ccp[1], ccp[0]) for ccp in embeddable_component_planes
        ]
        return embeddable_component_planes

    def embed_img(self, img: Image.Image) -> HiddenImage:
        if len(self.ccplanes) == 0:
            raise RuntimeError("No remaining embeddable ccplanes to embed into!")

        ccplane = self.ccplanes.pop(0)
        bw_img = convert_img_to_bw(img)
        embed_bw_in_cover(self.img, bw_img, ccplane)
        return HiddenImage(ccplane, bw_img)

    def extract_all_planes(self) -> Generator[HiddenImage, None, None]:
        for ccplane in self.get_all_ccplanes():
            extracted_img = extract_from_cover_image(self.img, ccplane)
            yield HiddenImage(ccplane, extracted_img)

    def extract_planes(
        self, ccplanes: Iterable[CCPlane]
    ) -> Generator[HiddenImage, None, None]:
        for ccplane in ccplanes:
            extracted_img = extract_from_cover_image(self.img, ccplane)
            yield HiddenImage(ccplane, extracted_img)

    def extract_plane(self, ccplane: CCPlane) -> Image.Image:
        return extract_from_cover_image(self.img, ccplane)

    def embed_img_in_ccplane(self, img: Image.Image, ccplane: CCPlane) -> HiddenImage:
        bw_img = convert_img_to_bw(img)
        embed_bw_in_cover(self.img, bw_img, ccplane)
        return HiddenImage(ccplane, bw_img)

    def can_fit(self, img: Image.Image | HiddenImage) -> bool:
        if isinstance(img, HiddenImage):
            img = img.img
        return img.size[0] <= self.img.size[0] and img.size[1] <= self.img.size[1]
