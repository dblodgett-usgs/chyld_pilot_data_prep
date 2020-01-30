source("rdf_utils.R")
rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

rdf <- create_association(paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"),
                          "https://geoconnex.ca/id/connectedTo",
                          "https://geoconnex.ca/id/LOD_Node/CAN_Hydro_LOD_Node", rdf = rdf)

rdf <- create_subjectof(subject = paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                        url = "https://cida-test.er.usgs.gov/chyld-pilot/data/node/cross", 
                        format = c("application/x-turtle", "application/rdf+xml", "application/ld+json"),  
                        label = "Connections to other nodes", 
                        provider = "https://labs.waterdata.usgs.gov",
                        conformsto = "https://github.com/NRCan/GSIP",
                        rdf = rdf)

rdf <- create_subjectof(subject = paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                        url = "https://cida-test.er.usgs.gov/chyld-pilot/data/node/connect", 
                        format = c("application/x-turtle", "application/rdf+xml", "application/ld+json"),  
                        label = "Connected nodes", 
                        provider = "https://labs.waterdata.usgs.gov",
                        conformsto = "https://github.com/NRCan/GSIP",
                        rdf = rdf)

rdf <- create_subjectof(subject = paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                        url = "https://cida-test.er.usgs.gov/chyld-pilot/data/node/all", 
                        format = c("application/x-turtle", "application/rdf+xml", "application/ld+json"),  
                        label = "Catalog of features", 
                        provider = "https://labs.waterdata.usgs.gov",
                        conformsto = "https://github.com/NRCan/GSIP",
                        rdf = rdf)

rdf <- create_association(paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"),
                   "http://www.w3.org/2000/01/rdf-schema#label",
                   "Hydrography Linked Data Node - United States of America", rdf = rdf)

rdf <- create_association("https://geoconnex.ca/id/LOD_Node/CAN_Hydro_LOD_Node",
                   "http://www.w3.org/2000/01/rdf-schema#label",
                   "Hydrography Linked Data Node - Canada", rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")


