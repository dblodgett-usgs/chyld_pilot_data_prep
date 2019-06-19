source("rdf_utils.R")
wells <- read_sf("wells.geojson")

rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

wells_subject <- paste0(wells_base, gsub(":", "-", wells$MY_SITEID))

# wells_subject <- paste0(wells_base, wells$MY_SITEID)

rdf <- mint_feature(subject = wells_subject, 
                    label = wells$SITE_NAME,
                    type = "http://geosciences.ca/def/groundwater#GW_Well",
                    rdf = rdf)

rdf <- create_seealso(subject = wells_subject, 
                      seealso = paste0(wells_info_base, wells$MY_SITEID),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"), 
                      label = "Information Index", 
                      rdf = rdf)

rdf <- create_seealso(subject = wells_subject, 
                      seealso = wells$LINK, 
                      format = c("text/html"), 
                      label = "Well Summary Page", 
                      rdf = rdf)

cql = paste0("&cql_filter=MY_SITEID%20IN%20(%27", 
             wells$MY_SITEID,
             "%27)")

rdf <- create_seealso(subject = wells_subject, 
                      seealso = paste0(wells_wfs_base, cql),
                      format = "application/vnd.geo+json", 
                      label = "GeoJSON", 
                      rdf = rdf)

rdf <- create_association(subject = wells_subject,
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfWithin",
                          object = paste0(wbd_base, wells$huc8),
                          rdf = rdf)

rdf <- create_association(subject = wells_subject,
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfWithin",
                          object = paste0(wbd_base, wells$HUC_12),
                          rdf = rdf)

rdf <- create_association(subject = wells_subject,
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfWithin",
                          object = paste0(nat_aq_base, wells$NAT_AQUIFER_CD),
                          rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")

