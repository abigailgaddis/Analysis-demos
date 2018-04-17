;========================================================================================
; Calculates the jet latitude index and maximum speed. Compares observational wind data 
; to model wind data at the Atlantic jet region: 0-60W, 15-75N, and outputs wind max 
; speed and latitude over time, and pdf of wind max and lat for observations and model
;
;
; 2/3/2015
; Abigail L. Gaddis
;=======================================================================================

   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------------------------------
; User settings
;----------------------------------------------------------------------------------------

   casename = "climate_model_run_of_interest"
   outputfile = "jli_"+casename
   dir = "/storage/myname/archive/"+casename+"/atm/"
   
   ;navigating to the output folder for the climate simulation, listing relevant files
   fil = systemfunc("cd "+dir+"  ; ls *.h2.nc")
   ;reading in the h2 = daily output files
   filelist = addfiles(dir+fil, "r")

   ;navigating to the observational data files and reading them in 
   obsname = "uwind850.1948-1958"
   obsdir = "/observational_wind_data_directory/"
   obsfil = systemfunc("cd "+obsdir+"  ; ls uwind850*")
   obslist = addfile(obsdir+obsfil, "r")

  ;select lat/lon box, Atlantic jet: 0-60W, 15-75N
   lonL = 0
   lonR = 60
   latS = 15
   latN = 75

;----------------------------------------------------------------------------------------
; Reading in file dimensions and variables
;----------------------------------------------------------------------------------------

; Read in dimensions from file, compute number of days in obs and simulation files
   time = filelist->time
   lon = filelist->lon
   otime = obslist->time

   ndays = dimsizes(time)
   ondays = dimsizes(otime)

   ; reading in U850 daily wind in specified lat/lon box
   wind = filelist->U850(:,{latS:latN},{lonL:lonR})
   obswind = obslist->uwnd(:,0,{latS:latN},{lonL:lonR})

   ; calculating number of latitude points within the lat/lon box, differs for obs and 
   ; simulation based on resolution
   lat = wind&lat
   nlats = dimsizes(lat)
   olat = obswind&lat
   onlats = dimsizes(olat)

;----------------------------------------------------------------------------------------
; Finding jet latitude index: the latitude of maximum westerly wind speed
;----------------------------------------------------------------------------------------

   ; calculating the maximum wind at each latitude over time, retaining metadata
   jetmax = dim_max_n_Wrap(wind, (/1,2/))
   ojetmax = dim_max_n_Wrap(obswind, (/1,2/))


   ; jet latitude location of max wind speed
   ; model data
   latmax = wind(0,:,0)
   latmax = 0
   jetlatindex = wind(:,0,0)
   jetlatindex = 0
   do t=0,ndays-1
      do l=0,nlats-1
         ;find max value of wind for all lons at a given lat and time
         windlon = wind(t,l,:)
         latmax(l) = max(windlon)
      end do
      ; index of the max value gives latitude of the max value
      jetlatindex(t) = doubletofloat(lat(maxind(latmax)))
   end do

   ; observations
   olatmax = obswind(0,:,0)
   olatmax = 0
   ojetlatindex = obswind(:,0,0)
   ojetlatindex = 0
   do t=0,ondays-1
      do l=0,onlats-1
         ;find max value of wind for all lons at a given lat and time
         owindlon = obswind(t,l,:)
         olatmax(l) = max(owindlon)
      end do
      ; index of the max value gives latitude of the max value
      ojetlatindex(t) = (/olat(maxind(olatmax))/)
   end do

   ; Jet latitude statistics - pdf of jet latitude index and maximum wind speed values
   jetlatfreq = pdfx(jetlatindex,0,False)
   jetmaxfreq = pdfx(jetmax,0,False)

   ojetlatfreq = pdfx(ojetlatindex,0,False)
   ojetmaxfreq = pdfx(ojetmax,0,False)

;----------------------------------------------------------------------------------------
; Plotting wind speeds over time and distributions of wind speed
;----------------------------------------------------------------------------------------


   ;create plot environment
   wks          = gsn_open_wks("pdf",outputfile)
   res          = True

   ;Change plot axis and title label size and text, remove tick marks
   res@tiXAxisFontHeightF       = 0.020
   res@tiYAxisFontHeightF       = 0.020
   res@gsnScale                 = True        ; force text scaling
   res@gsnMaximize              = True
   res@tmLabelAutoStride        = True
   res@tmXTOn                   = False
   res@tmYROn                   = False
   res@tiYAxisString            = "Maximum jet speed at 850 mb"
   res@tiXAxisString            = "Time (days)"

   ; Plot 1: maximum wind speed over time
   plot = gsn_csm_xy(wks,time,jetmax,res); create plot

   ; Plot 2: latitude of maximum wind speed over time
   res@tiYAxisString            = "Jet Latitude Index at 850 mb"
   plot2 = gsn_csm_xy(wks,time,jetlatindex,res)

   ; Plots 3 & 4: frequency distribution of jet speed and latitude
   plot3    = new ( 2, "graphic")
   modellabel = casename
   obslabel = "NCEP/NCAR Reanalysis 1948-58"
   labels = (/modellabel, obslabel/)
   res@pmLegendDisplayMode = "Always"
   res@xyExplicitLegendLabels   = labels
   res@xyLineColors         = (/"black","red"/)
   res@xyLineThicknesses    = (/2,2/)
   res@gsnMaximize              = False
   res@gsnDraw              = False
   res@gsnFrame             = False
   res@tiYAxisString        = "Frequency"
   res@tiXAxisString        = "Jet Maximum Latitude at 850 mb"

   plot3(0) = gsn_csm_xy (wks, jetlatfreq@bin_center, (/jetlatfreq,ojetlatfreq/), res)
   res@tiXAxisString            = "Jet Maximum Speed at 850 mb"
   plot3(1) = gsn_csm_xy (wks, jetmaxfreq@bin_center, (/jetmaxfreq,ojetmaxfreq/), res)
   gsn_panel(wks,plot3,(/1,2/),False)
