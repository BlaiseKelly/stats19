#' Download, read and format STATS19 data in one function.
#'
#' @section Details:
#' This function uses gets STATS19 data. Behind the scenes it uses
#' `dl_stats19()` and `read_*` functions, returning a
#' `tibble` (default), `data.frame`, `sf` or `ppp` object, depending on the
#' `output_format` parameter.
#' The function returns data for a specific year (e.g. `year = 2022`)
#'
#' Note: for years before 2016 the function may return data from more years than are
#' requested due to the nature of the files hosted at
#' [data.gov.uk](https://www.data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data).
#'
#' As this function uses `dl_stats19` function, it can download many MB of data,
#' so ensure you have a sufficient disk space.
#'
#' If `output_format = "data.frame"` or `output_format = "sf"` or `output_format
#' = "ppp"` then the output data is transformed into a data.frame, sf or ppp
#' object using the [as.data.frame()] or [format_sf()] or [format_ppp()]
#' functions, as shown in the examples.
#'
#' @seealso [dl_stats19()]
#' @seealso [read_collisions()]
#'
#' @inheritParams dl_stats19
#' @param format Switch to return raw read from file, default is `TRUE`.
#' @param output_format A string that specifies the desired output format. The
#'   default value is `"tibble"`. Other possible values are `"data.frame"`, `"sf"`
#'   and `"ppp"`, that, respectively, returns objects of class [`data.frame`],
#'   [`sf::sf`] and [`spatstat.geom::ppp`]. Any other string is ignored and a tibble
#'   output is returned. See details and examples.
#' @param ... Other arguments be passed to [format_sf()] or
#'   [format_ppp()] functions. Read and run the examples.
#'
#' @export
#' @examples
#' \donttest{
#' if(curl::has_internet()) {
#' x = get_stats19(2022, silent = TRUE, format = TRUE)
#' class(x)
#' # data.frame output
#' x = get_stats19(2022, silent = TRUE, output_format = "data.frame")
#' class(x)
#'
#' # Run tests only if endpoint is alive:
#' if(nrow(x) > 0) {
#'
#' # sf output
#' x_sf = get_stats19(2022, silent = TRUE, output_format = "sf")
#'
#' # sf output with lonlat coordinates
#' x_sf = get_stats19(2022, silent = TRUE, output_format = "sf", lonlat = TRUE)
#' sf::st_crs(x_sf)
#'
#' if (requireNamespace("spatstat.geom", quietly = TRUE)) {
#' # ppp output
#' x_ppp = get_stats19(2022, silent = TRUE, output_format = "ppp")
#'
#' # We can use the window parameter of format_ppp function to filter only the
#' # events occurred in a specific area. For example we can create a new bbox
#' # of 5km around the city center of Leeds
#'
#' leeds_window = spatstat.geom::owin(
#' xrange = c(425046.1, 435046.1),
#' yrange = c(428577.2, 438577.2)
#' )
#'
#' leeds_ppp = get_stats19(2022, silent = TRUE, output_format = "ppp", window = leeds_window)
#' spatstat.geom::plot.ppp(leeds_ppp, use.marks = FALSE, clipwin = leeds_window)
#'
#' # or even more fancy examples where we subset all the events occurred in a
#' # pre-defined polygon area
#'
#' # The following example requires osmdata package
#' # greater_london_sf_polygon = osmdata::getbb(
#' # "Greater London, UK",
#' # format_out = "sf_polygon"
#' # )
#' # spatstat works only with planar coordinates
#' # greater_london_sf_polygon = sf::st_transform(greater_london_sf_polygon, 27700)
#' # then we extract the coordinates and create the window object.
#' # greater_london_polygon = sf::st_coordinates(greater_london_sf_polygon)[, c(1, 2)]
#' # greater_london_window = spatstat.geom::owin(poly = greater_london_polygon)
#'
#' # greater_london_ppp = get_stats19(2022, output_format = "ppp", window = greater_london_window)
#' # spatstat.geom::plot.ppp(greater_london_ppp, use.marks = FALSE, clipwin = greater_london_window)
#' }
#' }
#' }
#' }

get_stats19 = function(year = NULL,
                      type = "collision",
                      data_dir = get_data_directory(),
                      file_name = NULL,
                      format = TRUE,
                      ask = FALSE,
                      silent = FALSE,
                      output_format = "tibble",
                      ...) {

  if(!exists("type")) {
    stop("Type is required", call. = FALSE)
  }
  if (!output_format %in% c("tibble", "data.frame", "sf", "ppp")) {
    warning(
      "output_format parameter should be one of c('tibble', 'data.frame', 'sf', 'ppp').\n",
      "You entered ", output_format, ".\n",
      "Defaulting to tibble.",
      call. = FALSE,
      immediate. = TRUE
    )
    output_format = "tibble"
  }
  if (grepl("casualties", type, ignore.case = TRUE) && output_format %in% c("sf", "ppp")) {
    warning(
      "You cannot select output_format = 'sf' or output_format = 'ppp' when type = 'casualties'.\n",
      "Casualties do not have a spatial dimension.\n",
      "Defaulting to tibble output_format",
      call. = FALSE,
      immediate. = TRUE
    )
    output_format = "tibble"
  }

  # download what the user wanted
  # this is saved in the directory defined by data_dir
  file_path <- dl_stats19(year = year,
             type = type,
             data_dir = data_dir,
             file_name = file_name,
             ask = ask,
             silent = silent)

  ## read in file
  ve = read_ve_ca(path = file_path)
  ## read in set to NULL
  read_in = NULL
  # read in from the file path defined above
  if(grepl("vehicles", type, ignore.case = TRUE)){
    if(format) {
      read_in = format_vehicles(ve)
    } else {
      read_in = ve
    }
  } else if(grepl("casualty", type, ignore.case = TRUE)) {
    if(format) {
      read_in = format_casualties(ve)
    } else {
      read_in = ve
    }
  } else { # inline with type = "collision" by default
    if(format) {
      read_in = format_collisions(ve)
    } else {
      read_in = ve
    }

  # transform read_in into the desired format
  if (output_format != "tibble") {
    read_in = switch(
      output_format,
      "data.frame" = as.data.frame(read_in, ...),
      "sf" = format_sf(read_in, ...),
      "ppp" = format_ppp(read_in, ...)
    )
  }

  read_in
  }

}

#' Get data download dir
#' @examples
#' # get_data_directory()
get_data_directory = function() {
  data_directory = Sys.getenv("STATS19_DOWNLOAD_DIRECTORY")
  if(data_directory != "") {
    return(data_directory)
  }
  tempdir()
}

#' Set data download dir
#'
#' Handy function to manage `stats19` package underlying environment
#' variable. If run interactively it makes sure user does not change
#' directory by mistatke.
#'
#' @param data_path valid existing path to save downloaded files in.
#' @examples
#' # set_data_directory("MY_PATH")
