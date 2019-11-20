source("rdf_utils.R")
gages <- read_sf("gages.geojson")
hu12 <- st_set_geometry(read_sf("hu12.geojson"), NULL)
hu08 <- st_set_geometry(read_sf("hu08.geojson"), NULL)
rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

nwis_gage_subject <- paste0(nwis_gage_base, gages$STAID)

rdf <- mint_feature(subject = nwis_gage_subject, 
                    label = gages$STANAME, 
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydrometricFeature",
                    rdf = rdf)

rdf <- create_subjectof(subject = nwis_gage_subject, 
                      url = paste0(nwis_gage_info_base, gages$STAID),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"), 
                      label = "Information Index", 
                      rdf = rdf)

rdf <- create_subjectof(subject = nwis_gage_subject, 
                      url = paste0("https://waterdata.usgs.gov/nwis/inventory?agency_code=USGS&site_no=", gages$STAID), 
                      format = c("text/html"), 
                      label = "NWIS Site Page", 
                      rdf = rdf)

rdf <- create_subjectof(subject = nwis_gage_subject, 
                      url = paste0("https://cida.usgs.gov/nldi/nwissite/USGS-", gages$STAID), 
                      format = "application/vnd.geo+json", 
                      label = "NLDI Feature JSON", 
                      rdf = rdf)

hu12_hydrometricnetwork <- data.frame(hu12 = unique(gages$HUC_12), stringsAsFactors = FALSE) %>%
  left_join(select(hu12, HUC_12, HU_12_NAME), by = c("hu12" = "HUC_12"))
  
nwis_hu12_hydrometricnetwork_subject <- paste0(nwis_hu_hydrometricnetwork_base, hu12_hydrometricnetwork$hu12)
rdf <- mint_feature(subject = nwis_hu12_hydrometricnetwork_subject,
                    label = paste("Monitoring Network In", hu12_hydrometricnetwork$HU_12_NAME, "Hydrologic Unit"), 
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydrometricNetwork", 
                    rdf = rdf)

rdf <- create_subjectof(subject = nwis_hu12_hydrometricnetwork_subject, 
                      url = paste0(nwis_hu_hydrometricnetwork_info_base, hu12_hydrometricnetwork$hu12),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"), 
                      label = "Information Index", 
                      rdf = rdf)

cql <- lapply(hu12_hydrometricnetwork$hu12, function(x) gages$STAID[which(gages$HUC_12 == x)])
cql <- sapply(cql, function(x) paste0("&cql_filter=STAID%20IN%20(%27", 
                                      paste0(x, collapse = "%27,%20%27"),
                                      "%27)"))

rdf <- create_subjectof(subject = nwis_hu12_hydrometricnetwork_subject, 
                      url = paste0(gages_wfs_base, cql),
                      format = "application/vnd.geo+json", 
                      label = "GeoJSON", 
                      rdf = rdf)

rdf <- create_association(subject = nwis_hu12_hydrometricnetwork_subject, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedCatchment",
                          object = paste0(wbd_base, hu12_hydrometricnetwork$hu12), 
                          rdf = rdf)

rdf <- create_association(subject = nwis_gage_subject, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/hydrometricNetwork", 
                          object = paste0(nwis_hu_hydrometricnetwork_base, gages$HUC_12), 
                          rdf = rdf)

hu08_hydrometricnetwork <- data.frame(hu08 = unique(gages$huc8), stringsAsFactors = FALSE) %>%
  left_join(select(hu08, huc8, name), by = c("hu08" = "huc8"))

nwis_hu08_hydrometricnetwork_subject <- paste0(nwis_hu_hydrometricnetwork_base, hu08_hydrometricnetwork$hu08)
rdf <- mint_feature(subject = nwis_hu08_hydrometricnetwork_subject,
                    label = paste("Monitoring Network In", hu08_hydrometricnetwork$name, "Hydrologic Unit"), 
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydrometricNetwork", 
                    rdf = rdf)

rdf <- create_subjectof(subject = nwis_hu08_hydrometricnetwork_subject, 
                      url = paste0(nwis_hu_hydrometricnetwork_info_base, hu08_hydrometricnetwork$hu08),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"), 
                      label = "Information Index", 
                      rdf = rdf)

rdf <- create_subjectof(subject = nwis_hu08_hydrometricnetwork_subject, 
                      url = paste0(wbd_nwis_base, hu08_hydrometricnetwork$hu08),
                      format = c("text/html"), 
                      label = "Water Data For the Nation", 
                      rdf = rdf)

cql <- lapply(hu08_hydrometricnetwork$hu08, function(x) gages$STAID[which(gages$huc8 == x)])
cql <- sapply(cql, function(x) paste0("&cql_filter=STAID%20IN%20(%27", 
                                      paste0(x, collapse = "%27,%20%27"),
                                      "%27)"))

rdf <- create_subjectof(subject = nwis_hu08_hydrometricnetwork_subject, 
                      url = paste0(gages_wfs_base, cql),
                      format = "application/vnd.geo+json", 
                      label = "GeoJSON", 
                      rdf = rdf)

rdf <- create_association(subject = nwis_hu08_hydrometricnetwork_subject, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedCatchment",
                          object = paste0(wbd_base, hu08_hydrometricnetwork$hu08), 
                          rdf = rdf)

rdf <- create_association(subject = nwis_gage_subject, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/hydrometricNetwork", 
                          object = paste0(nwis_hu_hydrometricnetwork_base, gages$huc8), 
                          rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")
