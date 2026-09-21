import os
from PIL import Image
src=Image.open('/mnt/user-data/outputs/pixi_cats/happysrc/01.png').convert('RGBA')
W,H=src.size
bb=src.getbbox(); bottom=bb[3]
def pose(sx,sy,up):
    w,h=int(W*sx),int(H*sy)
    t=src.resize((w,h),Image.LANCZOS)
    out=Image.new('RGBA',(W,H),(0,0,0,0))
    # keep feet (bottom of bbox) anchored, then lift
    nb=int(bottom*sy)
    out.alpha_composite(t,(int((W-w)/2), int(bottom-nb-up)))
    return out
d='/mnt/user-data/outputs/pixi_cats/happy'; os.makedirs(d,exist_ok=True)
for f in os.listdir(d): os.remove(os.path.join(d,f))
frames=[pose(1,1,0), pose(1.05,0.93,0), pose(0.98,1.03,14), pose(0.99,1.02,30), pose(1.03,0.96,0)]
for i,f in enumerate(frames): f.save(f'{d}/{i+1:02d}.png',optimize=True)
print('happy frames',len(frames))
