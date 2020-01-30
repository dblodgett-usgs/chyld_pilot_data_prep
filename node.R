source("rdf_utils.R")
rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

rdf <- create_association(paste0(id_domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"),
                          "https://geoconnex.ca/id/connectedTo",
                          "https://geoconnex.ca/id/LOD_Node/CAN_Hydro_LOD_Node", rdf = rdf)

rdf <- create_subjectof(subject = paste0(id_domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                        url = "https://cida-test.er.usgs.gov/chyld-pilot/data/node/cross", 
                        format = c("application/x-turtle", "application/rdf+xml", "application/ld+json"),  
                        label = "Connections to other nodes", 
                        provider = "https://labs.waterdata.usgs.gov",
                        conformsto = "https://github.com/NRCan/GSIP",
                        rdf = rdf)

rdf <- create_subjectof(subject = paste0(id_domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                        url = "https://cida-test.er.usgs.gov/chyld-pilot/data/node/connect", 
                        format = c("application/x-turtle", "application/rdf+xml", "application/ld+json"),  
                        label = "Connected nodes", 
                        provider = "https://labs.waterdata.usgs.gov",
                        conformsto = "https://github.com/NRCan/GSIP",
                        rdf = rdf)

rdf <- create_subjectof(subject = paste0(id_domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                        url = "https://cida-test.er.usgs.gov/chyld-pilot/data/node/all", 
                        format = c("application/x-turtle", "application/rdf+xml", "application/ld+json"),  
                        label = "Catalog of features", 
                        provider = "https://labs.waterdata.usgs.gov",
                        conformsto = "https://github.com/NRCan/GSIP",
                        rdf = rdf)

rdf <- create_association(paste0(id_domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"),
                   "http://www.w3.org/2000/01/rdf-schema#label",
                   "Hydrography Linked Data Node - United States of America", rdf = rdf)

rdf <- create_association("https://geoconnex.ca/id/LOD_Node/CAN_Hydro_LOD_Node",
                   "http://www.w3.org/2000/01/rdf-schema#label",
                   "Hydrography Linked Data Node - Canada", rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")

node_sparql <- paste0("PREFIX geoconnex: <", id_domain, "> ",
                      "PREFIX usgs: <", domain, "> ",
                      "SELECT * { ",
                      "?subject ?predicate ?object . ",
                      "FILTER(isUri(?object) && STRSTARTS(STR(?object), STR(usgs:)) && STRSTARTS(STR(?subject), STR(geoconnex:))) ",
                      "}")

ids <- rdf_query(rdf, node_sparql)

ids <- dplyr:select(ids, subject)

library(xml2)

make_mapping <- function(path, target, creator, type = "1:1", 
                         description = "", action = "303", 
                         action_name = "location") {
  list(mapping = list(path = list(path), 
                      type = list(type), 
                      description = list(description), 
                      creator = list(creator),
                      action = list(type = list(action),
                                    name = list(action_name),
                                    value = list(target))))
}

mappings <- lapply(1:nrow(ids), function(id, ids) {
  make_mapping(gsub("http://geoconnex.us/", "", ids[id, ]$subject),
               ids[id, ]$object, creator = "dblodgett@usgs.gov", 
               description = "made for GSIP / CHyLD pilot project testing")
}, ids = ids)

attr(mappings, "xmlns") <- "urn:csiro:xmlns:pidsvc:backup:1.0"

out <- list(backup = mappings)
doc <- as_xml_document(out)

xml2::write_xml(doc, "test.xml")
