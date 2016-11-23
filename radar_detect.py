#!/usr/bin/env python
from PIL import Image
import types
import sys
import os

filename=sys.argv[1]
im=Image.open(filename)
#define focus_box (whole png is x800*y700)
focus_box=(350,250,550,450) #xbgn, ybgn, xend, yend
out_im=im.crop(focus_box).convert("RGB")
nx,ny=out_im.size
#out_im.save("thumbnail.png")
#print nx,ny
#get dbz pixel count
level_colors=[(0,236,236), (1,160,246), (1,0,246), 
              (0,239,0), (0,200,0), (0,144,0), 
              (255,255,0), (231,192,0), (255,142,2),
              (255,0,0), (166,0,0), (101,0,0),
              (255,0,255), (209,209,209), (255,255,255)]
level_lower=range(5,76,5)
nlev=len(level_lower)
level_cnt=[0] * nlev
level_ratio=[0] * nlev
for count, (r,g,b) in out_im.getcolors(out_im.size[0] *out_im.size[1]):
    for ilev in range(0,nlev):
        if (r==level_colors[ilev][0]) and (g==level_colors[ilev][1]) and (b==level_colors[ilev][2]):
            level_cnt[ilev]=count
            level_ratio[ilev]=count*1.0/(nx*ny)
            break
level_sumup_ratio=[0] * nlev
for i in range(0,nlev):
    level_sumup_ratio[-i]=sum(level_ratio[-i:nlev])
#define critical of rain
#2. dbz>25, ratio>10%, dbz>30, ratio>1%
file_title=os.path.split(filename)[1]
if (level_sumup_ratio[4] > 0.1) and (level_sumup_ratio[6]>0.01) :
    print "%s: dbz>%d (%6.3f), dbz>%d (%6.3f): DETECT RAIN" %(file_title, level_lower[4], level_sumup_ratio[4], level_lower[6], level_sumup_ratio[6])
else:
    print "%s: dbz>%d (%6.3f), dbz>%d (%6.3f): DETECT NO RAIN" %(file_title, level_lower[4], level_sumup_ratio[4], level_lower[6], level_sumup_ratio[6])
