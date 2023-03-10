% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/install_requirements.R
\name{install_requirements}
\alias{install_requirements}
\title{...}
\usage{
install_requirements(
  req.file.path = getwd(),
  req.file.name = "requirements.txt",
  list = "all",
  library.folder.path = getwd(),
  library.folder.name = "lib"
)
}
\arguments{
\item{req.file.path}{(chr vector):}

\item{req.file.name}{(chr vector):}

\item{list}{(chr vector):}

\item{library.folder.path}{(chr vector):}

\item{library.folder.name}{(chr vector):}
}
\description{
...
}
\details{
test
}
\section{Dependencies}{

- get_requirements()

- get_installed_packages()

- install_package_version()
}

\section{Side effects}{
 ...
}

\section{Return}{
 ...
}

\examples{
\dontrun{
# use 'requirements.txt.' within the current working directory
install_requirements()

# use 'req.txt' within the lib folder of the current working directory
install_requirements(req.file.path=paste(getwd(),"lib",sep="/"),
                     req.file.name="requirements.txt",
                     list="all",
                     library.folder.path=getwd(),
                     library.folder.name="lib")
}

}
\seealso{
\code{\link[utils]{.libPaths()}}
}
\author{
Simon Ress
}
\keyword{...}
