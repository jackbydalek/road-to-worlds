"""Replace only the opening five seconds; retain the clean upgrade trailer."""
from pathlib import Path
import subprocess
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'outputs/trailer_punchier_open'
V2 = '--impact-first' in sys.argv
if V2:
    OUT = ROOT / 'outputs/trailer_impact_first'
SOURCE = ROOT / 'outputs/trailer_clean_upgrade/TOP_CUT_clean_with_upgrade_1080p.mp4'

def run(args):
    subprocess.run([str(x) for x in args], check=True)

def main():
    OUT.mkdir(exist_ok=True)
    shots = [
        ('attack', '01_combat_hook', 72, 54, '3072:1728:384:200'),
        ('impact', '17_firecracker_bench_hit', 180, 48, '2688:1512:500:180'),
        ('bounce', '16_sweet_jellyfish_bounce', 100, 48, '3072:1728:384:200'),
    ]
    if V2:
        shots = [
            ('01_burst', '17_firecracker_bench_hit', 195, 30, '2304:1296:850:170'),
            ('02_attack', '01_combat_hook', 78, 45, '2688:1512:700:280'),
            ('03_power_up', '07_battle_combo', 120, 45, '2304:1296:850:640'),
            ('04_bounce', '16_sweet_jellyfish_bounce', 110, 30, '2688:1512:580:230'),
        ]
    inputs = []
    for name, clip, first, frames, crop in shots:
        target = OUT / f'{name}.mp4'
        if not target.exists():
            run(['ffmpeg', '-v', 'error', '-n', '-framerate', 30, '-start_number', first,
                 '-i', ROOT / 'outputs/trailer_hq_all' / clip / 'frames/frame_%06d.png',
                 '-frames:v', frames, '-vf', f'crop={crop},scale=1920:1080:flags=lanczos,setsar=1',
                 '-an', '-c:v', 'libx264', '-crf', 16, '-preset', 'fast', '-pix_fmt', 'yuv420p', target])
        inputs += ['-i', target]
    inputs += ['-i', SOURCE, '-i', ROOT / 'assets/audio/combat.mp3',
               '-i', ROOT / 'assets/audio/combat_hit_thud.mp3',
               '-i', ROOT / 'assets/audio/combat_hit_ground.mp3',
               '-i', ROOT / 'assets/audio/kenney_casino/cards-pack-open-2.ogg']
    filters = [
        '[0:v][1:v][2:v]concat=n=3:v=1:a=0[open]',
        '[3:v]trim=start=5,setpts=PTS-STARTPTS[rest]',
        '[open][rest]concat=n=2:v=1:a=0[v]',
        '[4:a]atrim=duration=5,asetpts=PTS-STARTPTS,volume=0.30[m]',
        '[5:a]atrim=duration=0.8,asetpts=PTS-STARTPTS,volume=0.9,adelay=1267:all=1[hit]',
        '[6:a]atrim=duration=1.0,asetpts=PTS-STARTPTS,volume=0.8,adelay=2300:all=1[burst]',
        '[7:a]atrim=duration=0.6,asetpts=PTS-STARTPTS,volume=0.6,adelay=4067:all=1[card]',
        '[m][hit][burst][card]amix=inputs=4:duration=first:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000,atrim=duration=5[oa]',
        '[3:a]atrim=start=5,asetpts=PTS-STARTPTS[ra]',
        '[oa][ra]concat=n=2:v=0:a=1[a]',
    ]
    target = OUT / 'TOP_CUT_punchier_open_1080p.mp4'
    if V2:
        inputs += ['-i', ROOT / 'assets/audio/531087__ryusa__magic-spell-buff-bell-sparkle-reverb.wav']
        filters = [
            '[0:v][1:v][2:v][3:v]concat=n=4:v=1:a=0[open]',
            '[4:v]trim=start=5,setpts=PTS-STARTPTS[rest]',
            '[open][rest]concat=n=2:v=1:a=0[v]',
            '[5:a]atrim=duration=5,asetpts=PTS-STARTPTS,volume=0.30[m]',
            '[6:a]atrim=duration=0.8,asetpts=PTS-STARTPTS,volume=0.9,adelay=2067:all=1[hit]',
            '[7:a]atrim=duration=1.0,asetpts=PTS-STARTPTS,volume=0.9[burst]',
            '[8:a]atrim=duration=0.6,asetpts=PTS-STARTPTS,volume=0.7,adelay=4333:all=1[card]',
            '[9:a]atrim=duration=1.0,asetpts=PTS-STARTPTS,volume=0.65,adelay=3000:all=1[buff]',
            '[m][hit][burst][card][buff]amix=inputs=5:duration=first:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000,atrim=duration=5[oa]',
            '[4:a]atrim=start=5,asetpts=PTS-STARTPTS[ra]',
            '[oa][ra]concat=n=2:v=0:a=1[a]',
        ]
        target = OUT / 'TOP_CUT_impact_first_1080p.mp4'
    if not target.exists():
        run(['ffmpeg', '-v', 'error', '-n', *inputs, '-filter_complex', ';'.join(filters),
             '-map', '[v]', '-map', '[a]', '-t', 40, '-r', 30, '-c:v', 'libx264',
             '-crf', 16, '-preset', 'fast', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
             '-b:a', '320k', '-ar', 48000, '-movflags', '+faststart', target])
    run(['ffmpeg', '-v', 'error', '-i', target, '-f', 'null', '-'])
    info = json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-of','json',str(target)]))
    video = next(s for s in info['streams'] if s['codec_type'] == 'video')
    assert (video['width'],video['height'],int(video['nb_frames'])) == (1920,1080,1200)
    print(f'Verified 40-second export: {target}')

if __name__ == '__main__':
    main()
