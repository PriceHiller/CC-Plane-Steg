#let gold = rgb("#ffc500")
#set text(font: "Calibri", size: 12.5pt)
#show link: set text(blue)
#show cite: set text(blue)
#let gradient_fill = (
  color.hsl(230deg, 60%, 20%),
  color.hsl(225deg, 60%, 15%),
  color.hsl(220deg, 60%, 15%),
  color.hsl(220deg, 60%, 15%),
  color.hsl(220deg, 60%, 15%),
  color.hsl(220deg, 60%, 15%),
  color.hsl(210deg, 60%, 15%),
  color.hsl(210deg, 80%, 20%),
)
#let imageonside(
  lefttext,
  rightimage,
  bottomtext: none,
  marginleft: 0em,
  margintop: 0.5em,
) = {
  set par(justify: true)
  grid(
    columns: 2,
    column-gutter: 1em,
    lefttext, rightimage,
  )
  set par(justify: false)
  block(inset: (left: marginleft, top: -margintop), bottomtext)
}

#show heading: header => {
  let heading_level = str(header.level)
  let heading_map = (
    "1": (bgfill: gold, textfill: black),
    "2": (bgfill: rgb("#00265E"), textfill: white),
    "3": (bgfill: red.darken(50%), textfill: white),
  )
  let (bgfill, textfill) = heading_map.at(str(heading_level))
  block(inset: (x: 8pt, y: 8pt), radius: 30%, fill: bgfill, text(
    font: "Roboto",
    fill: textfill,
    tracking: .1pt,
    weight: "black",
  )[#header.body])
}

#let accent_font = "IBM Plex Sans"
#let title = [A Novel Data Embedding Method in RGB Color Component Bit Planes]
#set page(
  "us-letter",
  margin: (x: .5in, top: 0.70in, bottom: .5in),
  header: context if here().page() > 1 {
    align(center + horizon, box(
      width: page.width + 4em,
      height: 100%,
      fill: gradient.linear(..gradient_fill),
      [
        #place(left + horizon, dx: +page.margin.left + 10pt)[
          #text(size: 1.1em, fill: gold, font: accent_font, weight: "black")[Steganography Project],
          #text(size: 1.1em, fill: white)[#title],
        ]
        #let icon_size = 45%
        #place(
          right + horizon,
          dx: -page.margin.left,
          box(
            baseline: icon_size,
          ),
        )
      ],
    ))
  },
  footer: context if here().page() > 1 {
    text(size: 0.8em, fill: color.luma(35%), [
      #v(.75em)
      Steganography Final Report | CS 4463-01T | Team 2
      #h(1fr)

      #{
        here().page() - 1
      }
    ])
    align(center + bottom, block(
      width: page.width + 10pt,
      height: 20%,
      fill: gradient.linear(..gradient_fill),
    ))
  },
)

// COVER PAGE

#set page(background: context if here().page() == 1 {
  box(
    fill: gradient.linear(angle: 60deg, ..gradient_fill),
    width: 100%,
    height: 100%,
  )

  place(top + center, rect(width: 100%, height: 100%, fill: tiling(
    size: (18pt, 18pt),
    place(dy: 3pt, dx: 1pt, circle(
      radius: 3.5pt,
      fill: blue.darken(65%),
    )),
  )))

  let globe = read("./assets/globe.svg").replace(
    "#000000",
    blue.darken(40%).to-hex(),
  )
  place(bottom + right, dy: 70pt, dx: 120pt, rotate(-20deg, image(
    bytes(globe),
    height: 600pt,
  )))


  let darken_amount = 15%
  place(top + right, stack(dir: btt, ..{
    let rect_height = 30pt
    (
      rect(width: 50pt, height: rect_height, fill: red.darken(
        darken_amount + 10%,
      )),
      rect(width: 75pt, height: rect_height, fill: gold.darken(darken_amount)),
      rect(width: 100pt, height: rect_height, fill: blue.darken(darken_amount)),
    )
  }))

  place(horizon + left, rect(
    fill: blue.darken(darken_amount),
    height: 100%,
    width: 8pt,
  ))
})

#context {
  let icon_size = 36pt
  place(left + top, align(horizon, grid(
    columns: 1,
    row-gutter: 10pt,
    text(
      size: 1.3em,
      font: accent_font,
      fill: gold,
      weight: "black",
    )[
      Price Hiller\
      Kevin Pham\
      Joseph Baca\
      Kaitlyn Grace\
    ],
    text(size: 1.10em, font: accent_font, fill: gold.darken(10%))[
      Project Group 2\
    ],
  )))
  place(center + horizon, box(width: page.width / 1.08, text(
    font: "Roboto",
    size: 5em,
    fill: blue.lighten(75%),
    weight: "black",
  )[#title]))

  place(left + bottom, dx: 20pt, dy: page.margin.bottom - 20pt, text(
    size: 1em,
    fill: blue.lighten(95%),
    style: "italic",
  )[
    Steganography CS-4643-01T\
    August 7th, 2025
  ])
}

#pagebreak()

= Introduction

In this project, we developed a program which embeds multiple images within the individual bit planes of each color component in a 24-bit color bitmap. To accomplish this, the program converts input images to black and white and then embeds each image in a single color component bit plane by distributing its bits across the plane linearly. This means treating each of the red, green, and blue components as individual bit planes @improved-lsb-rgb. This allows up to 23 images to be hidden if we preserve a single color component bit plane of the cover image. The goal of this project was to implement a novel technique for concealing multiple images within a single bitmap file, maximizing hiding capacity.

We conducted an analysis on the output to determine the effectiveness of our method, including the visual detectability of the embedded data. This analysis will also discuss the techniques involved with this method, difficulties we faced in development, suggestions for improvement in the future, as well as examples of the finished product.

= Functional Block Diagram

#align(center)[#image("./assets/CC-Plane-Embedding-BD.svg", height: 90%)]

#align(center)[#image("./assets/CC-Plane-Extraction-BD.svg", height: 90%)]

= Algorithm: Hiding & Extraction


== Hiding

The main method of hiding in this project is using similar patterns as Least Significant Bit (LSB) bit-plane-based Steganography @lsb-steg-explore. It takes each input image to hide, converts it to a black-and-white image (another technique described below), and embeds it within a individual bit-plane of an unused color component in the 24-bit color bitmap cover image. The target bit within the bit-plane of the chosen color channel is replaced with a bit from one of the black-and-white images. This is repeated until the black-and-white images are completely embedded. This allows up to 23 images to be embedded within the cover image as we reserve the most significant green color component bit plane of the cover image.

Another technique used in this program is to use threshold-based conversion on the pixels within the images to be hidden. The color component value of each pixel is summed and then compared against a threshold to determine if that pixel qualifies as a black or white pixel in the converted black-and-white embedded image. The pixel's summed value must be more than 384 to qualify as a white pixel, otherwise it will embed as a black pixel. Once this finishes, the image that is embedded into the cover is entirely black-and-white and is placed across a single color bit plane as discussed above.

A micro-optimization made to slightly reduce perceptibility in the implemented program is the reservation of the most significant green color component bit plane as discussed previously. The human visual system perceives green strongest and thus the most impactful green colors in the image are preserved from the cover in an attempt to improve security. @visual-sensitivty

== Extraction

Extraction is much more straightforward. Unless like normal bit plane extraction, we slice the image up into 24 separate planes, 8 color bit planes per color component. We then extract each individual color component bit plane as a single black and white image where a bit value of 0 is black and a bit value of 1 is white. We then append each bit into its corresponding color component plane file, e.g. `B2.bmp` for the 2nd bit plane in the blue component.

#pagebreak()


= Technical Difficulties

== Performance

One of the primary challenges that we encountered in the development of this program was performance. Initially, it took nearly or over twenty seconds to embed and extract a single bit-plane, which made for an inefficient implementation.

== Writing the Image Data

Originally, the implementation of this program involved passing full black-and-white byte values to the Python Imaging Library (`PIL`), with each bit representing an individual pixel. However, this led to distorted output images. This meant the image data had to be written back to the disk in the correct format. It took several hours of trial and error to find that feeding individual bits rather than grouped byte values outputs correct results.

== Dependency Management

Writing in Python proved to have its own challenges. Dependency management within Python’s ecosystem turned out to be frustrating and time-consuming.

== Black-and-White Images

Determining the threshold for what makes a black or white pixel when converting images to be hidden was yet another challenge we faced in the development of this project. The original threshold of 383 left pixels with exactly half luminosity as white pixels, which made existing histogram images lose their inner gray bars when embedded and extracted. Raising the threshold to 384 caused the pixels to be rendered as black instead of white, which improved the histograms we embedded.

#pagebreak()
= Suggestions for Future Work

A possible future feature could be implementing an algorithm that changes the order of the images to preserve the most cover image data as possible in order to decrease the visual and possibly data analytical perceptibility. Another way to decrease visual perceptibility would be to encode our data in a spiral as well as arrange our data in a way that it weights the amount of images hidden in each color channel based on the color composition of the color image to account for human visual perception @visual-sensitivty.

Currently our histograms for our cover images containing higher quantities of hidden images have a significant spike at 0. Determining an improved algorithm to convert images to black and white, or possibly determining a system to invert some of the black and white embedded images could reduce the 0 spike in the histogram. Additionally, we could analyze the encoded image with visual metrics as well, such as SSIM, PSNR and MSE to evaluate the perceptibility of the modifications in our steganographic images.

#block(breakable: false)[
  = Example Images With Data Hidden
  == Sunset Tree
  === Image Set
  #let width = 100%
  #v(-.25em)
  #grid(
    columns: 2,
    column-gutter: 5pt,
    row-gutter: 5pt,
    align: center,
    [
      #figure(
        image("./assets/Final-Report/sunset-tree-original.png", width: width),
        caption: "Sunset Tree Original Image",
      )
    ],
    [
      #figure(
        image("assets/Final-Report/sunset-tree-5.png", width: width),
        caption: "Sunset Tree With 5 Images Embedded",
      )
    ],

    [
      #figure(
        image("assets/Final-Report/sunset-tree-9.png", width: width),
        caption: "Sunset Tree With 9 Images Embedded",
      )
    ],
    [
      #figure(
        image("assets/Final-Report/sunset-tree-14.png", width: width),
        caption: "Sunset Tree With 14 Images Embedded",
      )
    ],

    [
      #figure(
        image("assets/Final-Report/sunset-tree-20.png", width: width),
        caption: "Sunset Tree With 20 Images Embedded",
      )
    ],
    [
      #figure(
        image("assets/Final-Report/sunset-tree-23.png", width: width),
        caption: "Sunset Tree With 23 (Max) Images Embedded",
      )
    ],
  )
]


#block(breakable: false)[
  #let width = 55%
  === Histograms
  #v(-.5em)
  #grid(
    columns: 2,
    column-gutter: 5pt,
    row-gutter: 5pt,
    align: center,
    [
      #figure(
        image(
          "assets/Final-Report/histograms/hist_sunset-tree-original.png_@0x0_z_001.bmp.png",
          width: width,
        ),
        caption: "Sunset Tree Original Image",
      )
    ],
    [
      #figure(
        image(
          "assets/Final-Report/histograms/hist_sunset-tree-5.png_@0x0_z_001.bmp.png",
          width: width,
        ),
        caption: "Sunset Tree With 5 Images Embedded",
      )
    ],

    [
      #figure(
        image(
          "assets/Final-Report/histograms/hist_sunset-tree-9.png_@0x0_z_001.bmp.png",
          width: width,
        ),
        caption: "Sunset Tree With 9 Images Embedded",
      )
    ],
    [
      #figure(
        image(
          "assets/Final-Report/histograms/hist_sunset-tree-14.png_@0x0_z_001.bmp.png",
          width: width,
        ),
        caption: "Sunset Tree With 14 Images Embedded",
      )
    ],

    [
      #figure(
        image(
          "assets/Final-Report/histograms/hist_sunset-tree-20.png",
          width: width,
        ),
        caption: "Sunset Tree With 20 Images Embedded",
      )
    ],
    [
      #figure(
        image(
          "assets/Final-Report/histograms/hist_sunset-tree-23.png",
          width: width,
        ),
        caption: "Sunset Tree With 23 Images Embedded",
      )
    ],
  )
]

#block(breakable: false)[
  == Mantis
  === Image Set
  #let width = 100%
  #v(-.25em)
  #grid(
    columns: 2,
    column-gutter: 5pt,
    row-gutter: 5pt,
    align: center,
    [

      #figure(
        image("assets/Final-Report/mantis-original.png", width: width),
        caption: "Mantis Original Image",
      )
    ],
    [
      #figure(
        image("assets/Final-Report/mantis-4.png", width: width),
        caption: "Mantis With 4 Images Embedded",
      )
    ],

    [
      #figure(
        image("assets/Final-Report/mantis-8.png", width: width),
        caption: "Mantis With 8 Images Embedded",
      )
    ],
    [
      #figure(
        image("assets/Final-Report/mantis-12.png", width: width),
        caption: "Mantis With 12 Images Embedded",
      )
    ],

    [
      #figure(
        image("assets/Final-Report/mantis-20.png", width: width),
        caption: "Mantis With 20 Images Embedded",
      )
    ],
    [
      #figure(
        image("assets/Final-Report/mantis-23.png", width: width),
        caption: "Mantis With 23 (Max) Images Embedded",
      )
    ],
  )
]


#block(breakable: false)[
  #let width = 55%
  === Histograms
  #v(-.5em)
  #grid(
    columns: 2,
    column-gutter: 5pt,
    row-gutter: 5pt,
    align: center,
    [
      #figure(
        image(
          "./assets/Final-Report/histograms/mantis_original_hist.png",
          width: width,
        ),
        caption: "Mantis Original Image",
      )
    ],
    [
      #figure(
        image(
          "./assets/Final-Report/histograms/mantis_4_hist.png",
          width: width,
        ),
        caption: "Mantis With 4 Images Embedded",
      )
    ],

    [
      #figure(
        image(
          "./assets/Final-Report/histograms/mantis_8_hist.png",
          width: width,
        ),
        caption: "Mantis With 8 Images Embedded",
      )
    ],
    [
      #figure(
        image(
          "./assets/Final-Report/histograms/mantis_12_hist.png",
          width: width,
        ),
        caption: "Mantis With 12 Images Embedded",
      )
    ],

    [
      #figure(
        image(
          "./assets/Final-Report/histograms/mantis_20_hist.png",
          width: width,
        ),
        caption: "Mantis With 20 Images Embedded",
      )
    ],
    [
      #figure(
        image(
          "assets/Final-Report/histograms/mantis_23_hist.png",
          width: width,
        ),
        caption: "Mantis With 23 Images Embedded",
      )
    ],
  )
]

== Some Sample Embedded & Extracted Images

#align(center)[
  #let height = 30%
  #grid(
    columns: 2,
    column-gutter: 5pt,
    align: center,
    [
      #figure(
        image(
          "./assets/Final-Report/cartoon_pirate.bmp.png",
          height: height,
        ),
        caption: "Original Pirate Image",
      )
    ],
    [
      #figure(
        image(
          "./assets/Final-Report/sample-ex-1.png",

          height: height,
        ),
        caption: "Extracted Pirate Image from Mantis",
      )
    ],
  )
  #grid(
    columns: 2,
    column-gutter: 30pt,
    align: center,
    [
      #figure(
        image(
          "./assets/Final-Report/anime.bmp.png",
          width: 100%,
        ),
        caption: "Original Anime Image",
      )
    ],
    [
      #figure(
        image(
          "assets/Final-Report/sample-ex-2.png",
          width: 100%,
        ),
        caption: "Extracted Anime Image from Sunset Tree",
      )
    ],
  )
]

#pagebreak()

= Statistical Analysis Results

Our hiding technique allowed for a significantly higher capacity of images to be embedded within a single 24-bit cover image, permitting up to 23 images to be embedded within the cover. Capacity in our technique is best understood not in terms of the number of bits or bytes embedded; rather, going by how many images can be embedded is what is relevant. So long as the images to be hidden have dimensions that are less than the cover, they can be embedded. Thus, the capacity is 23 correctly sized images. To understand it as a ratio then, if we had images we were to embed that all matched dimensions of the cover image, we could embed into 95.8% of the cover image's size in bits.


$
  23 "available planes to embed in" ÷ 24 "total planes" ≈ 0.958
$

Our technique had a fairly low perceptibility rate, with cover images subjectively exceeding acceptable perceptibility when around 14 of the 23 available planes to embed in were used. This varied based on the complexity of the image of course. If you review the earlier images in this paper, the Mantis embeddings had little to no perceptibility at around 12 images; whereas the Sunset Tree samples were exceeding perceptibility thresholds around 9 images embedded.

Considering the histograms of the samples, this technique clearly fails to pass histogram analysis even with only a handful of images embedded. Large peaks began to build early in the histogram at low values, likely as a result of the black-and-white conversion process leading to larger quantities of straight 1s and 0s across planes. However, histogram analysis did not reveal absolutely blatant plateaus and cliffs across the histogram like normal LSB techniques would create. With additional methods or embedding regimens to smooth out the early peaks, this embedding technique has a fairly strong chance of bypassing cursory histogram analysis on avoiding cliffs and plateaus alone.

The other primary challenge that this technique faces in bypassing histogram analysis is how much it smooths down the remaining portions of a histogram. Evaluating the histograms embedding from only a handful of images up to even around 12 images embedded, there's a flattening of all regions of the histogram. This flattening becomes more pronounced the more images embedded and reacts strongly to the images embedded in the cover. If we embed a image made of large sections of similar colors, it's likely they'll get converted into large regions of white and black in the embedded image causing long runs of 1s or 0s to appear in the cover when embedded. Superior black-and-white conversions or even permutation/interleaving of the bits after conversion could reduce the amount of flattening.

#pagebreak()

#bibliography(
  "./bibliography.yml",
  full: true,
  style: "institute-of-electrical-and-electronics-engineers",
)
