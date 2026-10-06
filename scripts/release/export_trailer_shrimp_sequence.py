"""Use the complete summon -> attack -> ping capture as the opening."""
from pathlib import Path
import subprocess
import re
import math
import json

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'outputs/trailer_shrimp_sequence'
MASTER=ROOT/'outputs/trailer_hq_all/22_shrimp_full_combo'
PREVIOUS=ROOT/'outputs/trailer_varied_combat/TOP_CUT_varied_combat_1080p.mp4'

def run(args):
    subprocess.run([str(a) for a in args],check=True)

def main():
    OUT.mkdir(exist_ok=True)
    log=(MASTER/'capture.log').read_text()
    assert 'TRAILER_CLIP_CAPTURED 22_shrimp_full_combo' in log
    assert 'SCRIPT ERROR:' not in log
    marks={name:int(re.search('SHRIMP_'+name+r'_FRAME (\d+)',log)[1]) for name in ['SUMMON','ATTACK','PING','DONE']}
    first=marks['SUMMON']-3
    count=max(150, marks['DONE']+13-first)
    duration=count/30
    total=35+duration
    clip=OUT/'Firecracker_Shrimp_summon_attack_ping_1080p.mp4'
    if not clip.exists():
        run(['ffmpeg','-v','error','-n','-framerate',30,'-start_number',first,
             '-i',MASTER/'frames/frame_%06d.png','-frames:v',count,
             '-vf','scale=1920:1080:flags=lanczos,setsar=1','-an','-c:v','libx264',
             '-preset','fast','-crf',16,'-pix_fmt','yuv420p','-movflags','+faststart',clip])
    inputs=['-i',clip,'-i',PREVIOUS,'-i',ROOT/'assets/audio/combat.mp3',
            '-i',ROOT/'assets/audio/meal_summon_epic_spell_impact.mp3',
            '-i',ROOT/'assets/audio/combat_hit_thud.mp3',
            '-i',ROOT/'assets/audio/combat_hit_ground.mp3']
    filters=['[1:v]trim=start=5,setpts=PTS-STARTPTS[tail]',
             '[0:v][tail]concat=n=2:v=1:a=0[v]',
             f'[2:a]atrim=duration={duration},asetpts=PTS-STARTPTS,volume=0.30[m]']
    for i,name in enumerate(['SUMMON','ATTACK','PING']):
        visual_offset={'SUMMON':0,'ATTACK':30,'PING':45}[name]
        delay=round((marks[name]+visual_offset-first)/30*1000)
        filters += [f'[{i+3}:a]atrim=duration=1,asetpts=PTS-STARTPTS,volume=0.6,adelay={delay}:all=1[s{i}]']
    filters += [f'[m][s0][s1][s2]amix=inputs=4:duration=first:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000,atrim=duration={duration}[intro]',
                '[1:a]atrim=start=5,asetpts=PTS-STARTPTS[ta]',
                '[intro][ta]concat=n=2:v=0:a=1[a]']
    target=OUT/'TOP_CUT_full_shrimp_sequence_1080p.mp4'
    if not target.exists():
        run(['ffmpeg','-v','error','-n',*inputs,'-filter_complex',';'.join(filters),
             '-map','[v]','-map','[a]','-t',total,'-r',30,'-c:v','libx264','-preset','fast',
             '-crf',16,'-pix_fmt','yuv420p','-c:a','aac','-b:a','320k','-ar',48000,
             '-movflags','+faststart',target])
    run(['ffmpeg','-v','error','-i',target,'-f','null','-'])
    info=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-of','json',str(target)]))
    video=next(s for s in info['streams'] if s['codec_type']=='video')
    assert int(video['nb_frames'])==1050+count
    print({'markers':marks,'first':first,'opener_seconds':duration,'total_seconds':total,'caption_shift_seconds':duration-5})

if __name__=='__main__':
    main()
