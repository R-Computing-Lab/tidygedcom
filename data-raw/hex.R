library(hexSticker)
library(stringr)
library(rsvg)
## read in file
file <- "data-raw/catlogo.svg"
# Render with rsvg into png
svgdata <- readLines(file)
svg_string <- paste(svgdata, collapse = "\n")
svgdata <- readLines(file, warn = FALSE)
svg_string <- paste(svgdata, collapse = "\n")

tuxedo_palette <- c(
  st0_fill   = "#CCE4ED", # hidden background shape
  st1_stroke = "#07080A", # hidden stroke
  st2_fill   = "#F4F7F8", # hidden decorative/cloud shapes
  st3_fill   = "#202328", # black-fur shadow
  st4_fill   = "#30343A", # main black-fur highlight
  st5_stroke = "#07080A", # visible outline stroke
  st6_fill   = "#E8A9B3", # pink nose / ear
  st7_fill   = "#C9828F", # darker inner ear pink
  st8_fill   = "#07080A", # deepest outline/detail
  st9_fill   = "#111317", # dark black accent
  st10_fill  = "#F4F7F8"  # white muzzle/patch highlight
)

replace_css_property <- function(svg_string, class_name, property, color) {
  pattern <- paste0(
    "(\\.", class_name, "\\{[^}]*?",
    property, "\\s*:\\s*)#[A-Fa-f0-9]{6}"
  )

  replacement <- paste0("\\1", color)

  str_replace_all(
    svg_string,
    regex(pattern),
    replacement
  )
}

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

cat("recoloredcat.png exists: ", file.exists("data-raw/recoloredcat.png"), "\n")
cat("recoloredcat.png path:   ", normalizePath("data-raw/recoloredcat.png"), "\n")
cat("recoloredcat.png time:   ", file.info("data-raw/recoloredcat.png")$mtime, "\n")

if (file.exists("man/figures/hex.png")) {
  file.remove("man/figures/hex.png")
}
library(magick)


cat_img <- magick::image_read(normalizePath("data-raw/recoloredcat.png"))

# make the three cats
cat_left   <- image_scale(cat_img, "300x300")
cat_center <- image_scale(cat_img, "360x360")
cat_right  <- image_scale(cat_img, "300x300")

# tighter transparent canvas
three_cats <- image_blank(width = 860, height = 380, color = "transparent")

# place cats higher on the canvas
three_cats <- image_composite(three_cats, cat_left,   operator = "over", offset = "+0+0")
three_cats <- image_composite(three_cats, cat_center, operator = "over", offset = "+230+0")
three_cats <- image_composite(three_cats, cat_right,  operator = "over", offset = "+520+0")

# trim extra transparent space
#three_cats <- image_trim(three_cats)

# optionally re-extend to a balanced canvas so sticker positioning is stable


image_write(three_cats, path = "data-raw/threecats.png", format = "png")

sticker(
  subplot = three_cats,
  package = "tidygedcom",
  p_size = 20,
  s_x = 1,
  s_y = 0.66,
  s_width =  1.55,
  h_fill = "#0fa1e0",
  h_color = "#333333",
  p_color = "white",
  filename = "man/figures/hex.png"
)

