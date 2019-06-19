source("rdf_utils.R")

aq <- read_sf("aquifers.geojson")

hu08 <- read_sf("hu08.geojson")

hu12 <- read_sf("hu12.geojson")

aq_atts <- st_set_geometry(aq, NULL) %>%
  distinct()

aq_merge <- group_by(aq, NAT_AQFR_CD) %>%
  summarise() %>%
  st_cast("MULTIPOLYGON") %>%
  left_join(aq_atts, by = "NAT_AQFR_CD") %>%
  filter(NAT_AQFR_CD != "N9999OTHER")

hu08_aq <- st_join(hu08, aq_merge) %>%
  st_set_geometry(NULL) %>%
  select(huc8, NAT_AQFR_CD) %>%
  filter(!is.na(NAT_AQFR_CD) & !is.na(huc8))

hu12_aq <- st_join(hu12, aq_merge) %>%
  st_set_geometry(NULL) %>%
  select(HUC_12, NAT_AQFR_CD) %>%
  filter(!is.na(NAT_AQFR_CD) & !is.na(HUC_12))

rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

nat_aq_subject <- paste0(nat_aq_base, aq_merge$NAT_AQFR_CD)
rdf <- mint_feature(subject = nat_aq_subject, 
                    label = aq_merge$AQ_NAME, 
                    type = "http://geosciences.ca/def/groundwater#GW_AquiferSystem", 
                    rdf = rdf)

cql <- paste0("&cql_filter=NAT_AQFR_CD%20IN%20(%27", aq_merge$NAT_AQFR_CD, "%27)")
rdf <- create_seealso(subject = nat_aq_subject, 
                      seealso = paste0(nat_aq_wfs_base, cql),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

rdf <- create_seealso(subject = nat_aq_subject, 
                      seealso = aq_merge$LINK,
                      format = c("text/html"),
                      label = "Aquifer Summary Page",
                      rdf = rdf)

rdf <- create_seealso(subject = nat_aq_subject, 
                      seealso = paste0(nat_aq_info_base, aq_merge$NAT_AQFR_CD),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_association(subject = paste0(wbd_base, hu08_aq$huc8), 
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfIntersects", 
                          object = paste0(nat_aq_base, hu08_aq$NAT_AQFR_CD), 
                          rdf = rdf)

rdf <- create_association(subject = paste0(wbd_base, hu12_aq$HUC_12), 
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfIntersects", 
                          object = paste0(nat_aq_base, hu12_aq$NAT_AQFR_CD), 
                          rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")