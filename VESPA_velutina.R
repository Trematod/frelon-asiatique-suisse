library(dplyr)
library(ggplot2)
library(sf)
library(rnaturalearth)
library(tidyverse)
library(giscoR)
library(ggrepel)
library(plotly)
library(viridisLite)
library(leaflet)


#---------------import
Vespa<- read.csv2("GBIF_VESPA_CH.csv", sep = "\t")
head(Vespa) 

#---------------Sub dataset avec vespa velutina
subdat <- subset(Vespa, scientificName == "Vespa velutina Lepeletier, 1836")
str(subdat)

#---------------Apparition en Suisse
ggplot(subdat, aes(x = stateProvince, y = year)) +
  geom_point()
#premier point d'observation en 2017 dans le Jura, puis Vaud 2019, Ge-Ju-Ti 2020, forte augmentation depuis 2022
#en 2025: seuls les cantons de SG et Ti n'ont pas d'observations (aucun canton avec 0 obs au fil des ans)

subdat_2017<-subdat %>%
  filter(year == 2017)

#---------------Propagation géographique
#Nombre d'observations par année
subdat %>%
  count(year) %>%
  ggplot(aes(year, n)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Signalements du frelon asiatique en Suisse",
    x = "Année",
    y = "Nombre d'observations"
  ) +
  theme_minimal()
#observations en forte croissance depuis 2022-2023 - exponentiel 


#---------------Cartographie
swiss_map <- ne_countries(
  country = "Switzerland",
  returnclass = "sf"
)
swiss_map

#transformer subdat en objet spatial sf
subdat_sf <- st_as_sf(
  subdat,
  coords = c("decimalLongitude", "decimalLatitude"),
  crs = 4326   
)

cantons <- st_read("swissBOUNDARIES3D_1_5_TLM_KANTONSGEBIET.shp")#selection des cantons
st_crs(cantons)
st_crs(subdat_sf)

subdat_sf_2056 <- st_transform(subdat_sf, 2056)
#transformation des observations en 2056 pour qu'elles matchent
cantons_xy <- st_zm(cantons, drop = TRUE, what = "ZM")
#applatir la géométrie des cantons en XY uniquement


ggplot() +
  geom_sf(data = cantons_xy, fill = "gray95", color = "white") +
  geom_sf(data = subdat_sf_2056, color = "red", alpha = 0.6, size = 1) +
  geom_sf_text(
    data = cantons,
    aes(label = NAME),
    size = 3
  ) +
  labs(
    title = "Répartition du frelon asiatique en Suisse",
    subtitle = "Données GBIF – frontières officielles (swissBOUNDARIES3D)"
  )+
  theme_minimal()

#------essayer de faire une carte avec couleurs sur cantons
subdat_2025 <- subdat_sf_2056 |> 
  dplyr::filter(year == 2025)

cantons_xy$nb_obs <- lengths(
  st_intersects(cantons_xy, subdat_2025)
)


ggplot() +
  geom_sf(
    data = cantons_xy,
    aes(fill = nb_obs),
    color = "white",
    linewidth = 0.3
  ) +
  geom_sf(
    data = subdat_2025,
    color = "black",
    size = 0.4,
    alpha = 0.5
  ) +
  scale_fill_viridis_c(option = "plasma") +
  labs(
    title = "Frelon asiatique en Suisse (2025)",
    subtitle = "Couleur des cantons selon le nb observations"
  ) +
  theme_minimal()
#--> ne fonctionne plus ?

#version compliquée pour faire une carte avec points en fonction du canton
cantons_xy <- st_transform(cantons_xy, 2056)
subdat_2025 <- st_transform(subdat_2025, 2056)

#Trouver le canton de chaque point 
idx <- st_intersects(subdat_2025, cantons_xy)

#Créer une colonne canton dans les points
subdat_2025$canton <- cantons_xy$NAME[
  sapply(idx, function(x) if (length(x) > 0) x[1] else NA)
]


ggplot() +
  geom_sf(data = cantons_xy, fill = "gray95", color = "black") +
  geom_sf(
    data = subdat_2025,
    aes(color = canton),
    size = 0.6,
    alpha = 0.7
  ) +
  scale_color_viridis_d(option = "turbo") +
  labs(
    title = "Frelon asiatique en Suisse (2025)",
    subtitle = "Couleur des points selon le canton"
  ) +
  theme_minimal()

#------Carte interactive 2025
subdat_2025 <- subdat_sf_2056 |> 
  dplyr::filter(year == 2025)

cantons_xy$nb_obs <- lengths(
  st_intersects(cantons_xy, subdat_2025)
)#calcule le nombre d'observations en 2025 total


cantons_xy$info <- paste0( #on utilise paste0 pour dire sep = ""
  #paste0("a", "b") === paste("a", "b", sep="")
  "Canton: ", cantons_xy$NAME,
  "\nNombre d'observations: ", cantons_xy$nb_obs
)#infos pour mettre dans les étiquettes liées aux cantons dans la map interactive


ggsf <- ggplot(cantons_xy) +
  geom_sf(aes(fill = nb_obs, text = info), color = "white") +  # color = "black" pour les frontières
  scale_fill_viridis_c(name = "Observations totales/cantons") +
  labs(
    title = "Frelon asiatique en Suisse (2025)",
    subtitle = "Nombre total d'observations par canton"
  ) +
  theme_minimal()

ggplotly(ggsf, tooltip = "text")

#------Carte interactive toutes années --> ne fonctionne pas encore

cantons_simple <- st_simplify(
  cantons_xy,
  dTolerance = 100  # en mètres (50–200 recommandé)
)

years <- sort(unique(subdat_sf_2056$year))

obs_canton_year <- lapply(years, function(y) {
  pts <- subdat_sf_2056 |> dplyr::filter(year == y)
  n <- lengths(st_intersects(cantons_xy, pts))
  data.frame(
    NAME = cantons_xy$NAME,
    year = y,
    nb_obs = n
  )
}) |> bind_rows()

head(obs_canton_year)


cantons_long <- cantons_xy |>
  st_drop_geometry() |>
  select(NAME) |>
  crossing(year = sort(unique(obs_canton_year$year))) |>
  left_join(obs_canton_year, by = c("NAME", "year")) |>
  mutate(nb_obs = replace_na(nb_obs, 0)) |>
  left_join(
    cantons_xy |> select(NAME, geometry),
    by = "NAME"
  ) |>
  st_as_sf()

cantons_long_ll <- st_transform(cantons_long, 4326)

pal <- colorNumeric(
  palette = "viridis",
  domain = cantons_long_ll$nb_obs
)

leaflet(cantons_long_ll) |>
  addProviderTiles("CartoDB.Positron") |>
  addPolygons(
    fillColor = ~pal(nb_obs),
    weight = 1,
    color = "white",
    fillOpacity = 0.8,
    popup = ~paste0(
      "<b>", NAME, "</b><br>",
      "Année: ", year, "<br>",
      "Observations: ", nb_obs
    )
  )


library(crosstalk)

sd <- SharedData$new(
  cantons_long_ll,
  key = ~paste(NAME, year),
  group = "cantons"
)


slider <- filter_slider(
  id = "year",
  label = "Année",
  sharedData = sd,
  column = ~year,
  step = 1,
  width = "100%"
)

pal <- colorNumeric(
  "viridis",
  domain = cantons_long_ll$nb_obs
)

slider
leaflet(sd) |>
  addProviderTiles("CartoDB.Positron") |>
  addPolygons(
    fillColor = ~pal(nb_obs),
    weight = 1,
    color = "white",
    fillOpacity = 0.8,
    popup = ~paste0(
      "<b>", NAME, "</b><br>",
      "Année: ", year, "<br>",
      "Observations: ", nb_obs
    )
  )

