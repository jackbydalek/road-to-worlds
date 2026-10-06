"""Replace the closing combat montage with three verified new interactions."""
from pathlib import Path
import subprocess
import json
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'outputs/trailer_varied_combat'
SOURCE = ROOT / 'outputs/trailer_impact_first/TOP_CUT_impact_first_1080p.mp4'

def run(args):
    subprocess.run([str(x) for x in args], check=True)

def main():
    OUT.mkdir(exist_ok=True)
    inputs, rows = [], []
    for clip, duration in [('19_healing_save', 3.5), ('20_polar_power_move', 3), ('21_sharkcake_draw', 3)]:
        master = ROOT / 'outputs/trailer_hq_all' / clip
        log = (master / 'capture.log').read_text()
        assert f'TRAILER_CLIP_CAPTURED {clip}' in log
        assert 'SCRIPT ERROR:' not in log and 'ERROR:' not in log
        first = int(re.search(r'VARIETY_ACTION_FRAME (\d+)', log)[1]) - 6
        resolved = int(re.search(r'VARIETY_RESOLVED_FRAME (\d+)', log)[1])
        count = round(duration * 30)
        if clip == '21_sharkcake_draw':
            # Skip the ingredient-picker pause, retain summon/draw and a result hold.
            first = max(first, resolved - count + 25)
        # Capture action onset through resolution, keeping real-time playback.
        assert resolved < first + count, (clip, first, resolved, count)
        target = OUT / f'{clip}_1080p.mp4'
        if not target.exists():
            run(['ffmpeg','-v','error','-n','-framerate',30,'-start_number',first,
                 '-i',master/'frames/frame_%06d.png','-frames:v',count,
                 '-vf','scale=1920:1080:flags=lanczos,setsar=1','-an',
                 '-c:v','libx264','-preset','fast','-crf',16,'-pix_fmt','yuv420p',target])
        inputs += ['-i', target]
        rows.append((clip, first, resolved, duration))
    inputs += ['-i', SOURCE, '-ss', 25.5, '-i', ROOT/'assets/audio/combat.mp3',
               '-i', ROOT/'assets/audio/ability_activation_healing_magic.mp3',
               '-i', ROOT/'assets/audio/531087__ryusa__magic-spell-buff-bell-sparkle-reverb.wav',
               '-i', ROOT/'assets/audio/meal_summon_epic_spell_impact.mp3']
    filters = [
        '[3:v]split=2[pre][post]',
        '[pre]trim=end=25.5,setpts=PTS-STARTPTS[p]',
        '[post]trim=start=35,setpts=PTS-STARTPTS[q]',
        '[p][0:v][1:v][2:v][q]concat=n=5:v=1:a=0[v]',
        '[4:a]atrim=duration=9.5,asetpts=PTS-STARTPTS,volume=0.30[m]',
        '[5:a]atrim=duration=1.5,asetpts=PTS-STARTPTS,volume=0.5,adelay=1800:all=1[h]',
        '[6:a]atrim=duration=1.5,asetpts=PTS-STARTPTS,volume=0.5,adelay=5000:all=1[b]',
        '[7:a]atrim=duration=1.5,asetpts=PTS-STARTPTS,volume=0.6,adelay=6500:all=1[s]',
        '[m][h][b][s]amix=inputs=4:duration=first:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000,atrim=duration=9.5[mid]',
        '[3:a]asplit=2[ap][aq]',
        '[ap]atrim=end=25.5,asetpts=PTS-STARTPTS[a0]',
        '[aq]atrim=start=35,asetpts=PTS-STARTPTS[a1]',
        '[a0][mid][a1]concat=n=3:v=0:a=1[a]',
    ]
    target = OUT/'TOP_CUT_varied_combat_1080p.mp4'
    if not target.exists():
        run(['ffmpeg','-v','error','-n',*inputs,'-filter_complex',';'.join(filters),
             '-map','[v]','-map','[a]','-t',40,'-r',30,'-c:v','libx264','-preset','fast',
             '-crf',16,'-pix_fmt','yuv420p','-c:a','aac','-b:a','320k','-ar',48000,
             '-movflags','+faststart',target])
    run(['ffmpeg','-v','error','-i',target,'-f','null','-'])
    probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-of','json',str(target)]))
    video=next(x for x in probe['streams'] if x['codec_type']=='video')
    assert (video['width'],video['height'],int(video['nb_frames']))==(1920,1080,1200)
    print(rows)
    print(f'Verified: {target}')

if __name__=='__main__':
    main()
