import os
from PIL import Image
S='/mnt/user-data/outputs/pixi_cats/sleepsrc'; D='/mnt/user-data/outputs/pixi_cats/sleep'
os.makedirs(D,exist_ok=True)
for f in os.listdir(D): os.remove(os.path.join(D,f))
def breathe(im, sy, sx=1.0):
    W,H=im.size; bb=im.getbbox(); bottom=bb[3]
    t=im.resize((int(W*sx),int(H*sy)),Image.LANCZOS)
    out=Image.new('RGBA',(W,H),(0,0,0,0)); out.alpha_composite(t,(int((W-t.width)/2), int(bottom-bottom*sy)))
    return out
s0=Image.open(f'{S}/01.png').convert('RGBA'); s1=Image.open(f'{S}/02.png').convert('RGBA')
frames=[s0, breathe(s0,1.018,1.004), breathe(s0,1.035,1.008), s1, breathe(s1,1.018,1.004)]
for i,f in enumerate(frames): f.save(f'{D}/{i+1:02d}.png',optimize=True)
print('sleep',len(frames))
