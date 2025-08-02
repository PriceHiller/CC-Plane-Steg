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
    align(center + horizon, box(width: page.width + 4em, height: 100%, fill: gradient.linear(..gradient_fill), [
      #place(left + horizon, dx: +page.margin.left + 10pt)[
        #text(size: 1.1em, fill: gold, font: accent_font, weight: "black")[Steganography Project],
        #text(size: 1.1em, fill: white)[#title],
      ]
      #let icon_size = 45%
      #place(right + horizon, dx: -page.margin.left, box(
        baseline: icon_size,
      ))
    ]))
  },
  footer: context if here().page() > 1 {
    text(size: 0.8em, fill: color.luma(35%), [
      #v(.75em)
      Steganography Project Proposal | CS 4463-01T | Team 2
      #h(1fr)

      #{
        here().page() - 1
      }
    ])
    align(center + bottom, block(width: page.width + 10pt, height: 20%, fill: gradient.linear(..gradient_fill)))
  },
)

// COVER PAGE

#set page(background: context if here().page() == 1 {
  box(
    fill: gradient.linear(angle: 60deg, ..gradient_fill),
    width: 100%,
    height: 100%,
  )

  place(top + center, rect(width: 100%, height: 100%, fill: tiling(size: (18pt, 18pt), place(dy: 3pt, dx: 1pt, circle(
    radius: 3.5pt,
    fill: blue.darken(65%),
  )))))

  let globe = read("./assets/globe.svg").replace("#000000", blue.darken(40%).to-hex())
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
      Sean Nicosia\
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
      July 10th, 2025
])
}

#pagebreak()

= Introduction

We are developing a steganographic program designed to embed multiple black and white images dervied from full-color input images within the individual bit planes of each color component (referred to as color component planes) in a 24-bit color bitmap. Our approach involves distributing the binary data of each black and white image across the bit planes of the red, green, and blue channels in a linear fashion @improved-lsb-rgb. This method will result in a modified cover image, potentially rendered in grayscale, or black and white, depending on the use of upper bit planes. The primary objective of this project is to implement a novel technique for concealing multiple images within a single bitmap file. Additionally, we aim to perform statistical analysis on the output, evaluating practical payload capacity, the visual detectability of the embedded data, and the overall effectiveness of the cover image as a steganographic medium.

The program will accept full-color images to hide in a full-color cover image and take the most significant bit of each pixel of the images to be hidden and derive an appropriate black and white image for the given bits. This black and white image will then be embedded within a color component bit plane in the cover image. The embedding pattern is taking advantage of similar patterns as that to Least Significant Bit replacement and encoding per color channel @lsb-steg-explore.


To extract the hidden data, the algorithm will accumulate each color component plane from a given image into its respective image file name. For instance, all bits in position 2 belonging to a blue color component as part of a given bit plane would be extracted to a file named `B2.bmp`.

The functional block diagrams outlining the algorithm's steps are located in the next pages.


#image("./assets/Steg-Project-Block-Diagram-Hiding.svg", height: 100%, width: 95%)

#image("./assets/Steg-Project-Block-Diagram-Extraction.svg")

#bibliography("./bibliography.yml", full: true, style: "institute-of-electrical-and-electronics-engineers")
