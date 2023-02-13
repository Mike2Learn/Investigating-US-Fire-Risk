#' Functions utilized in exploratory_complete_us_analysis.R

#' Function: connect_to_db()
#' ---
#' Function to connect to my local database
#' ---
#' Inputs:
#'     None
#' --
#' Output:
#'     connection object to my local database
connect_to_db <- function() {
    
    host_name <- "localhost"
    port_no <- 3306
    u_id <- "root"
    db_name <- "Stats_506_Final_Proj_DB"
    
    conn <- RMySQL::dbConnect(RMySQL::MySQL(),
                              host = host_name,
                              port_no = port_no,
                              user = u_id,
                              password = getPass(),
                              dbname = db_name)
}
