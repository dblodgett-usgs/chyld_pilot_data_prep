source("rdf_utils.R")

hu08 <- read_sf("hu08.geojson") %>% 
  st_set_geometry(NULL)

hu12 <- read_sf("hu12.geojson") %>% 
  st_set_geometry(NULL)

rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

hu08_subject <- paste0(wbd_base, hu08$huc8)
hu08_label <- hu08$name

rdf <- mint_feature(subject = hu08_subject, 
                    label = hu08_label,
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_Catchment",
                    rdf = rdf)

rdf <- create_association(subject = hu08_subject,
                          predicate ="http://www.w3.org/1999/02/22-rdf-syntax-ns#type", 
                          object ="https://www.opengis.net/def/hy_features/ontology/hyf/HY_CatchmentAggregate",
                          rdf = rdf)

rdf <- create_association(subject = hu08_subject,
                          predicate ="http://www.w3.org/1999/02/22-rdf-syntax-ns#type", 
                          object ="https://www.opengis.net/def/hy_features/ontology/hyf/HY_DendriticCatchment",
                          rdf = rdf)

cql <- paste0("huc8%20IN%20(%27", hu08$huc8, "%27)")

rdf <- create_subjectof(subject = hu08_subject, 
                      url = paste0(hu08_wfs_base, cql),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

rdf <- create_subjectof(subject = hu08_subject, 
                      url = paste0(wbd_info_base, hu08$huc8),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = hu08_subject, 
                      url = paste0(wbd_nwc_base, hu08$huc8),
                      format = c("text/html"),
                      label = "Waterbudget Summary",
                      rdf = rdf)

rdf <- create_subjectof(subject = hu08_subject, 
                      url = paste0(wbd_nwis_base, hu08$huc8),
                      format = c("text/html"),
                      label = "USGS Data Index",
                      rdf = rdf)

hu08_12_subject <- paste0(wbd_base, hu12$HUC_12)
hu08_12_object <- paste0(wbd_base, hu12$HUC_8)
rdf <- create_association(subject = hu08_12_subject, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/encompassingCatchment",
                          object = hu08_12_object,
                          rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")