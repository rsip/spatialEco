#' @title Surface curvature
#' @description Calculates Zevenbergen & Thorne, McNab's or Bolstad's curvature 
#' 
#' @param x      rasterLayer object
#' @param s      Focal window size
#' @param type   Method used c("planform", "profile", "total", "mcnab", "bolstad")
#' @param ...    Additional arguments passed to writeRaster
#' 
#' @return raster class object of surface curvature
#'
#' @note
#' The planform and profile curvatures are the second derivative(s) of the elevation surface, or the slope of the slope. 
#' Profile curvature is in the direction of the maximum slope, and the planform curvature is perpendicular to the direction of the maximum slope.
#' Negative values in the profile curvature indicate the surface is upwardly convex whereas, positive values indicate that the surface is upwardly concave.  
#' Positive values in the planform curvature indicate an that the surface is laterally convex whereas, negative values indicate that the surface is laterally concave.
#  Total curvature is the sigma of the profile and planform curvatures. A value of 0 in profile, planform or total curvature, indicates the surface is flat. 
#' The planform, profile and total curvatures are derived using Zevenbergen & Thorne (1987) via a quadratic equation fit to eight neighbors as such, the s (focal window size) argument is ignored. 
#'
#' @note
#' McNab's and Bolstad's variants of the surface curvature (concavity/convexity) index (McNab 1993; Bolstad & Lillesand 1992; McNab 1989). 
#' The index is based on features that confine the view from the center of a 3x3 window. In the Bolstad equation, edge correction is addressed 
#' by dividing by the radius distance to the outermost cell (36.2m). 
#' 
#' @author Jeffrey S. Evans  <jeffrey_evans@@tnc.org>
#' 
#' @references
#' Bolstad, P.V., and T.M. Lillesand (1992). Improved classification of forest vegetation in northern Wisconsin through a rule-based combination of soils, terrain, and Landsat TM data. Forest Science. 38(1):5-20.
#' Florinsky, I.V. (1998). Accuracy of Local Topographic Variables Derived from Digital Elevation Models. International Journal of Geographical Information Science, 12(1):47-62.
#' McNab, H.W. (1989). Terrain shape index: quantifying effect of minor landforms on tree height. Forest Science. 35(1):91-104.
#' McNab, H.W. (1993). A topographic index to quantify the effect of mesoscale landform on site productivity. Canadian Journal of Forest Research. 23:1100-1107.
#' Zevenbergen, L.W. & C.R. Thorne (1987). Quantitative Analysis of Land Surface Topography. Earth Surface Processes and Landforms, 12:47-56.
#'
#' @examples 
#'   library(raster)
#'   data(elev)
#'   elev <- projectRaster(elev, crs="+proj=robin +datum=WGS84", 
#'                         res=1000, method='bilinear')
#'
#'   m.crv <- curvature(elev, type="mcnab")
#'   b.crv <- curvature(elev, type="bolstad")
#'   t.crv <- curvature(elev, type="total")
#'     par(mfrow=c(2,2))
#'       plot(t.crv, main="Total curvature") 
#'       plot(m.crv, main="McNab curvature") 
#'       plot(b.crv, main="Bolstad curvature")
#'     
#' @seealso \code{\link[raster]{writeRaster}} For additional ... arguments passed to writeRaster
#'
#' @export curvature
curvature <- function(x, s = 3, type=c("planform", "profile", "total", "mcnab", "bolstad"), ...) { 
  if (!inherits(x, "RasterLayer")) stop("MUST BE RasterLayer OBJECT")
    type=type[1] 
    zt.crv <- function(m, method = type, res = raster::res(x)[1], ...) {
        p=(m[6]-m[4])/(2*res)
          q=(m[2]-m[8])/(2*res)
            r=(m[4]+m[6]-2*m[5])/(2*(res^2))
            s=(m[3]+m[7]-m[1]-m[9])/(4*(res^2))
          tx=(m[2]+m[8]-2*m[5])/(2*(res^2))
      if(type == "planform") {
        return( round( -(q^2*r-2*p*q*s+p^2*tx)/((p^2+q^2)*sqrt(1+p^2+q^2)),6) ) 
      } else if(type == "profile") {
        return( round( -(p^2*r+2*p*q*s+q^2*tx)/((p^2+q^2)*sqrt(1+p^2+q^2)^3),6 ) )
      } else if(type == "total") {
        return( round( -(q^2*r-2*p*q*s+p^2*tx)/((p^2+q^2)*sqrt(1+p^2+q^2)),6) + 
		        round( -(p^2*r+2*p*q*s+q^2*tx)/((p^2+q^2)*sqrt(1+p^2+q^2)^3),6 ) ) 
	   } else {
	     stop("Not a valid option")
       }
    }	   
    if( type == "mcnab" | type == "bolstad") {    
        if( length(s) == 1) s = c(s[1],s[1])
           m <- matrix(1, nrow=s, ncol=s)
    if(type == "bolstad") {
        return( 10000 * ((x - raster::focal(x, w=m, fun=mean)) / 1000 / 36.2) )  
      } else {
        mcnab <- function(x, ...) (((x[5] - x) + (x[5] - x)) / 4) / 36.2
        return( raster::focal(x, w=m, fun=mcnab, ...) )
      }  
    } else {  
      return( raster::focal(x, w=matrix(1,nrow=3,ncol=3), fun = zt.crv, 
	                        pad = TRUE, padValue = 0, ...) )
    }
}	
 
