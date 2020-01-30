source("rdf_utils.R")

hu12 <- read_sf("hu12.geojson")

catchment_json <- select(hu12, HUC_12, HU_12_DS, name = HU_12_NAME) %>%
  rename(id = HUC_12, `drains-to` = HU_12_DS) %>%
  mutate(uri = paste0(wbd_base, id),
         type = "HY_Catchment") %>%
  st_transform(5070) %>%
  rmapshaper::ms_simplify(keep = 0.01) %>%
  st_transform(4326)

unlink("../GSIP/WebContent/resources/catchment/catchments.json")

write_sf(catchment_json,
             "../GSIP/WebContent/resources/catchment/catchments.json",
             driver = "GeoJSON")

hu12_outlet <- read_sf("hu12_outlet.geojson") %>%
  select(HUC_12) 

encompassing_basin <- read_sf("outlet_hu.geojson")
outlet_hu <- paste0(wbd_base, encompassing_basin$huc12)

##### Primary HU12 Features and Representations #####
hu12_subject <- paste0(wbd_base, hu12$HUC_12)

rdf <- mint_feature(subject = hu12_subject, 
                      label = hu12$HU_12_NAME, 
                      type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_Catchment",
                      rdf = rdf())

rdf <- create_association(subject = hu12_subject,
                          predicate ="http://www.w3.org/1999/02/22-rdf-syntax-ns#type", 
                          object ="https://www.opengis.net/def/hy_features/ontology/hyf/HY_DendriticCatchment",
                          rdf = rdf)

rdf <- create_association(subject = hu12_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/lowerCatchment",
                          object = ifelse(hu12_subject == outlet_hu, 
                                          "https://geoconnex.ca/id/catchment/02OJ*CA",
                                          paste0(wbd_base, hu12$HU_12_DS)),
                          rdf = rdf)

rdf <- create_subjectof(subject = hu12_subject, 
                         url = paste0(wfs_base, "%27", hu12$HUC_12, "%27"),
                         format = "application/vnd.geo+json",
                         label = "GeoJSON",
                         rdf = rdf)

rdf <- create_subjectof(subject = hu12_subject, 
                      url = paste0(wbd_info_base, hu12$HUC_12),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = hu12_subject, 
                          url = paste0(wbd_nwc_base, hu12$HUC_12),
                          format = c("text/html"),
                          label = "Waterbudget Summary",
                          rdf = rdf)

# Add drainage basin for each HU12
hu12_basin_id <- paste0(hu12$HUC_12, "-drainage_basin")
hu12_basin_subject <- paste0(wbd_base, hu12_basin_id)

rdf <- mint_feature(subject = hu12_basin_subject, 
                    label = paste0(hu12$HU_12_NAME, ": total upstream drainage basin"),
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_Catchment", 
                    rdf = rdf)

rdf <- create_association(subject = hu12_basin_subject,
                          predicate ="http://www.w3.org/1999/02/22-rdf-syntax-ns#type", 
                          object ="https://www.opengis.net/def/hy_features/ontology/hyf/HY_DendriticCatchment",
                          rdf = rdf)

rdf <- create_association(subject = hu12_basin_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/lowerCatchment",
                          object = ifelse(hu12_basin_subject == paste0(outlet_hu, "-drainage_basin"), 
                                          "https://geoconnex.ca/id/catchment/02OJ*CA",
                                          paste0(wbd_base, hu12$HU_12_DS)),
                          rdf = rdf)

rdf <- create_subjectof(subject = hu12_basin_subject, 
                      url = paste0(wfs_agg_base, "%27", hu12$HUC_12, "%27"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

rdf <- create_subjectof(subject = hu12_basin_subject, 
                      url = paste0(wbd_info_base, hu12_basin_id),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = hu12_basin_subject, 
                      url = paste0(wbd_acnwc_base, hu12$HUC_12),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Waterbudget Summary",
                      rdf = rdf)

##### HU12 Nexuses Based on All HU12 Outlets that Contribute to a Given HU. #####
hu12_outlet <- left_join(hu12_outlet, 
                         select(st_set_geometry(hu12, NULL),
                                HUC_12, HU_12_DS, HU_12_NAME), 
                         by = "HUC_12")

from_hucs <- sapply(hu12_outlet$HUC_12, fromHUC_finder, 
                    hucs = hu12_outlet$HUC_12, 
                    tohucs = hu12_outlet$HU_12_DS)
cats_with_inflows <- which(lapply(from_hucs, length) > 0)


nexus_subject <- paste0(wbd_nexus_base, 
                        paste0(hu12_outlet$HUC_12[cats_with_inflows], 
                               "-inflow"))

rdf <- mint_feature(subject = nexus_subject,
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydroNexus",
                    label = paste("Nexus contributing to", hu12_outlet$HU_12_NAME[cats_with_inflows]),
                    rdf = rdf)

rdf <- create_association(subject = nexus_subject, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/receivingCatchment", 
                          object = paste0(wbd_base, hu12_outlet$HUC_12[cats_with_inflows]), 
                          rdf = rdf)

next_ds <- paste0(domain, "chyld-pilot/id/hu_nexus/02OJ*CA-inflow")

rdf <- mint_feature(subject = next_ds,
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydroNexus",
                    label = paste("Nexus contributing to Little River - Riviere Richelieu"),
                    rdf = rdf)

rdf <- create_association(subject = next_ds, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/contributingCatchment", 
                          object = paste0(wbd_base, "041504081604"), 
                          rdf = rdf)

rdf <- create_association(subject = next_ds, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/contributingCatchment", 
                          object = paste0(wbd_base, "041504081604-drainage_basin"), 
                          rdf = rdf)

rdf <- create_association(subject = next_ds, 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/receivingCatchment", 
                          object = "https://geoconnex.ca/gsip/info/catchment/02OJ*CA", 
                          rdf = rdf)

rdf <- create_subjectof(subject = next_ds, 
                      url = paste0(nldi_base, "huc12pp/041504081604"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

##### Create nexus associations to catchments and  #####
##### a representation as a collection of inflows. #####
hy_in <- from_hucs[cats_with_inflows]
contributing_cats <- data.frame(nexus = character(), 
                                contributingCatchment = character(), 
                                stringsAsFactors = FALSE)

# Representation of the nexus as a collection of inflows.
nexus_wfs <- data.frame(nexus = names(hy_in), 
                        wfs = "", 
                        stringsAsFactors = FALSE)

# Create wfs calls for nexus representaton and contributing 
# catchments list for association to nexuses.
for(h in names(hy_in)) {
  cql <- paste0("HUC_12%20IN%20(%27", 
               paste0(hy_in[[h]], collapse = "%27,%20%27"),
               "%27)")
  nexus_wfs$wfs[which(nexus_wfs$nexus == h)] <- paste0(fpp_wfs_base, cql)
  for(c in hy_in[[h]]) {
    contributing_cats <- rbind(contributing_cats,
                            data.frame(nexus = h, 
                                       contributingCatchment = c, 
                                       stringsAsFactors = FALSE))
  }
}

rdf  <- create_subjectof(subject = paste0(wbd_nexus_base, nexus_wfs$nexus, "-inflow"),
                       url = nexus_wfs$wfs,
                       format = "application/vnd.geo+json",
                       label = "GeoJSON",
                       rdf = rdf)

rdf <- create_association(subject = paste0(wbd_nexus_base, 
                                           contributing_cats$nexus, 
                                           "-inflow"), 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/contributingCatchment", 
                          object = paste0(wbd_base, contributing_cats$contributingCatchment), 
                          rdf = rdf)

rdf <- create_association(subject = paste0(wbd_nexus_base, 
                                           contributing_cats$nexus, 
                                           "-inflow"), 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/contributingCatchment", 
                          object = paste0(wbd_base, paste0(contributing_cats$contributingCatchment, "-drainage_basin")), 
                          rdf = rdf)

###### add HY_HydrologicLocation features for the outlet of HU12s that are part of the nexues above.
outlet_subject <- paste0(wbd_outlet_base, hu12_outlet$HUC_12)

rdf <- mint_feature(subject = outlet_subject,
                    label = paste("Outlet of", hu12_outlet$HU_12_NAME),
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydroloLocation",
                    rdf = rdf)

rdf <- create_association(subject = outlet_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedNexus",
                          object = paste0(wbd_nexus_base, hu12_outlet$HU_12_DS, "-inflow"),
                          rdf = rdf)

rdf <- create_subjectof(subject = outlet_subject,
                      url = paste0(wbd_outlet_info_base, hu12_outlet$HUC_12),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = outlet_subject,
                      url = paste0(fpp_wfs_base, "HUC_12%20IN%20(%27", hu12_outlet$HUC_12, "%27)"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

rdf <- create_subjectof(subject = outlet_subject,
                      url = paste0(nldi_base, "huc12pp/", hu12_outlet$HUC_12),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

#### Add flowpaths for drainage basins.

flowpath_id <- paste0(hu12$HUC_12, "-drainage_basin_flowpath")
flowpath_subject  <- paste0(wbd_base, flowpath_id)

rdf <- mint_feature(subject = flowpath_subject,
                    label = paste("Flowpath of", hu12_outlet$HU_12_NAME),
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_Flowpath",
                    rdf = rdf)

rdf <- create_association(subject = flowpath_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedCatchment",
                          object = hu12_basin_subject,
                          rdf = rdf)

rdf <- create_subjectof(subject = flowpath_subject,
                      url = paste0(wbd_info_base, flowpath_id),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = flowpath_subject,
                      url = paste0(nldi_base, "huc12pp/", hu12$HUC_12, "/navigate/UM"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

#### Add network for drainage basins

network_id <- paste0(hu12$HUC_12, "-drainage_basin_hydronetwork")
network_subject  <- paste0(wbd_base, network_id)

rdf <- mint_feature(subject = network_subject,
                    label = paste("Hydronetwork of", hu12_outlet$HU_12_NAME),
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydroNetwork",
                    rdf = rdf)

rdf <- create_association(subject = network_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedCatchment",
                          object = hu12_basin_subject,
                          rdf = rdf)

rdf <- create_subjectof(subject = network_subject,
                      url = paste0(wbd_info_base, network_id),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = network_subject,
                      url = paste0(nldi_base, "huc12pp/", hu12$HUC_12, "/navigate/UT"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

# Add hydrometric network (nwissite)
hydrometric_network_id <- paste0(hu12$HUC_12, "-drainage_basin_hydrometric_network_nwis")
hydrometric_network_subject  <- paste0(wbd_base, hydrometric_network_id)

rdf <- mint_feature(subject = hydrometric_network_subject,
                    label = paste("NWIS hydrometric network of", hu12_outlet$HU_12_NAME),
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydrometricNetwork",
                    rdf = rdf)

rdf <- create_association(subject = hydrometric_network_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedCatchment",
                          object = hu12_basin_subject,
                          rdf = rdf)

rdf <- create_subjectof(subject = hydrometric_network_subject,
                      url = paste0(wbd_info_base, hydrometric_network_id),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = hydrometric_network_subject,
                      url = paste0(nldi_base, "huc12pp/", hu12$HUC_12, "/navigate/UT/nwissite"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

# Add hydrometric network (wqp)
hydrometric_network_id <- paste0(hu12$HUC_12, "-drainage_basin_hydrometric_network_wqp")
hydrometric_network_subject  <- paste0(wbd_base, hydrometric_network_id)

rdf <- mint_feature(subject = hydrometric_network_subject,
                    label = paste("WQP hydrometric network of", hu12_outlet$HU_12_NAME),
                    type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydrometricNetwork",
                    rdf = rdf)

rdf <- create_association(subject = hydrometric_network_subject,
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedCatchment",
                          object = hu12_basin_subject,
                          rdf = rdf)

rdf <- create_subjectof(subject = hydrometric_network_subject,
                      url = paste0(wbd_info_base, hydrometric_network_id),
                      format = c("text/html","application/rdf+xml","application/x-turtle","application/ld+json"),
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_subjectof(subject = hydrometric_network_subject,
                      url = paste0(nldi_base, "huc12pp/", hu12$HUC_12, "/navigate/UT/wqp"),
                      format = "application/vnd.geo+json",
                      label = "GeoJSON",
                      rdf = rdf)

#### Find overlaps with the Southern St Lawrence Platform hydrogeounit.

hgu <- read_sf("https://geoconnex.ca/gsip/resources/aq/aq1")
hu12 <- st_join(hu12, select(hgu, hgu_uri = uri))

overlaps <- filter(hu12, !is.na(hu12$hgu_uri))

rdf <- create_association(subject = paste0(wbd_base, overlaps$HUC_12),
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfIntersects", 
                          object = overlaps$hgu_uri, 
                          rdf = rdf)

rdf <- create_association(subject = paste0(wbd_base, overlaps$HUC_12, "-drainage_basin"),
                          predicate = "http://www.opengeospatial.org/standards/geosparql/sfIntersects", 
                          object = overlaps$hgu_uri, 
                          rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")
