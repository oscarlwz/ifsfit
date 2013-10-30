;
; History
;  10jul17  DSNR  re-written for new GMOS data, 
;                 based on new PLOTSTRONGLINES routine
;
; Plot strong emission line fits.
;

pro gmos_plotstronglines,instr,outfile,ps=ps,zbuf=zbuf,comp=comp,$
                         plotilines=plotilines,oplothan2=oplothan2,$
                         xran=xran,yran=yran,xmar=xmar,ymar=ymar,$
                         xtickint=xtickint,xminor=xminor,layout=layout

  if ~ keyword_set(oplothan2) then begin
     dops=0
     dozbuf=0
     if keyword_set(ps) then dops=1
     if keyword_set(zbuf) then dozbuf=1
     if ~ keyword_set(comp) then comp=1

     if (dops) then begin
        set_plot,'ps',/copy,/interpolate
        device,filename=outfile+'.eps',/encapsulated,/inches,$
               xsize=10,ysize=7.5,bits_per_pixel=8,/color
        !P.charsize=1
        !P.charthick=1
     endif else if (dozbuf) then begin
        set_plot,'Z'
        device,decomposed=0,set_resolution=[1920,960],set_pixel_depth=24
        !P.charsize=1
        !P.charthick=1
        erase
     endif else begin
        set_plot,'X'
        device,decomposed=0
        window,xsize=1280,ysize=960,xpos=0,ypos=0,retain=2
        !P.charsize=1
        !P.charthick=1
     endelse

  endif

  defaultXtickint=!X.tickinterval
  defaultXminor=!X.minor
  if keyword_set(xtickint) then !X.tickinterval = xtickint $
  else !X.tickinterval=20
  if keyword_set(xminor) then !X.minor = xminor $
  else !X.minor=5

  wave = instr.wave

; polynomial near Ha/[NII]
  ypoly = dblarr(n_elements(wave))
  npoly = instr.param[4]
  wavelo = instr.param[5]
  wavehi = instr.param[6]
  n2hawave = where(wave ge wavelo AND wave le wavehi)
  ypoly[n2hawave] = poly(wave[n2hawave]-mean(wave[n2hawave]),instr.param[7:7+npoly])

  spectot = instr.spec
  specstars = instr.spec - instr.specfit + ypoly
  speclines = instr.spec_nocnt - ypoly
  specerr = instr.spec_err
  modtot = instr.specfit + (instr.spec - instr.spec_nocnt)
  modstars = instr.spec - instr.spec_nocnt + ypoly
  modlines = instr.specfit - ypoly

  norm = max(modstars)
  spectot /= norm
  specstars /= norm
  speclines /= norm
  specerr /= norm
  modtot /= norm
  modstars /= norm
  modlines /= norm
     
  if keyword_set(comp) then zbase = instr.z.gas[comp-1] $
  else zbase = instr.z.star

  lab = textoidl(['H\alpha/[NII]','[OI]'])
  off = [-15d,15d]
  xran1 = ([6548.0d,6583.4d]+6d*off) * (1d + zbase)
  xran2 = ([6300.3d,6363.7d]+6d*off) * (1d + zbase)
  xran1ss = ([6548.0d,6583.4d]+3d*off) * (1d + zbase)
  xran2ss = ([6300.3d,6363.7d]+3d*off) * (1d + zbase)
  telran1 = [6865d,6925d]
  telran2 = [6275d,6285d]
  i1 = where(wave gt xran1[0] AND wave lt xran1[1],ct1)
  i2 = where(wave gt xran2[0] AND wave lt xran2[1],ct2)
  i1ss = where(wave gt xran1ss[0] AND wave lt xran1ss[1],ct1ss)
  i2ss = where(wave gt xran2ss[0] AND wave lt xran2ss[1],ct2ss)

; Halpha / [NII]

  if ~ keyword_set(oplothan2) then begin

     if keyword_set(plotilines) then begin
        ncomp = instr.param[1]
        colors = [255,75,125,75]
     endif

     pxl = [0,0.06,0.37]
     pxu = [0,0.33,0.95]
     pyl = [0,0.05,0.15,0.55,0.65]
     pyu = [0,0.15,0.45,0.65,0.95]

     loadct,0,/silent
     ydat = spectot
     ymod = modtot
     yran = [min([ydat[i1],ymod[i1]]),max([ydat[i1],ymod[i1]])]
     ip = [1,4]
     plot,wave,ydat,xran=xran1,yran=yran,/xsty,/ysty,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]],$
          xtickn=replicate(' ',60)
     loadct,13,/silent
     polyfill,[telran1,reverse(telran1)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran1[0],yran[0],xran1[1],yran[1]]
     polyfill,[telran2,reverse(telran2)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran1[0],yran[0],xran1[1],yran[1]]
     oplot,wave,ymod,color=75,thick=4
     oplot,wave,modstars,color=255,thick=5
     loadct,0,/silent
     xyouts,xran1[0]+(xran1[1]-xran1[0])*0.05d,$
            yran[0]+(yran[1]-yran[0])*0.85d,$
            lab[0],charsize=1.5,charthick=2
     ydat = specerr
     yran = [min(ydat[i1]),max(ydat[i1])]
     ip = [1,3]
     plot,wave,ydat,xran=xran1,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]]

     ydat = speclines
     ymod = modlines
     yran = [min([ydat[i1ss],ymod[i1ss]]),max([ydat[i1ss],ymod[i1ss]])]
     ip = [2,4]
     plot,wave,ydat,xran=xran1ss,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]],$
          xtickn=replicate(' ',60)
     loadct,13,/silent
     polyfill,[telran1,reverse(telran1)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran1ss[0],yran[0],xran1ss[1],yran[1]]
     polyfill,[telran2,reverse(telran2)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran1ss[0],yran[0],xran1ss[1],yran[1]]
     if keyword_set(plotilines) then begin
        for i=1,ncomp do begin
           flux = gmos_componeline(instr,'[NII]6548',i,center=clam)
           cgoplot,wave,flux/norm,color=colors[i-1],thick=4
           cgoplot,[clam,clam],yran,linesty=2,color=colors[i-1],thick=2
           flux = gmos_componeline(instr,'Halpha',i,center=clam)
           cgoplot,wave,flux/norm,color=colors[i-1],thick=4
           cgoplot,[clam,clam],yran,linesty=2,color=colors[i-1],thick=2
           flux = gmos_componeline(instr,'[NII]6583',i,center=clam)
           cgoplot,wave,flux/norm,color=colors[i-1],thick=4
           cgoplot,[clam,clam],yran,linesty=2,color=colors[i-1],thick=2
        endfor
     endif
     loadct,0,/silent
     ydat = specerr
     yran = [min(ydat[i1ss]),max(ydat[i1ss])]
     ip = [2,3]
     plot,wave,ydat,xran=xran1ss,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]]

; [OI]

     ydat = spectot
     ymod = modtot
     yran = [min([ydat[i2],ymod[i2]]),max([ydat[i2],ymod[i2]])]
     ip = [1,2]
     plot,wave,ydat,xran=xran2,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]],$
          xtickn=replicate(' ',60)
     loadct,13,/silent
     polyfill,[telran1,reverse(telran1)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran2[0],yran[0],xran2[1],yran[1]]
     polyfill,[telran2,reverse(telran2)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran2[0],yran[0],xran2[1],yran[1]]
     oplot,wave,ymod,color=75,thick=4
     oplot,wave,modstars,color=255,thick=4
     loadct,0,/silent
     xyouts,xran2[0]+(xran2[1]-xran2[0])*0.05d,$
            yran[0]+(yran[1]-yran[0])*0.85d,$
            lab[1],charsize=1.5,charthick=2
     ydat = specerr
     yran = [min(ydat[i2]),max(ydat[i2])]
     ip = [1,1]
     plot,wave,ydat,xran=xran2,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]]

     ydat = speclines
     ymod = modlines
     yran = [min([ydat[i2],ymod[i2]]),max([ydat[i2],ymod[i2]])] 
     ip = [2,2]
     plot,wave,ydat,xran=xran2ss,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]],$
          xtickn=replicate(' ',60)
     loadct,13,/silent
     polyfill,[telran1,reverse(telran1)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran2ss[0],yran[0],xran2ss[1],yran[1]]
     polyfill,[telran2,reverse(telran2)],[yran[0],yran[0],yran[1],yran[1]],$
              /line_fill,spacing=0.5d,color=125,noclip=0,$
              clip=[xran2ss[0],yran[0],xran2ss[1],yran[1]]
     if keyword_set(plotilines) then begin
        for i=1,ncomp do begin
           flux = gmos_componeline(instr,'[OI]6300',i,center=clam)
           oplot,wave,flux/norm,color=colors[i-1],thick=4
           oplot,[clam,clam],yran,linesty=2,color=colors[i-1],thick=2
           flux = gmos_componeline(instr,'[OI]6364',i,center=clam)
           oplot,wave,flux/norm,color=colors[i-1],thick=4
           oplot,[clam,clam],yran,linesty=2,color=colors[i-1],thick=2
        endfor
     endif
     loadct,0,/silent
     ydat = specerr
     yran = [min(ydat[i2ss]),max(ydat[i2ss])]
     ip = [2,1]
     plot,wave,ydat,xran=xran2ss,yran=yran,/xsty,/ysty,/noerase,$
          position=[pxl[ip[0]],pyl[ip[1]],pxu[ip[0]],pyu[ip[1]]]

; Finish

     tmpfile = outfile
     if (dops) then device,/close_file $
     else img = tvread(filename=tmpfile,/jpeg,/nodialog,quality=100)

  endif else begin

     if ~keyword_set(xran) then begin
        print,'ERROR: GMOS_PLOTSTRONGLINES: XRAN not specified.'
        exit
     endif
     if ~keyword_set(xmar) then begin
        print,'ERROR: GMOS_PLOTSTRONGLINES: XMAR not specified.'
        exit
     endif
     if ~keyword_set(ymar) then begin
        print,'ERROR: GMOS_PLOTSTRONGLINES: YMAR not specified.'
        exit
     endif
     if ~keyword_set(layout) then begin
        print,'ERROR: GMOS_PLOTSTRONGLINES: LAYOUT not specified.'
        exit
     endif

     if keyword_set(plotilines) then begin
        ncomp = instr.param[1]
        colors = ['Black','Blue','Green']
     endif

     ydat = spectot
     ymod = modtot
     yran = [min([ydat[i1],ymod[i1]]),max([ydat[i1],ymod[i1]])]
     ;; yran = [0,max([ydat[i1],ymod[i1]])]
     ;; ydat = speclines
     ;; ymod = modlines
     ;; yran = [min([ydat[i1s],ymod[i1s]]),max([ydat[i1s],ymod[i1s]])]

     cgplot,wave,ydat,/xsty,/ysty,xran=xran,yran=yran,layout=layout,$
            xmar=xmar,ymar=ymar
     if keyword_set(plotilines) then begin
        for i=1,ncomp do begin
           flux = gmos_componeline(instr,'[NII]6548',i,center=clam)
           cgplot,wave,flux/norm+modstars,color=colors[i-1],$
                  thick=2,linesty=2,/over
           flux = gmos_componeline(instr,'Halpha',i,center=clam)
           cgplot,wave,flux/norm+modstars,color=colors[i-1],$
                  thick=2,linesty=2,/over
           flux = gmos_componeline(instr,'[NII]6583',i,center=clam)
           cgplot,wave,flux/norm+modstars,color=colors[i-1],$
                  thick=2,linesty=2,/over
        endfor
     endif

     cgoplot,wave,ymod,color='Red',thick=4
     cgoplot,wave,modstars,color='Blue',thick=4

  endelse

  !X.tickinterval=defaultXtickint
  !X.minor=defaultXminor
  
end
