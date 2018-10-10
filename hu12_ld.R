library(sf)
library(dplyr)
library(tidyr)
library(rdflib)

wbd_base <- "http://localhost/id/hu/"
wbd_info_base <- "http://localhost/gsip/info/hu/"
hy_base <- "https://www.opengis.net/def/hy_features/ontology/hyf/"
rdf_base <- "http://www.w3.org/2000/01/rdf-schema#"
dct_base <- "http://purl.org/dc/terms/"
wfs_base <- "https://cida.usgs.gov/nwc/geoserver/WBD/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=WBD:huc12&outputFormat=application%2Fjson&cql_filter=huc12="
html_base <- "https://cida.usgs.gov/nwc/#!waterbudget/huc/"

hu12 <- read_sf("data_prep/hu12.geojson")
hu12_outlet <- read_sf("data_prep/hu12_outlet.geojson") %>%
  select(HUC_12)
encompassing_basin <- read_sf("data_prep/outlet_hu.geojson")
outlet_hu <- paste0(wbd_base, encompassing_basin$huc12)

hu_ld <- st_set_geometry(hu12, NULL) %>%
  select(hu12 = HUC_12, lowerCatchment = HU_12_DS, label = HU_12_NAME) %>%
  mutate(subject = paste0(wbd_base, hu12), 
         lowerCatchment = paste0(wbd_base, lowerCatchment),
         label = label,
         type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_Catchment") %>%
  mutate(lowerCatchment = ifelse(subject == outlet_hu, 
                                 "https://geoconnex.ca/id/catchment/02OJ*CA",
                                 lowerCatchment))

hu_wfs <- select(hu_ld, subject = subject, hu12) %>%
  mutate(format = "application/vnd.geo+json",
         seeAlso = paste0(wfs_base, "%27", hu12, "%27"),
         label = "GeoJSON") %>%
  select(-hu12)

hu_html <- select(hu_ld, subject = subject, hu12) %>%
  mutate(format = "text/html",
         seeAlso = paste0(wbd_info_base, hu12),
         label = "Information Index") %>%
  select(-hu12)

hu_html_nwc <- select(hu_ld, subject = subject, hu12) %>%
  mutate(format = "text/html",
         seeAlso = paste0(html_base, hu12),
         label = "Waterbudget Summary") %>%
  select(-hu12)
  
split_seealso <- function(x) {
  rbind(select(x, subject, object = seeAlso) %>%
          mutate(predicate = paste0(rdf_base, "seeAlso")),
        select(x, subject = seeAlso, object = format) %>%
          mutate(predicate = paste0(dct_base, "format")),
        select(x, subject = seeAlso, object = label) %>%
          mutate(predicate = paste0(rdf_base, "label"))) %>%
    select(subject, predicate, object)
}

hu_ld <- select(hu_ld, -hu12) %>%
  rename(subject = subject, 
         !!paste0(hy_base, "lowerCatchment") := lowerCatchment,
         !!paste0(rdf_base, "label") := label,
         "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" = type)

hu_ld <- gather(hu_ld, predicate, object, -subject) %>%
  rbind(split_seealso(hu_wfs)) %>%
  rbind(split_seealso(hu_html)) %>%
  rbind(split_seealso(hu_html_nwc))

rdf <- rdf()

for(r in seq(1, nrow(hu_ld))) {
  rdf <- rdf_add(rdf, hu_ld$subject[r], hu_ld$predicate[r], hu_ld$object[r])
}

rdflib::rdf_serialize(rdf, "GSIP/WebContent/repos/gsip/relations.ttl", "turtle")

catchment_json <- select(hu12, HUC_12, HU_12_DS, name = HU_12_NAME) %>%
  rename(id = HUC_12, `drains-to` = HU_12_DS) %>%
  mutate(uri = paste0(wbd_base, id),
         type = "HY_Catchment")

write_sf(catchment_json, "GSIP/WebContent/resources/catchment/catchments.json", driver = "GeoJSON")


