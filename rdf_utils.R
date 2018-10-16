library(sf)
library(dplyr)
library(tidyr)
library(rdflib)
library(HUCAgg)

# Feature NIR base urls
wbd_base <- "http://localhost/id/hu/"
wbd_outlet_base <- "http://localhost/id/hu_outlet/"
wbd_nexus_base <- "http://localhost/id/hu_nexus/"
nwis_gage_base <- "http://localhost/id/gage/"
nwis_hu_hydrometricnetwork_base <- "http://localhost/id/gage_hu_network/"
nat_aq_base <- "http://localhost/id/nat_aq/"

# gsip base urls
wbd_info_base <- "http://localhost/info/hu/"
wbd_outlet_info_base <- "http://localhost/info/hu_outlet/"
wbd_nexus_info_base <- "http://localhost/info/hu_nexus/"
nwis_gage_info_base <- "http://localhost/info/gage/"
nwis_hu_hydrometricnetwork_info_base <- "http://localhost/info/gage_hu_network/"
nat_aq_info_base <- "http://localhost/info/nat_aq/"

# predicate bases
hy_base <- "https://www.opengis.net/def/hy_features/ontology/hyf/"
rdf_base <- "http://www.w3.org/2000/01/rdf-schema#"
dct_base <- "http://purl.org/dc/terms/"

# Resource base urls
wfs_base <- "https://cida.usgs.gov/nwc/geoserver/WBD/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=WBD:huc12&outputFormat=application%2Fjson&cql_filter=huc12="
hu08_wfs_base <- "https://cida.usgs.gov/nwc/geoserver/WBD/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=WBD:huc08&outputFormat=application%2Fjson&cql_filter="
wbd_nwc_base <- "https://cida.usgs.gov/nwc/#!waterbudget/huc/"
fpp_wfs_base <- "https://www.sciencebase.gov/catalogMaps/mapping/ows/5762b664e4b07657d19a71ea?service=wfs&request=getfeature&version=1.0.0&typename=sb:fpp&outputFormat=application%2fjson&srsName=EPSG:4326&cql_filter="
wbd_nwis_base <- "https://waterdata.usgs.gov/hydrological-unit/"
gages_wfs_base <- "https://cida.usgs.gov/nwc/geoserver/NWC/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=NWC:gagesII&srsName=EPSG:4326&outputFormat=application%2Fjson"
nat_aq_wfs_base <- "https://cida.usgs.gov/ngwmn/geoserver/wfs?service=WFS&version=1.0.0&request=GetFeature&typeName=ngwmn:aquifrp025&srsName=EPSG:4326&outputFormat=application%2Fjson"


split_seealso <- function(x) {
  rbind(select(x, subject, object = seeAlso) %>%
          mutate(predicate = paste0(rdf_base, "seeAlso")),
        select(x, subject = seeAlso, object = format) %>%
          mutate(predicate = paste0(dct_base, "format")),
        select(x, subject = seeAlso, object = label) %>%
          mutate(predicate = paste0(rdf_base, "label"))) %>%
    select(subject, predicate, object)
}

add_to_rdf <- function(x, rdf) { # dumb implementation, but it does the job!
  message(paste("Adding", nrow(x), "to rdf."))
  for(r in seq(1, nrow(x))) {
    rdf <- rdf_add(rdf, x$subject[r], x$predicate[r], x$object[r])
  }
  return(rdf)
}

create_seealso <- function(subject, seealso, format, label = "", rdf = NULL) {
  ld <- split_seealso(data.frame(subject = subject, 
                           seeAlso = seealso, 
                           format = format, 
                           label = label, 
                           stringsAsFactors = FALSE))
  if (!is.null(rdf)) {
    return(add_to_rdf(ld, rdf))
  } else {
    return(ld)
  }
}

mint_feature <- function(subject, label, type, rdf = NULL) {
  ld <- data.frame(subject = subject, label = label, 
                   type = type, stringsAsFactors = FALSE)
  ld <- rename_ld(ld)
  ld <- gather(ld, predicate, object, -subject)
  
  if (!is.null(rdf)) {
    return(add_to_rdf(ld, rdf))
  } else {
    return(ld)
  }
}

create_association <- function(subject, predicate, object, rdf = NULL) {
  ld <- data.frame(subject = subject, 
                   predicate = predicate, 
                   object = object, stringsAsFactors = FALSE)
  if (!is.null(rdf)) {
    return(add_to_rdf(ld, rdf))
  } else {
    return(ld)
  }
}

rename_ld <- function(x) {
  
  old_names <- c("subject",  
                 "label", 
                 "type")
  new_names <- c("subject",  
                 paste0(rdf_base, "label"), 
                 "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  
  if (!all(names(x) %in% old_names)) 
    stop(paste("unsupported names passed in must be in", old_names))
  
  names_picker <- old_names %in% names(x)
  old_names <- old_names[names_picker]
  new_names <- new_names[names_picker]

  names(x)[match(old_names, names(x))] <- new_names

  return(x)
}
