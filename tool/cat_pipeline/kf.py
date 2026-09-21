"""Keyframe pipeline: align AI-edited frames to a base image, cut out, fill body white.
usage: kf.py NAME base.png frame1.png frame2.png ...   -> /mnt/user-data/outputs/pixi_cats/NAME/01.png ...
Frames are aligned (similarity transform) to base using AKAZE matches + RANSAC,
refined with ECC on the lower (static) part. Output: square RGBA 512px, same crop for all."""
import sys, os
import numpy as np, cv2
from scipy import ndimage as ndi
from PIL import Image, ImageFilter

def ink(path, size=1024):
    im = Image.open(path).convert('L').resize((size, size), Image.LANCZOS)
    a = np.array(im).astype(np.float32)
    return np.clip((230 - a) / 170, 0, 1)

def align(base, img, static_mask=None):
    b8 = (base * 255).astype(np.uint8); i8 = (img * 255).astype(np.uint8)
    det = cv2.AKAZE_create(threshold=0.0005)
    kb, db = det.detectAndCompute(255 - b8, None)
    ki, di = det.detectAndCompute(255 - i8, None)
    M = np.array([[1, 0, 0], [0, 1, 0]], np.float32)
    if db is not None and di is not None and len(kb) > 10 and len(ki) > 10:
        bf = cv2.BFMatcher(cv2.NORM_HAMMING)
        m = bf.knnMatch(di, db, k=2)
        good = [a for a, b in (x for x in m if len(x) == 2) if a.distance < 0.8 * b.distance]
        if len(good) >= 8:
            src = np.float32([ki[g.queryIdx].pt for g in good]); dst = np.float32([kb[g.trainIdx].pt for g in good])
            M2, inl = cv2.estimateAffinePartial2D(src, dst, method=cv2.RANSAC, ransacReprojThreshold=4, maxIters=5000, confidence=0.999)
            if M2 is not None and inl is not None and inl.sum() >= 8:
                M = M2.astype(np.float32)
    # ECC refinement (euclidean) on static region
    warped = cv2.warpAffine(img, M, img.shape[::-1], flags=cv2.INTER_LINEAR)
    try:
        W = np.eye(2, 3, dtype=np.float32)
        mask = None if static_mask is None else static_mask.astype(np.uint8)
        _, W = cv2.findTransformECC(cv2.GaussianBlur(base, (0, 0), 3), cv2.GaussianBlur(warped, (0, 0), 3), W,
                                    cv2.MOTION_EUCLIDEAN, (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 200, 1e-6), mask, 5)
        M3 = np.vstack([M, [0, 0, 1]]); W3 = np.vstack([W, [0, 0, 1]])
        M = (np.linalg.inv(W3) @ M3)[:2].astype(np.float32)  # base(x)=warped(Wx) => img->base = W^-1 M
    except cv2.error:
        pass
    return M

def cutout(inkmap):
    mask = inkmap > 0.15
    yy, xx = np.mgrid[-6:7, -6:7]; d6 = (xx*xx + yy*yy) <= 36
    yy, xx = np.mgrid[-4:5, -4:5]; d4 = (xx*xx + yy*yy) <= 16
    closed = ndi.binary_closing(np.pad(mask, 10), structure=d4)[10:-10, 10:-10]
    filled = ndi.binary_fill_holes(closed)
    filled = ndi.binary_opening(filled, structure=d6)
    lab, n = ndi.label(filled)
    if n:
        sizes = ndi.sum(filled, lab, range(1, n + 1)); keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > 800])
    else:
        keep = filled
    body = np.array(Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))) / 255.0
    a = np.maximum(body * 0.97, inkmap)
    rgb = np.where(inkmap[..., None] > 0, (0x24 * inkmap[..., None] + 255 * (1 - inkmap[..., None]) * body[..., None] / np.maximum(a[..., None], 1e-6)), 255)
    out = np.zeros(inkmap.shape + (4,), np.uint8); out[..., :3] = np.clip(rgb, 0, 255); out[..., 3] = np.clip(a * 255, 0, 255)
    return out

if __name__ == '__main__':
    name, base_p, frames = sys.argv[1], sys.argv[2], sys.argv[3:]
    base = ink(base_p)
    H, Wd = base.shape
    static = np.zeros_like(base, bool); static[int(H * 0.55):, :] = True   # lower body/feet/tail rarely move
    inks = [base]
    for f in frames:
        img = ink(f)
        M = align(base, img, static)
        inks.append(cv2.warpAffine(img, M, (Wd, H), flags=cv2.INTER_LINEAR))
        print(os.path.basename(f), 'scale %.3f rot %.2f tx %.1f ty %.1f' % (np.hypot(M[0,0], M[1,0]), np.degrees(np.arctan2(M[1,0], M[0,0])), M[0,2], M[1,2]))
    # common crop: union bbox over all frames, square, with margin
    union = np.zeros_like(base, bool)
    for k in inks: union |= k > 0.2
    if os.environ.get('FIXED', '1') == '1':
        # same crop for every animation: square around the BASE cat, bottom-anchored
        ys, xs = np.where(base > 0.2)
        by0, by1, bx0, bx1 = ys.min(), ys.max(), xs.min(), xs.max()
        side = int((by1 - by0) * 1.30); cx = (bx0 + bx1) // 2
        if os.environ.get('CROPREF'):
            ref = ink(os.environ['CROPREF']); ry, rx = np.where(ref > 0.2)
            rh = ry.max() - ry.min(); side = int(rh * 1.30)
            by0 = by1 - rh
        y1 = by1 + int((by1 - by0) * 0.03); y0 = y1 - side; x0 = cx - side // 2
        uy, ux = np.where(union)
        if uy.min() < y0 or ux.min() < x0 or ux.max() > x0 + side:
            print('WARNING: some frame exceeds the fixed crop', uy.min() - y0, ux.min() - x0, x0 + side - ux.max())
    else:
        ys, xs = np.where(union); pad = 24
        y0, y1, x0, x1 = ys.min() - pad, ys.max() + pad, xs.min() - pad, xs.max() + pad
        side = max(y1 - y0, x1 - x0); cx = (x0 + x1) // 2
        y0 = max(0, y1 - side); x0 = max(0, cx - side // 2)
    out_dir = f'/mnt/user-data/outputs/pixi_cats/{name}'; os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir): os.remove(os.path.join(out_dir, f))
    tiles = []
    if os.environ.get('NOBASE') == '1':
        inks = inks[1:]
    for i, k in enumerate(inks):
        rgba = cutout(k)
        crop = Image.fromarray(rgba).crop((x0, y0, x0 + side, y0 + side)).resize((512, 512), Image.LANCZOS)
        crop.save(f'{out_dir}/{i+1:02d}.png', optimize=True); tiles.append(crop)
    # contact + onion skin preview
    cs = Image.new('RGBA', (256 * len(tiles), 256), (200, 185, 240, 255))
    for i, t in enumerate(tiles): cs.alpha_composite(t.resize((256, 256)), (256 * i, 0))
    cs.convert('RGB').save(f'{name}_contact.jpg', quality=88)
    onion = Image.new('RGBA', (512, 512), (255, 255, 255, 255))
    for t in tiles:
        a = np.array(t).astype(float); a[..., 3] *= 0.45; onion.alpha_composite(Image.fromarray(a.astype(np.uint8)))
    onion.convert('RGB').save(f'{name}_onion.jpg', quality=88)
    print('frames', len(tiles), 'crop', side)
