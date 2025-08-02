import pathlib
from PIL import Image
from os import listdir
from os.path import isfile, join

from ccps import CoverImage

script_dir = pathlib.Path(__file__).parent.resolve()
ASSETS_DIR = f"{script_dir}/assets/samples"

img_files_to_hide = [
    join(ASSETS_DIR, f) for f in listdir(ASSETS_DIR) if isfile(join(ASSETS_DIR, f))
]

output_dir = pathlib.Path(f"{script_dir}/output.ignore/")
output_dir.mkdir(parents=True, exist_ok=True)

original_img_path = f"{output_dir}/original.bmp"
embedded_img_path = f"{output_dir}/embedded.bmp"
image_to_hide_path = f"{output_dir}/image_to_hide.bmp"
cover = CoverImage(Image.open(f"{script_dir}/assets/samples/Simpsons_24.bmp"))
cover.img.save(original_img_path)

for img_to_hide_path in img_files_to_hide:
    img_to_hide = Image.open(img_to_hide_path).convert("RGB")
    embedded = cover.embed_img(img_to_hide)
    print(f"Embedded '{img_to_hide_path}' into '{embedded.ccplane}'")
    img_to_hide.save(f"{output_dir}/{embedded.ccplane}-ORIGINAL.bmp")
    embedded.img.save(f"{output_dir}/{embedded.ccplane}-EMBEDDED.bmp")


cover.img.save(embedded_img_path)

for ccplane, extracted_img in cover.extract_all_planes():
    extracted_img_save_path = f"{output_dir}/{ccplane}-EXTRACTED.bmp"
    print(f"Extracing '{ccplane}' to '{extracted_img_save_path}'")
    extracted_img.save(extracted_img_save_path)

print(f"Wrote output to '{output_dir}'")
