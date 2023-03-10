#' Get the dependencies of an package on CRAN
#' @section Dependencies: None
#'
#' @description ...
#' @param package sad
#' @param version  sd
#' @param cran.mirror vv
#' @param archiv.path fdf
#' @param main.path xc
#'
#' @section Side effects: None
#' @section Return: List of lists with structure c(<package_name>, <version>)
#' @export
#'
#' @note See all available CRAN Packages by Name here: https://cran.r-project.org/web/packages/available_packages_by_name.html
#'
#' @examples
#' \dontrun{
#'
#' #package-VERSION does not exist -> returns "version-error"
#' get_dependencies("ggmap","2.6.0" )
#'
#' # package-VERSION does not exist -> returns "version-error"
#' get_dependencies("ggplot2","26.6.6" )
#'
#' # package-NAME does not exist -> returns "package-name-error"
#' get_dependencies("ggmapAAA","3.0.0" )
#'
#' # package-NAME does not exist -> returns "package-name-error"
#' get_dependencies("ggplot222","1.0.0" )
#'
#' # package version in archive (-> https://cran.r-project.org/src/contrib/Archive/ggplot2/)
#' get_dependencies("ggplot2","3.1.1" )
#'
#' # current version, date: 2023.03.08 (on main page -> https://cran.r-project.org/web/packages/ggplot2/index.html)
#' get_dependencies("ggplot2","3.4.1" )
#'
#' # package version in archive (->https://cran.r-project.org/src/contrib/Archive/ggmap/)
#' get_dependencies("ggmap","3.0.0" )
#'
#' # current version, date: 2023.03.08 (on main page -> https://cloud.r-project.org/web/packages/ggmap/)
#' get_dependencies("ggmap","3.0.1" )
#' }
#'
#' @author Simon Ress

get_dependencies <- function(package, version, cran.mirror = "https://cloud.r-project.org/", archiv.path = "src/contrib/Archive/", main.path = "src/contrib/") {
  if(!is.character(package)) {warning("Provide the package name as string (e.g. 'ggplot2')"); stop()}
  if(!is.character(version)) {warning("Provide the version name as string (e.g. '3.1.0')"); stop()}

  #Check whether version is in archive or on main package-page
  #Construct URLs (1. archive / 2. main package page)
  archive.url = paste0(cran.mirror, archiv.path, package, "/", package, "_", version, ".tar.gz")
  main.page.url = paste0(cran.mirror, main.path, package, "_", version, ".tar.gz") # don't look into "/Archive/" -> get newest version
  #https://cloud.r-project.org/src/contrib/ggmap_3.0.1.tar.gz

  #Check if constructed URL is correct
  cat("------------------------------------------------- \n")
  check = suppressWarnings(try(readLines(archive.url), silent=T)) # open.connection(url(...),open="rt",timeout=10)
  #suppressWarnings(try(close.connection(url(archive.url)),silent=T))
  #suppressWarnings(try(closeAllConnections(),silent=T))
  if(inherits(check, "try-error")) {
    check = suppressWarnings(try(readLines(main.page.url), silent=T)) # open.connection(url(...),open="rt",timeout=10)
    #suppressWarnings(try(close.connection(url(main.page.url)),silent=T))
    #suppressWarnings(try(closeAllConnections(),silent=T))
    if(inherits(check, "try-error")) {
      cat("Error!!! Package ", package, " (version ",version, ") was not found here: \n", "- Archive: ", archive.url, "\n", "- Main page: ", main.page.url, "\n", sep="")
      cat("---","\n")

      #Check if package exists
      check = suppressWarnings(try(readLines(paste0(cran.mirror, "web/packages/", package)), silent=T))
      if(inherits(check, "try-error")) {
        #Messages
        cat("No package by name '", package,"' found!", "\n", sep="")
        cat("(INFO) Find a list of all packages on CRAN here: https://cran.r-project.org/web/packages/available_packages_by_name.html", "\n")
        cat("------------------------------------------", "\n")
        return("package-name-error")
      } else {
        #scrape versions in archive
        archive.versions = readLines(paste0("https://cloud.r-project.org/src/contrib/Archive/", package))
        archive.versions = archive.versions[(grep("Parent Directory", archive.versions)+1):(grep("<hr></pre>", archive.versions)-1)]
        archive.versions = sapply(strsplit(archive.versions, '<a href=\"'), \(x) strsplit(x[2], '.tar.gz\">')[[1]][1])
        #scrape newest version
        newest.version = readLines(paste0(cran.mirror, "web/packages/", package))
        newest.version = newest.version[grep("<td>Version:</td>",newest.version)+1]
        newest.version = gsub("<td>|</td>", "", newest.version)
        newest.version = paste0(package, newest.version)

        #Messages
        cat("(INFO) Available versions of '", package, "':","\n", sep="")
        cat("- In archive:", paste(archive.versions, collapse = ", "), "\n")
        cat("- Newest version:", newest.version, "\n")
        #suppressWarnings(try(closeAllConnections(),silent=T))
        cat("------------------------------------------", "\n")
        return("version-error")
      }


    }
    package.url = main.page.url
    cat("Package '", package, "' (version: ",version, ") was found on: ", package.url, "\n", sep="")
  } else if(!inherits(check, "try-error")){
    package.url = archive.url
    cat("Package '", package, "' (version: ",version, ") was found on: ", package.url, "\n", sep="")
  }

  # Download the package archive
  tmp_file <- tempfile()
  utils::download.file(package.url, destfile = tmp_file, quiet=T)

  # Extract the package archive
  tmp_dir <- tempdir()
  utils::untar(tmp_file, exdir = tmp_dir)

  # Read the DESCRIPTION file
  description_file <- file.path(tmp_dir, package, "DESCRIPTION")
  description <- read.dcf(description_file)

  #Extract required R-version
  req.r.version = strsplit(as.data.frame(description)$Depends, "\\(")[[1]][2]
  req.r.version = strsplit(req.r.version, ")")[[1]][1]
  req.r.version = gsub("\\)|\\=|>|<| |\n", "", req.r.version)

  #Extract required packages + versions
  if(!is.null(as.data.frame(description)$Imports)){
    Imports = strsplit(as.data.frame(description)$Imports, ",")[[1]]
    Imports = gsub(" |\n", "", Imports)
    dep.name = unlist(lapply(strsplit(Imports, "\\("), \(x) x[1]))
    dep.version = unlist(lapply(strsplit(Imports, "\\("), \(x) x[2]))
    dep.version = gsub("\\)|\\=|>|<| |\n", "", dep.version)

    dependencies = data.frame(name = dep.name, version = dep.version)
  } else{
    dependencies = NA
  }

  #Close all connections
  suppressWarnings(try(closeAllConnections(),silent=T))
  # showConnections(all = TRUE)

  # Return the required R-version and dependencies
  out = list("R-version" = data.frame(name="R",version=req.r.version), "Packages" = dependencies)
  return(out)
}

#test
#All available CRAN Packages by Name: https://cran.r-project.org/web/packages/available_packages_by_name.html

# get_dependencies("ggmap","2.6.0" ) # package-VERSION does not exist -> works
# get_dependencies("ggplot2","26.6.6" ) # package-VERSION does not exist -> works
#
# get_dependencies("ggmapAAA","3.0.0" ) # package-NAME does not exist -> works
# get_dependencies("ggplot222","1.0.0" ) # package-NAME does not exist -> works
#
#
# get_dependencies("ggplot2","3.1.1" ) # package version in archive -> works // https://cran.r-project.org/src/contrib/Archive/ggplot2/
# get_dependencies("ggplot2","3.4.1" ) # current (2023.03.08)  package version (on main page) -> works // https://cran.r-project.org/web/packages/ggplot2/index.html
#
# get_dependencies("ggmap","3.0.0" ) # package version in archive -> works // https://cran.r-project.org/src/contrib/Archive/ggmap/
# get_dependencies("ggmap","3.0.1" ) # current (2023.03.08) package version (on main page) -> works // https://cloud.r-project.org/web/packages/ggmap/
