source("rdf_utils.R")

hu12 <- read_sf("hu12.geojson") %>% 
  st_set_geometry(NULL)

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

rdf <- create_seealso(subject = hu12_subject, 
                         seealso = paste0(wfs_base, "%27", hu12$HUC_12, "%27"),
                         format = "application/vnd.geo+json",
                         label = "GeoJSON",
                         rdf = rdf)

rdf <- create_seealso(subject = hu12_subject, 
                      seealso = paste0(wbd_info_base, hu12$HUC_12),
                      format = "text/html",
                      label = "Information Index",
                      rdf = rdf)

rdf <- create_seealso(subject = hu12_subject, 
                          seealso = paste0(wbd_nwc_base, hu12$HUC_12),
                          format = "text/html",
                          label = "Waterbudget Summary",
                          rdf = rdf)

##### HU12 Nexuses Based on All HU12 Outlets that Contribute to a Given HU. #####
hu12_outlet <- left_join(hu12_outlet, 
                         select(hu12, 
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

##### Create nexus associations to catchments and  
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

rdf  <- create_seealso(subject = paste0(wbd_nexus_base, nexus_wfs$nexus, "-inflow"),
                       seealso = nexus_wfs$wfs,
                       format = "application/vnd.geo+json",
                       label = "GeoJSON",
                       rdf = rdf)

rdf <- create_association(subject = paste0(wbd_nexus_base, 
                                           contributing_cats$nexus, 
                                           "-inflow"), 
                          predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/contributingCatchment", 
                          object = paste0(wbd_base, contributing_cats$contributingCatchment), 
                          rdf = rdf)

# Could add HY_HydrologicLocation features for the outlet of HU12s that are part of the nexues above.
# outlet_subject <- paste0(wbd_outlet_base, hu12_outlet$HUC_12)
# 
# rdf <- mint_feature(subject = outlet_subject,
#                     label = paste("Outlet of", hu12_outlet$HU_12_NAME), 
#                     type = "https://www.opengis.net/def/hy_features/ontology/hyf/HY_HydroloLocation", 
#                     rdf = rdf)
# 
# rdf <- create_association(subject = outlet_subject, 
#                           predicate = "https://www.opengis.net/def/hy_features/ontology/hyf/realizedNexus",
#                           object = paste0(wbd_nexus_base, hu12_outlet$HU_12_DS, "-inflow"),
#                           rdf = rdf)
# 
# rdf <- create_seealso(subject = outlet_subject, 
#                       seealso = paste0(wbd_outlet_info_base, hu12_outlet$HUC_12),
#                       format = "text/html",
#                       label = "Information Index",
#                       rdf = rdf)
# 
# rdf <- create_seealso(subject = outlet_subject, 
#                       seealso = paste0(fpp_wfs_base, "HUC_12%20IN%20(%27", hu12_outlet$HUC_12, "%27)"),
#                       format = "application/vnd.geo+json",
#                       label = "GeoJSON",
#                       rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")
