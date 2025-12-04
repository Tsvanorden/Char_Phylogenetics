library(ggplot2)
library(dplyr)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(readxl)

# Load your data
Genbank <- read_excel("/Users/tannervanorden/Desktop/Char_Publication/Publication_Map/Genbank Location.xlsx")
Bull <- read_excel("/Users/tannervanorden/Desktop/Char_Publication/Publication_Map/Bull Trout.xlsx")
Dolly <- read_excel("/Users/tannervanorden/Desktop/Char_Publication/Publication_Map/Dolly.xlsx")
Char <- read_excel("/Users/tannervanorden/Desktop/Char_Publication/Publication_Map/Arctic Char.xlsx")

# Add Source column
Genbank <- Genbank %>% mutate(Source = "Genbank")
Bull <- Bull %>% mutate(Source = "Bull Trout")
Dolly <- Dolly %>% mutate(Source = "Dolly")
Char <- Char %>% mutate(Source = "Arctic Char")

# Combine all data
all_data <- bind_rows(Genbank, Bull, Dolly, Char)

# Convert to sf object with WGS84 coords
all_sf <- st_as_sf(all_data, coords = c("Long", "Lat"), crs = 4326)

# Load world map
world <- ne_countries(scale = "medium", returnclass = "sf")

# Projection centered on North Pole, longitude shifted to -90°
aeqd_proj <- "+proj=aeqd +lat_0=90 +lon_0=-90 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

# Transform data
world_aeqd <- st_transform(world, crs = aeqd_proj)
all_sf_aeqd <- st_transform(all_sf, crs = aeqd_proj)

#Plot
ggplot() +
  geom_sf(data = world_aeqd, fill = "lightgrey", color = "gray40") +
  geom_sf(data = all_sf_aeqd, aes(color = Source, shape = Source), size = 4, alpha = 0.8) +
  scale_shape_manual(values = c(
    "Genbank" = 17,     # triangle
    "Bull Trout" = 16,  # default circle
    "Dolly" = 16,
    "Arctic Char" = 16
  )) +
  scale_color_manual(values = c(
    "Genbank" = "gold",
    "Bull Trout" = "black",
    "Dolly" = "orange",
    "Arctic Char" = "#3182bd"
  )) + 
  coord_sf(crs = aeqd_proj,
           xlim = c(-4e6, 3e6),
           ylim = c(-6e6, 1.5e6),
           expand = FALSE) +
  theme_minimal() +
  theme(
    panel.background = element_rect(fill = "white"),
    legend.position = "bottom"
  )
