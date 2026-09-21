# gif.py name "1:800,2:120,3:120,..." out.gif  (frame index 1-based : ms)
import sys
from PIL import Image
name, seq, out = sys.argv[1], sys.argv[2], sys.argv[3]
d=f'/mnt/user-data/outputs/pixi_cats/{name}'
frames=[]; durs=[]
for part in seq.split(','):
    i,ms=part.split(':')
    t=Image.open(f'{d}/{int(i):02d}.png').convert('RGBA').resize((320,320),Image.LANCZOS)
    bg=Image.new('RGBA',(360,360),(236,230,250,255)); bg.alpha_composite(t,(20,20))
    frames.append(bg.convert('P',palette=Image.ADAPTIVE,colors=128)); durs.append(int(ms))
frames[0].save(out,save_all=True,append_images=frames[1:],duration=durs,loop=0,disposal=2)
print('gif',out,len(frames))
