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

fpp_url <- "https://www.sciencebase.gov/catalogMaps/mapping/ows/5762b664e4b07657d19a71ea?service=wfs&request=getfeature&version=1.0.0&typename=sb:fpp&outputFormat=application%2fjson&srsName=EPSG:4326"
fpp_data <- httr::GET(fpp_url)
fpp <- sf::read_sf(rawToChar(fpp_data$content))

fpp <- filter(fpp, HUC_12 %in% hu12$HUC_12)

write_sf(fpp, "hu12_outlet.geojson")
