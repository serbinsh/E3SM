load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"


;***********************************************************************;
; NCL script to plot PS
;***********************************************************************;
begin

plotsol=1
plotref=0

fnames =  systemfunc("ls movies/jw_baroclinic1.nc")
;fnames =  systemfunc("ls movies/asp_baroclinic1.nc")
 f      = addfiles(fnames,"r")       ; Open netCDF files.	


if (plotref.eq.1) then
  fnames2 =  systemfunc("ls ../eaT340.ps.nc")
   fref    = addfiles(fnames2,"r")       ; Open netCDF files.	
end if

if (isatt(f[0],"ne")) then
   NE=f[0]@ne
   NPTS = f[0]@np
   deg=360.0 / (4*NE*(NPTS-1))
   hdeg=sprintf("%4.2f", deg)
   print("NE="+NE+" NPTS="+NPTS+" degree="+hdeg)
else
   hdeg = ""
end if 


  ntimes = dimsizes(f[0]->time)
  nlev = dimsizes(f[0]->lev)
  nlat = dimsizes(f[0]->lat)
  nlon = dimsizes(f[0]->lon)
  print ("ntimes="+ntimes+" nlev="+nlev+" nlat x nlon "+nlat+"x"+nlon)


; change the levels and or times to plot here
  n9 = closest_val(9,f[0]->time)

  firsttime=n9
  lasttime=n9
  timeinc=1



  field = "ps"
  if ( isfilevar(f[0],"PS")) then
    field = "PS"
  end if 
sizevar = dimsizes(f[0]->$field$)
ntime = sizevar(0)
nlat=sizevar(1)
nlon=sizevar(2)



lat = f[0]->lat
lon = f[0]->lon
if ( 0.eq.1 ) then
   gw = f[0]->gw
   glat = gaus(nlat/2)
   print ("HOMME Gauss vs NCL Gauss latitudes:  max diff="+ max(abs(glat(:,0)- lat)) )
   print ("HOMME Gauss vs NCL Gauss weights:    max diff="+ max(abs(glat(:,1)- gw)) )
   d_eta = f[0]->ilev(1:26) - f[0]->ilev(0:25)
   print ("sum of gauss weights, eta weights: "+sum(gw)+" "+sum(d_eta))
end if



;  output_format = "ncgm"
  output_format = "pdf"
;  output_format = "X11"

  fcnt = dimsizes(fnames)
  print ("number of input files = " + fcnt )

  var = new((/nlat,nlon/),"double")
  diffl2 = new((/fcnt,lasttime+1/),"double")
  diffl2=0

   print ("ntimes="+ntimes+" nlat x nlon "+nlat+"x"+nlon)

  time = f[0]->time
  wks = gsn_open_wks(output_format,field)
  print ("Writing file "+field+"."+output_format)


do n=firsttime,lasttime,timeinc
do kf = 0,fcnt-1
;
; The first call below selects a colormap, and the second reverses it.
; The colors go from violet at the low valus to blue at the high
; values.
;
; To see the various colormaps, go to:
; http://ngwww.ucar.edu/ncl/coltable.html
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
;  gsn_reverse_colormap(wks)
; Any time you don't want a plot drawn, just set the resources:
;  res@gsnDraw  = False
;  res@gsnFrame = False
;
  res                     = True
  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@gsnSpreadColors     = True         ; Use full colormap, but start
;  res@gsnSpreadColorStart = 20           ; at color index 24.


  res@cnFillOn            = True         ; Turn on contour fill
  res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
  res@cnLinesOn           = True        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.
  res@lbBoxLinesOn        = False        ; Turn of labelbar box lines.
  res@mpGridAndLimbOn  = False
  res@mpGridSpacingF  = 10.0
  res@cnLevelSelectionMode = "ManualLevels"

  res@mpOutlineOn          = False
  res@mpFillOn             = False
  res@mpCenterLonF         = 0
  res@mpShapeMode          = "FreeAspect"



;  res@gsnAddCyclic = False                  ; This is not global data.
;    res@mpProjection = "CylindricalEquidistant"
;    res@mpLimitMode = "LatLon"
  res@mpCenterLonF         = 180
  res@mpMinLatF = 0
  res@mpMaxLatF = 90
  ;res@vpWidthF            = 1           ; change aspect ratio of plot
  ;res@vpHeightF           = .3

  varmin = 1.e9
  varmax = -1.
  var(:,:)= f[kf]->$field$(n,:,:)
  copyatt( var, f[kf]->$field$(n,:,:) )

  if ( "Pa" .eq. var@units) then
     var=var/100
     var@units="mb"
  end if

  if ( time(n) .ge. 7  ) then
     res@cnMinLevelValF = 940.
     res@cnMaxLevelValF = 1020.
     res@cnLevelSpacingF = 10.0
  else
     res@cnMinLevelValF = 993.
     res@cnMaxLevelValF = 1005.
     res@cnLevelSpacingF = 1.0
  end if 
  ;res@cnLevelSpacingF = (res@cnMaxLevelValF-res@cnMinLevelValF)/16.
  ;print(res@cnMinLevelValF+" "+res@cnMaxLevelValF) 

  res@tiMainString        = "HOMME "+hdeg+":F34:0"

  ;gsn_define_colormap(wks,"rainbow")                ; choose colormap
  ;gsn_define_colormap(wks,"wh-bl-gr-ye-re")
  ;gsn_define_colormap(wks,"WhViBlGrYeOrRe")
  gsn_define_colormap(wks,"cosam")
  if (plotsol .eq. 1) then
     print ("min/max = "+min(var(:,:))+", "+max(var(:,:)) + "  time="+time(n) )
     contour = gsn_csm_contour_map(wks,var(:,:),res)     ; Draw a contour plot.  ;
     print("Contour complete: "+res@tiMainString)
   end if

  if (plotref .eq. 1) then
    ; now plot the CAM contour plot:
    res@tiMainString        = "CAM T340"
    var2= fref[0]->PS(n,:,:)
    copyatt( var2, fref[0]->PS(n,:,:) )
    if ( "Pa" .eq. var2@units) then
       var2=var2/100
       var2@units="mb"
    end if
    print ("min/max = "+min(var2(:,:))+", "+max(var2(:,:)) + "  time="+time(n) )
    contour = gsn_csm_contour_map(wks,var2(:,:),res)     ; Draw a contour plot.  ;
    print("Contour complete: "+res@tiMainString)
  end if


end do  ; loop over file names
end do  ; loop over time level




end

