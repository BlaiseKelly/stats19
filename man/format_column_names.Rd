% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/format.R
\name{format_column_names}
\alias{format_column_names}
\title{Format column names of raw stats19 data}
\usage{
format_column_names(column_names)
}
\arguments{
\item{column_names}{Column names to be cleaned}
}
\description{
This function takes messy column names and returns clean ones that work well with
R by default. Names that are all lower case with no R-unfriendly characters
such as spaces and `-` are returned.
}
\examples{
\dontrun{
crashes_raw = read_accidents()
column_names = names(crashes_raw)
column_names
format_column_names(column_names = column_names)
}
}