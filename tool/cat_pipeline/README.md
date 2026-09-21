# Cat animation pipeline

Each animation = a few keyframes, generated **one image at a time** as edits of one clean
base drawing (`_shots/in/icon_cat.png`), then aligned automatically and cut out.

1. In ChatGPT: upload the base image, prompt
   "Edit this image for an animation keyframe. Keep EVERYTHING identical (...). Change ONLY: <pose>.
   Exactly two ears, two front legs, one tail."  (one new chat per keyframe)
2. Save the result to `_shots/in/<name>_<n>.png`.
3. `python3 kf.py <anim> _shots/in/icon_cat.png _shots/in/<anim>_1.png ...`
   - aligns every frame to the base (AKAZE features + RANSAC, ECC refinement on the static lower body)
   - same square crop for all animations (FIXED=1, default) so the cat never jumps between screens
   - `NOBASE=1` leaves the base out of the output, `CROPREF=<img>` takes the crop size from another cat
   - writes `<anim>_contact.jpg` and `<anim>_onion.jpg` (all frames overlaid) for checking
4. Programmatic motion: `hop.py` (jump with squash & stretch), `breathe.py` (sleeping breath).
5. `gif.py <anim> "1:1400,2:140,..." out.gif` previews a sequence; copy the same order/timings
   into `CatAnims` in `lib/widgets/pixi_cat.dart`.

Needs: python3, numpy, scipy, pillow, opencv-python.
