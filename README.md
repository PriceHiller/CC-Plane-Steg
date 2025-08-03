# RGB Color Component Steganography Project

Team Members:
- Price Hiller
- Kaitlyn Grace
- Sean Nicosia
- Kevin Pham

## Environment Configuration

Requires `Python3.13` or higher. `Python3.13` can be downloaded [here](https://www.python.org/downloads/release/python-3135/).

### Using [`pip`](https://pypi.org/project/pip/) (Note: `pip` comes with most Python installations)

- Head into the `src` diretory
- `python3 -m venv .venv`
- `source .venv/bin/activate`
- `pip install -r requirements.txt`

### Using [`uv`](https://docs.astral.sh/uv/)
- Head into the `src` directory
- `uv venv --clear `
- `source .venv/bin/activate`
- `uv sync`

You should now have a working virtual environment

## Example Usage

### Embedding
Issued from within the `src` directory:
```bash
python './main.py' \
  -H ./assets/samples/anime.bmp \
     ./assets/samples/bass.bmp \
     ./assets/samples/bee-flower.bmp \
     ./assets/samples/cartoon_pirate.bmp \
     ./assets/samples/chameleon.bmp \
     ./assets/samples/CoatCheck.jpg \
     ./assets/samples/hist_Flowers_08g.bmp_@0x0_z_001.bmp \
     ./assets/samples/mantis.bmp \
     ./assets/samples/MantisC_24.bmp \
     ./assets/samples/red-square.bmp \
     ./assets/samples/Rhino_08gA.bmp \
     ./assets/samples/Simpsons_24.bmp \
     ./assets/samples/SunsetTree_08gA.bmp \
  -c ./assets/samples/MantisC_24.bmp \
  -o ./out.bmp
```

`STDOUT` Output:

```
Hid 'assets/samples/anime.bmp' in 'R0'
Hid 'assets/samples/bass.bmp' in 'B0'
Hid 'assets/samples/bee-flower.bmp' in 'G0'
Hid 'assets/samples/cartoon_pirate.bmp' in 'R1'
Hid 'assets/samples/chameleon.bmp' in 'B1'
Hid 'assets/samples/CoatCheck.jpg' in 'G1'
Hid 'assets/samples/hist_Flowers_08g.bmp_@0x0_z_001.bmp' in 'R2'
Hid 'assets/samples/mantis.bmp' in 'B2'
Hid 'assets/samples/MantisC_24.bmp' in 'G2'
Hid 'assets/samples/red-square.bmp' in 'R3'
Hid 'assets/samples/Rhino_08gA.bmp' in 'B3'
Hid 'assets/samples/Simpsons_24.bmp' in 'G3'
Hid 'assets/samples/SunsetTree_08gA.bmp' in 'R4'
Hid 13 images in cover image
Saved image with hidden images to 'out.bmp'
```

### Extraction

Issued from within the `src` directory:

```bash
python './main.py' -c ./out.bmp -e -o ./output-path.ignore/
```

`STDOUT` Output:

```
Extracted image from plane 'R0' to 'output-path.ignore/R0.extracted.bmp'
Extracted image from plane 'G0' to 'output-path.ignore/G0.extracted.bmp'
Extracted image from plane 'B0' to 'output-path.ignore/B0.extracted.bmp'
Extracted image from plane 'R1' to 'output-path.ignore/R1.extracted.bmp'
Extracted image from plane 'G1' to 'output-path.ignore/G1.extracted.bmp'
Extracted image from plane 'B1' to 'output-path.ignore/B1.extracted.bmp'
Extracted image from plane 'R2' to 'output-path.ignore/R2.extracted.bmp'
Extracted image from plane 'G2' to 'output-path.ignore/G2.extracted.bmp'
Extracted image from plane 'B2' to 'output-path.ignore/B2.extracted.bmp'
Extracted image from plane 'R3' to 'output-path.ignore/R3.extracted.bmp'
Extracted image from plane 'G3' to 'output-path.ignore/G3.extracted.bmp'
Extracted image from plane 'B3' to 'output-path.ignore/B3.extracted.bmp'
Extracted image from plane 'R4' to 'output-path.ignore/R4.extracted.bmp'
Extracted image from plane 'G4' to 'output-path.ignore/G4.extracted.bmp'
Extracted image from plane 'B4' to 'output-path.ignore/B4.extracted.bmp'
Extracted image from plane 'R5' to 'output-path.ignore/R5.extracted.bmp'
Extracted image from plane 'G5' to 'output-path.ignore/G5.extracted.bmp'
Extracted image from plane 'B5' to 'output-path.ignore/B5.extracted.bmp'
Extracted image from plane 'R6' to 'output-path.ignore/R6.extracted.bmp'
Extracted image from plane 'G6' to 'output-path.ignore/G6.extracted.bmp'
Extracted image from plane 'B6' to 'output-path.ignore/B6.extracted.bmp'
Extracted image from plane 'R7' to 'output-path.ignore/R7.extracted.bmp'
Extracted image from plane 'G7' to 'output-path.ignore/G7.extracted.bmp'
Extracted image from plane 'B7' to 'output-path.ignore/B7.extracted.bmp'
```
