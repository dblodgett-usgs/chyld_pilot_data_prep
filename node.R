source("rdf_utils.R")
rdf <- rdf_parse("../GSIP/WebContent/repos/gsip/relations.ttl")

rdf <- create_association(paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"),
                          "https://geoconnex.ca/id/connectedTo",
                          "https://geoconnex.ca/id/LOD_Node/CAN_Hydro_LOD_Node", rdf = rdf)

rdf <- create_seealso(subject = paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                      seealso = "https://raw.githubusercontent.com/dblodgett-usgs/GSIP/master/mockups/id/LOD_Node/US_Hydro_LOD_Node_TTL", 
                      format = "application/x-turtle", 
                      label = "Connection Nodes", 
                      rdf = rdf)

rdf <- create_seealso(subject = paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                      seealso = "https://raw.githubusercontent.com/dblodgett-usgs/GSIP/master/mockups/id/LOD_Node/US_Hydro_LOD_Node_RDF", 
                      format = "application/rdf+xml", 
                      label = "Connection Nodes", 
                      rdf = rdf)

rdf <- create_seealso(subject = paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"), 
                      seealso = "https://raw.githubusercontent.com/dblodgett-usgs/GSIP/master/mockups/id/LOD_Node/US_Hydro_LOD_Node_JSONLD", 
                      format = "application/ld+json", 
                      label = "Connection Nodes", 
                      rdf = rdf)

rdf <- create_association(paste0(domain, "chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node"),
                   "http://www.w3.org/2000/01/rdf-schema#label",
                   "Hydrography Linked Data Node - United States of America", rdf = rdf)

rdf <- create_association("https://geoconnex.ca/id/LOD_Node/CAN_Hydro_LOD_Node",
                   "http://www.w3.org/2000/01/rdf-schema#label",
                   "Hydrography Linked Data Node - Canada", rdf = rdf)

rdflib::rdf_serialize(rdf, "../GSIP/WebContent/repos/gsip/relations.ttl", "turtle")

node_sparql <- paste0("PREFIX usgs: <", domain, "> ",
                      "PREFIX ca: <https://geoconnex.ca> ",
                      "SELECT * { ",
                            "?subject ?predicate ?object . ",
                            "FILTER(isUri(?object) && STRSTARTS(STR(?object), STR(ca:))) ",
                            "}")

outbound <- rdf_query(rdf, node_sparql)
outbound <- add_to_rdf(outbound, rdf())

rdf_serialize(outbound, "../GSIP/mockups/id/LOD_Node/US_Hydro_LOD_Node_TTL", format = "turtle")  
rdf_serialize(outbound, "../GSIP/mockups/id/LOD_Node/US_Hydro_LOD_Node_RDF", format = "rdfxml")
rdf_serialize(outbound, "../GSIP/mockups/id/LOD_Node/US_Hydro_LOD_Node_JSONLD", format = "jsonld")  

rdf_serialize(outbound, "../GSIP/mockups/id/LOD_Node/US_Hydro_LOD_Node_TTL", format = "turtle")  

