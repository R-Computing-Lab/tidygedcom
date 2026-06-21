library(hexSticker)
library(stringr)
library(rsvg)
## read in file
file <- "data-raw/catlogo.svg"
# Render with rsvg into png
svgdata <- readLines(file)
svg_string <- paste(svgdata, collapse = "\n")


old_colors <- c(
  "#cce4ed", # st0_color
  "#5f1905", # st1_color, st5_color, st8_color
  "#d9ebf4", # st2_color, st10_color
  "#ce370b", # st3_color
  "#f45f34", # st4_color
  "#c15b65", # st6_color pink nose
  "#a54653", # st7_color pink inner ear
  "#842307"  # st9_color
)


new_colors <- c(
  # tuxedo cat
  "#CCE4ED", # st0_color, unchanged hidden background shape
  "#07080A", # st1_color, st5_color, st8_color, near-black outline/detail
  "#F4F7F8", # st2_color, st10_color, tuxedo white highlight/muzzle
  "#202328", # st3_color, black-fur shadow replacing darker orange
  "#30343A", # st4_color, main black-fur highlight replacing bright orange
  "#E8A9B3", # st6_color, inner ear / nose pink
  "#C9828F", # st7_color, darker inner ear pink
  "#111317"  # st9_color, dark black accent replacing reddish-brown accent
)
color_replacements <- setNames(new_colors, old_colors)
# Use str_replace_all to replace all occurrences of the old color
modified_svg_string <- str_replace_all(svg_string, color_replacements)
writeLines(modified_svg_string, "data-raw/recoloredcat.svg")

rsvg::rsvg_png("data-raw/recoloredcat.svg",
  "data-raw/recoloredcat.png",
  width = 800
)


sticker("data-raw/recoloredcat.png",
  package = "BGmisc", p_size = 20, s_x = 1, s_y = .75, s_width = .6,
  h_fill = "#0fa1e0", h_color = "#333333", p_color = "white",
  filename = "man/figures/hex.png"
)
