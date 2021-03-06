#' Calculate the sample depth of a defol object
#'
#' @param x A defol object.
#'
#' @return A data.frame containing the years and number of trees
#'
#' @export
sample_depth <- function(x) {
  if(!is.defol(x)) stop("x must be a defol object")
  x_stats <- defol_stats(x)
  n_trees <- nrow(x_stats)
  out <- data.frame(year = min(x_stats$first):max(x_stats$last))
  for(i in 1:n_trees){
    yrs <- x_stats[i, ]$first : x_stats[i, ]$last
    treespan <- data.frame(year = yrs, z = 1)
    names(treespan)[2] <- paste(x_stats$series[i])
    out <- merge(out, treespan, by=c('year'), all=TRUE)
  }
  if(n_trees > 1){
    out$samp_depth <- rowSums(out[, -1], na.rm=TRUE)
  }
  else out$samp_depth <- out[, -1]
  out <- subset(out, select=c('year', 'samp_depth'))
  return(out)
}

#' Descriptive statistics for defoliation trees
#'
#' @param x A defol object after running \code{defoliate_trees}.
#'
#' @return A data frame containing tree/series-level statistics.
#'
#' @export
defol_stats <- function(x) {
  if(!is.defol(x)) stop("x must be a defol object")
  plyr::ddply(x, c('series'), function(df) {
    first <- min(df$year)
    last <- max(df$year)
    years <- length(df$year)
    count <- plyr::count(df, "defol_status")
    num_defol <- count[count$defol_status == "max_defol", ]$freq
    tot_defol <- sum(count[count$defol_status != "nd", ]$freq)
    avg_defol <- round(tot_defol / num_defol, 0)
    out <- c(first, last, years, num_defol, tot_defol, avg_defol)
    names(out) <- c("first", "last", "years", "num_events", "tot_years", "mean_duration")
    return(out)
    }
  )
}

#' Outbreak statistics
#'
#' @param x An outbreak object after running \code{outbreak}
#'
#' @return A data.frame with descriptive statistics for each outbreak event determined by \code{outbreak},
#'  including start and end years, duration, the year with the most number of trees in the outbreak and its
#'  associated tree count, and the year with the maximum growth suppression with its associated mean_ngsi value.
#'
#'@export
outbreak_stats <- function(x){
  if(!is.outbreak(x)) stop ("x must be an outbreak object")
  events <- rle(x$outbreak_status == "outbreak")
  events_index <- cumsum(events$lengths)
  events_pos <- which(events$values == TRUE)
  ends <- events_index[events_pos]
  newindex = ifelse(events_pos > 1, events_pos - 1, 0)
  starts <- events_index[newindex] + 1
  if (0 %in% newindex) starts = c(1,starts)
  deps <- data.frame(cbind(starts, ends))
  start_years <- x$year[starts]
  end_years <- x$year[ends]
  duration <- end_years - start_years + 1
  peaks <- data.frame(matrix(NA, ncol=7, nrow=nrow(deps)))
  names(peaks) <- c("num_trees_start", "perc_trees_start", "peak_outbreak_year",
                    "num_trees_outbreak", "peak_defol_year", "min_gsi", "mean_ngsi")
  for(i in 1:nrow(deps)){
    ob <- x[deps$starts[i] : deps$ends[i], ]
    peaks[i, 1] <- ob[1, ]$num_defol
    peaks[i, 2] <- ob[1, ]$perc_defol
    peaks[i, 3] <- ob[which.max(ob$num_defol), ]$year
    peaks[i, 4] <- max(ob$num_defol)
    peaks[i, 5] <- ob[which.min(ob$mean_ngsi), ]$year
    peaks[i, 6] <- round(min(ob$mean_gsi), 3)
    peaks[i, 7] <- round(min(ob$mean_ngsi), 3)
  }
  out <- data.frame(start = start_years, end = end_years,
                    duration = duration)
  out <- cbind(out, peaks)
  return(out)
}
