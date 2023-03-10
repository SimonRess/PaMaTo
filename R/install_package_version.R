#' ....
#' @section Dependencies:
#' - get_installed_packages() [<- update_packages_search_path()]
#'
#' - get_dependencies()
#'
#' - update_packages_search_path()
#'
#' @description -> Recursive function <-
#' @param package sad
#' @param version  sd
#' @param lib.install.path vv
#'
#' @section Side effects:
#' @section Return:
#' @export
#'
#' @note See all available CRAN Packages by Name here: https://cran.r-project.org/web/packages/available_packages_by_name.html
#'
#' @examples
#' \dontrun{
#' sessionInfo()
#' install_package_version("ggplot2", "3.4.0")
#' sessionInfo()
#' library_version("ggplot2", "3.4.0")
#' sessionInfo()
#' detach(paste0("package:","ggplot2"), character.only = TRUE) # character.only = TRUE <- needed when paste0() or object used
#' }
#'
#' @author Simon Ress


install_package_version = function(package, version, lib.install.path=.libPaths()[1]) {
  if(!is.character(package)) {warning("Provide the package name as string (e.g. 'ggplot2')"); stop()}
  if(!is.character(version)) {warning("Provide the version name as string (e.g. '3.1.0')"); stop()}

  #Create package.url & package.install.path
  cran.mirror = "https://cloud.r-project.org/"
  package.url = paste0(cran.mirror, "src/contrib/Archive/", package, "/", package, "_", version, ".tar.gz")
  package.install.path = paste0(lib.install.path,"/", package, "_", version)
  cat("------------------------------------------------- \n")
  cat("Package Url: ", package.url, "\n", sep="")
  cat("Local package installation folder: ", package.install.path, "\n", sep="")


  #Check installed R Version
  rversion.installed = paste0(R.version$major,".",R.version$minor)

  #Check which dependencies are needed & Check whether package-name and -version exist
  # package = "ggplot2"
  # version = "3.4.0"
  # package = "vctrs"
  # version = "0.5.0"
  depends.on = get_dependencies(package, version)

  rversion.required = depends.on$`R-version`$version

  #Check R-VERSION
  if(rversion.installed != rversion.required) {
    cat("-------------------------------------------------------------------")
    cat("The installed r-version does not match the required r-version (installed:",rversion.installed," < required:",rversion.required,")\n", sep="")
    install = ""
    while(toupper(install)!="Y" & toupper(install)!="N") {
      install <- readline(prompt=paste0("Do you want to install the required R-Version (",rversion.required,") now [Y/N]?: "))
      if(toupper(install) == "Y") cat("Not implementet yet (dependency 'installr' & 'devtools' would be needed, what is not desired). \n -> Please install R-version ",rversion.required," by your own and try install_requirements() again. \n", sep="")
      if(toupper(install) == "N") cat("-> Please install R-version ",rversion.required," by your own and try install_requirements() again. \n", sep="")
    }
    cat("-------------------------------------------------------------------")
  }

  #Some packages don't use dependencies -> do stuff below only when dependencies are present
  if(!all(is.na(depends.on$Packages))){ # all() needed because obj is normaly a dataframe and is.na() produces therefore several outputs
    #Check already installed packages & R-verison
    already.installed = get_installed_packages()
    #keep only the highest installed version
    already.installed = merge(stats::aggregate(version ~ name, max, data = already.installed), already.installed)

    #Uninstalled but required packages or installed version too old
    m = merge(depends.on$Packages, already.installed, by="name", all.x = TRUE, all.y = FALSE, suffixes = c(".required",".installed"))
    #print(m)
    get1 = m[is.na(m$version.installed),] # required, but not installed (or not version available)
    #print(get1)
    get2 = m[!is.na(m$version.required) & m$version.required > m$version.installed,] # required version > installed version
    #print(get2)
    get = rbind(get1,get2)
    if(nrow(get)>0){
      cat("Unsatisfied requirements: \n")
      print(get)
    }else cat("All requirements satisfied: \n")

    #Recursion: Invoke itself until there are no more unfulfilled preconditions, continue script with this package -> after ending the script, continue with the next "higher" package below if condition
    if(nrow(get)>0){
      for(p in 1:nrow(get)) {
        cat("------------------------------------------------- \n")
        cat("Installing Requirenment:", p, get$name[p], get$version.required[p], "\n")
        install_package_version(get$name[p], get$version.required[p], lib.install.path)
      }
    }

  }

  #detach package
  #capture.output(suppressWarnings(detach(paste0("package:",package), character.only = TRUE, force = TRUE)), file='NUL') # character.only = TRUE <- needed when paste0() or object used
  suppressWarnings(try(detach(paste0("package:",package), character.only = TRUE, force = T), silent = T))


  #Rekursive function
  install_and_check = function() {
    #Create folder to install package in: <package.name>_<version>
    if(!dir.exists(package.install.path)) dir.create(package.install.path)
    #Check if constructed url is correct
    cat("------------------------------------------------- \n")
    check = suppressWarnings(try(readLines(package.url), silent = T)) # open.connection(url(),open="rt",timeout=t)
    #suppressWarnings(try(close.connection(url(package.url)),silent=T))
    #Install package if url (archive) is correct, use it
    if(!inherits(check, "try-error")) {
      cat("Installing package '", package, "' (version ", version, ") from '", package.url, "' (and dependencies!).", "\n", sep="")
      utils::install.packages(package.url, repos=NULL, type="source", lib=package.install.path)
      #try main page
    } else{
      new.package.url = paste0(cran.mirror, "src/contrib/", package, "_", version, ".tar.gz") # don't look into "/Archive/" -> get newest version
      check = suppressWarnings(try(readLines(new.package.url),silent = T)) # open.connection(url(),open="rt",timeout=t
      #suppressWarnings(try(close.connection(url(new.package.url)),silent=T))
      if(!inherits(check, "try-error")) {
        cat("Installing package '", package, "' (version ", version, ") from '", new.package.url, "' (and dependencies!).", "\n", sep="")
        utils::install.packages(new.package.url, repos=NULL, type="source", lib=package.install.path)
      } else {
        cat("Error!!! Package ", package, " (version: ",version, ") was not found in: \n", sep="")
        cat("- ", package.url, "\n", sep="")
        cat("- ", new.package.url, "\n", sep="")
      }
    }


    #Load packages once in order to check if desired version can be used
    #capture.output(suppressWarnings(detach(paste0("package:",package), character.only = TRUE,unload=TRUE,force = TRUE)), file='NUL') # character.only = TRUE <- needed when paste0() or object used
    suppressWarnings(try(detach(paste0("package:",package), character.only = TRUE, force = T), silent = T))
    cat("Try to load packages from: ", package.install.path, "\n", sep ="")
    error = try(library(package, lib.loc = package.install.path, character.only = TRUE), silent = TRUE) # character.only = TRUE <- needed when paste0() or object used
    if(!inherits(error, "try-error")){
      if(version == utils::packageVersion(package)) cat(paste0("Check: Desired version (-> ", version, ") of the package '", package, "' loaded"))
      if(version != utils::packageVersion(package)) cat(paste0("Check: Error!!! Version '", utils::packageVersion(package), "' instead of desired version ", version, " of packages '", package, "' loaded"))
      return(TRUE)
    }
    if(inherits(error, "try-error")){
      cat("Installation of package ", package, " (version:", version,") was NOT successful!\n", sep ="")
      cat("Retry the installation one more time.\n")
      unlink(package.install.path, recursive = TRUE) # delete empty folder
      return(FALSE)
    }
  }

  success = FALSE
  i = 1
  while(all(success == FALSE, i < 4)){ # Three attempts to install an package
    if(i>1) cat(i, ". attempt to install the package ", package, " (version:", version, ")\n", sep="")
    #detach before installing
    suppressWarnings(try(detach(paste0("package:",package), character.only = TRUE, force = T), silent = T))
    #try to install the package
    success = install_and_check()
    i =i+1
  }
  if(success== FALSE) {
    cat("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
    cat("Your r-version and the specified packages version are not compatible! \n")
    cat("Installed r-version: ", rversion.installed, "\n")
    cat("By package (min.) required r-version: ", rversion.required, "\n")
    cat("-> Check whether you can use a package-version which depends on an r-version closer to yours \n")
    cat("-> or you can install an r-version which is closer to the required r-version of this package version. \n")
    cat("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
    stop()
  }

  #capture.output(suppressWarnings(detach(paste0("package:",package), character.only = TRUE,unload=TRUE,force = TRUE)), file='NUL') # character.only = TRUE <- needed when paste0() or object used
  suppressWarnings(try(detach(paste0("package:",package), character.only = TRUE, force = T), silent = T))


  #Update the "Search Paths for Packages" (-> '.libPaths()')
  update_packages_search_path(path = package.install.path)  # c(lib.install.path, package.install.path)
}
