#!/usr/bin/env python3
"""Extract the eight original AI portraits without redrawing or recoloring them.

Code-based background removal continues the user's recorded authorization in
docs/generated-art-register.md (staged seated-opponent expression pack).
"""
from pathlib import Path
import hashlib, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / 'outputs/locals_opponents/peach_soda_cast_v1'
OUT = ROOT / 'assets/generated/peach_soda_opponents'
DOC = Path(__file__).resolve().parent
CAST = [
    ('pip',862,940,[(720,949)]),
    ('otis',893,970,[]),
    ('ines',887,950,[(595,839)]),
    ('sana',898,972,[]),
    ('milo',874,954,[(513,761)]),
    ('bea',876,947,[(721,920)]),
    ('kit',887,973,[(1022,815)]),
    ('ellis',884,952,[(495,821),(990,818),(721,930)]),
]

def extract(name, table_y, arm_y, seeds):
    number = [c[0] for c in CAST].index(name)+1
    path=SRC/f'{number:02d}-{name}.png'
    source=Image.open(path).convert('RGB')
    rgb=np.asarray(source)
    # Dark ink is a closed boundary. Broad flat interior colors remain exact.
    ink = (rgb.max(2) < 85)
    barrier=Image.fromarray(ink.astype('uint8')*255)
    # Close occasional subpixel pinholes in outer ink before flooding.
    barrier=barrier.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    flooded=barrier.copy()
    edge_seeds=[(0,y) for y in range(0,source.height,8)]+[(source.width-1,y) for y in range(0,source.height,8)]+[(x,0) for x in range(0,source.width,8)]+[(x,source.height-1) for x in range(0,source.width,8)]
    for point in edge_seeds+seeds:
        if flooded.getpixel(point)==0:
            ImageDraw.floodfill(flooded,point,128)
    outside=np.asarray(flooded)==128
    fg=~outside
    # Remove background table rules: isolated long horizontal ink on either
    # side of the character is not part of its silhouette. Restrict to the
    # character envelope measured from body rows surrounding the table line.
    for rule_y in [table_y]+([1018] if name=='kit' else []):
        top,bottom=rule_y-10,rule_y+10
        upper=np.where(fg[top,:])[0]
        lower=np.where(fg[bottom,:])[0]
        for y in range(top+1,bottom):
            if len(upper) and len(lower):
                t=(y-top)/(bottom-top)
                left=round(upper.min()*(1-t)+lower.min()*t)
                right=round(upper.max()*(1-t)+lower.max()*t)
                fg[y,:left]=False
                fg[y,right+1:]=False
    # Remove the full-width bottom mat line / band, never touching the subject.
    # A foreground-only flood retains the character plus its enclosed areas.
    comp=Image.fromarray(fg.astype('uint8')*255).copy()
    ImageDraw.floodfill(comp,(724,500),128)
    fg=np.asarray(comp)==128
    mask=Image.fromarray(fg.astype('uint8')*255)
    # Boundary antialias uses original RGB pixels. No generated pixels and no
    # hue / texture alterations are introduced in the extracted character.
    alpha=np.asarray(mask).copy()
    result=Image.fromarray(np.dstack((rgb,alpha)),'RGBA')
    bbox=result.getbbox()
    if not bbox: raise RuntimeError(f'Empty extraction: {name}')
    canvas=Image.new('RGBA',(1448,1200),(0,0,0,0))
    offset=(round(724-(bbox[0]+bbox[2])/2),1000-arm_y)
    canvas.alpha_composite(result,offset)
    output=OUT/f'{name}.png'
    canvas.save(output,optimize=True)
    a=np.asarray(canvas.getchannel('A'))
    return {'name':name,'source':str(path.relative_to(ROOT)),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source_dimensions':list(source.size),'source_foreground_bounds':list(bbox),'source_resting_arm_y':arm_y,'background_seeds':seeds,'output':str(output.relative_to(ROOT)),'dimensions':list(canvas.size),'mode':canvas.mode,'resting_arm_y':1000,'paste_offset':list(offset),'foreground_bounds':list(canvas.getbbox()),'alpha_zero_pixels':int((a==0).sum()),'alpha_partial_pixels':int(((a>0)&(a<255)).sum()),'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    records=[extract(*entry) for entry in CAST]
    (DOC/'extraction-records.json').write_text(json.dumps(records,indent=2)+'\n')
    review=Image.new('RGB',(1448,1200),'#126866')
    for i,record in enumerate(records):
        cutout=Image.open(ROOT/record['output'])
        cutout.thumbnail((362,550),Image.Resampling.LANCZOS)
        x=(i%4)*362+(362-cutout.width)//2
        y=(i//4)*600
        review.paste(cutout,(x,y),cutout)
        ImageDraw.Draw(review).text(((i%4)*362+20,y+570),record['name'],fill='#FFF4DF')
    review.save(DOC/'extraction-review.png')
    print(json.dumps(records,indent=2))

if __name__=='__main__':main()
