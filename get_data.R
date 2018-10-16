source("rdf_utils.R")
# https://cida.usgs.gov/nwc/#!waterbudget/achuc/041504081604
library(nhdplusTools)
library(sf)
library(dplyr)

nhdplus_path("./NHDPlusV21_National_Seamless.gdb/")
stage_national_data()

layers <- st_layers(nhdplus_path())

wbd_layer <- "HUC12"
hu12 <- read_sf(nhdplus_path(), wbd_layer)

outlet_hu <- "041504081604"
wfs_url <- "https://cida.usgs.gov/nwc/geoserver/wfs"
wfs_post <- '<wfs:GetFeature xmlns:wfs="http://www.opengis.net/wfs" service="WFS" version="1.1.0" outputFormat="application/json" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/1.1.0/wfs.xsd"><wfs:Query typeName="feature:huc12agg" srsName="EPSG:4326" xmlns:feature="http://gov.usgs.cida/WBD"><ogc:Filter xmlns:ogc="http://www.opengis.net/ogc"><ogc:PropertyIsEqualTo matchCase="true"><ogc:PropertyName>huc12</ogc:PropertyName><ogc:Literal>041504081604</ogc:Literal></ogc:PropertyIsEqualTo></ogc:Filter></wfs:Query></wfs:GetFeature>'
outlet_hu <- httr::POST(wfs_url, body = wfs_post)
writeBin(outlet_hu$content, "outlet_hu.geojson")

outlet_hu <- sf::read_sf("outlet_hu.geojson")

upstream_hus <- unlist(strsplit(outlet_hu$uphucs[1], ","))

hu12 <- filter(hu12, HUC_12 %in% c(outlet_hu, upstream_hus))

write_sf(hu12, "hu12.geojson")

hu08 <- unique(hu12$HUC_8)

hu08_wfs_base <- "https://cida.usgs.gov/nwc/geoserver/WBD/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=WBD:huc08&srsName=EPSG:4326&outputFormat=application%2Fjson&cql_filter="

cql <- paste0("huc8%20IN%20(%27", 
              paste0(hu08, collapse = "%27,%20%27"),
              "%27)")

hu08_sf <- read_sf(paste0(hu08_wfs_base, cql))

write_sf(hu08_sf, "hu08.geojson")

catchment_json <- select(hu12, HUC_12, HU_12_DS, name = HU_12_NAME) %>%
  rename(id = HUC_12, `drains-to` = HU_12_DS) %>%
  mutate(uri = paste0(wbd_base, id),
         type = "HY_Catchment")

try(write_sf(catchment_json, 
             "GSIP/WebContent/resources/catchment/catchments.json", 
             driver = "GeoJSON"), 
    silent = FALSE)

fpp_url <- "https://www.sciencebase.gov/catalogMaps/mapping/ows/5762b664e4b07657d19a71ea?service=wfs&request=getfeature&version=1.0.0&typename=sb:fpp&outputFormat=application%2fjson&srsName=EPSG:4326"
fpp_data <- httr::GET(fpp_url)
fpp <- sf::read_sf(rawToChar(fpp_data$content))

fpp <- filter(fpp, HUC_12 %in% hu12$HUC_12)

write_sf(fpp, "hu12_outlet.geojson")

hu12 <- read_sf("hu12.geojson")
hu08_sf <- read_sf("hu08.geojson")
gages <- read_sf(gages_wfs_base) 

gages <- st_intersection(gages, st_union(st_geometry(hu12)))

gages <- st_join(gages, select(hu12, "HUC_12"))

gages <- st_join(gages, select(hu08_sf, huc8))

write_sf(gages, "gages.geojson")

ngwmn_wfs_base <- "https://cida.usgs.gov/ngwmn/geoserver/wfs?service=WFS&version=1.0.0&request=GetFeature&typeName=ngwmn:aquifrp025&outputFormat=application%2Fjson"
nat_aq <- httr::GET(ngwmn_wfs_base)
nat_aq <- sf::read_sf(rawToChar(nat_aq$content))
nat_aq <- st_transform(nat_aq, st_crs(hu12))
write_sf(nat_aq, "nat_aq.geojson")

intersects <- st_intersects(nat_aq, hu12)

nat_aq_sub <- filter(nat_aq, lengths(intersects) > 0) %>%
  select(ROCK_NAME, ROCK_TYPE, AQ_NAME, AQ_CODE, NAT_AQFR_CD, LINK)

write_sf(nat_aq_sub, "aquifers.geojson")

wells <- read_sf(wells_wfs_base)

write_sf(wells, "ngwmn_wells.geojson")

wells <- st_intersection(wells, st_union(st_geometry(hu12)))

wells <- st_join(wells, select(hu12, "HUC_12"))

wells <- st_join(wells, select(hu08_sf, huc8))

write_sf(wells, "wells.geojson")

