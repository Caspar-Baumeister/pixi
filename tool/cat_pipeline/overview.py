from PIL import Image, ImageDraw
A={
 'idle':([1,2,1,2,1],[2600,130,170,130,2200]),
 'wave':([1,2,3,4,3,4,3,2],[1400,140,170,170,170,170,170,140]),
 'curious':([1,2,1,3],[1500,1000,600,1000]),
 'sad':([1,2,1,3],[1400,900,500,1100]),
 'happy':([1,2,3,4,3,5,1],[1200,110,80,170,80,110,300]),
 'gym':([1,2],[700,900]),
 'bell':([1,2,1,2],[1500,260,140,260]),
 'sleep':([1,2,3,2,1,4,5,4],[320,320,420,320,320,320,420,320]),
}
T=200; S=200; total=10000
cache={}
def fr(n,i):
    k=(n,i)
    if k not in cache: cache[k]=Image.open(f'/mnt/user-data/outputs/pixi_cats/{n}/{i:02d}.png').convert('RGBA').resize((S,S),Image.LANCZOS)
    return cache[k]
def at(n,t):
    seq,ms=A[n]; L=sum(ms); t%=L
    for s,m in zip(seq,ms):
        if t<m: return s
        t-=m
    return seq[-1]
frames=[]
names=list(A)
for t in range(0,total,80):
    bg=Image.new('RGBA',(S*4,S*2+30),(236,230,250,255)); d=ImageDraw.Draw(bg)
    for j,n in enumerate(names):
        x,y=(j%4)*S,(j//4)*(S+15)
        bg.alpha_composite(fr(n,at(n,t)),(x,y)); d.text((x+8,y+S-2),n,fill=(90,80,120,255))
    frames.append(bg.convert('P',palette=Image.ADAPTIVE,colors=96))
frames[0].save('/mnt/user-data/outputs/cats_overview.gif',save_all=True,append_images=frames[1:],duration=80,loop=0)
print(len(frames))
