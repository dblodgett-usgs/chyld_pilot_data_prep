library(xml2)
user <- "dblodgett@usgs.gov"
action <- "303"

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

root <- make_mapping("chyld-pilot/id/LOD_Node/US_Hydro_LOD_Node", 
             "https://cida-test.er.usgs.gov/chyld-pilot/info/LOD_Node/US_Hydro_LOD_Node",
             creator = user, description = "made for GSIP / CHyLD pilot project")

attr(root, "xmlns") <- "urn:csiro:xmlns:pidsvc:backup:1.0"

out <- list(backup = root)
doc <- as_xml_document(out)

xml2::write_xml(doc, "test.xml")

