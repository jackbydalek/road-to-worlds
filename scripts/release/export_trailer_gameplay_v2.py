"""Gameplay-first editorial draft; preserves previous exports and native masters."""
from pathlib import Path
import csv
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'outputs/trailer_gameplay_v2'
CLEAN_UPGRADE = '--clean-upgrade' in sys.argv
# name, source, in seconds, duration, on-screen text
SHOTS = [
    ('01_impact_hook', '17_firecracker_bench_hit', 5.8, 2, ''),
    ('02_attack', '01_combat_hook', 2.4, 3, ''),
    ('03_choose', '03_choose_competitor', 2.7, 3, 'PICK YOUR PLAYSTYLE'),
    ('04_combo', '07_battle_combo', 3, 4, 'MAKE YOUR CARDS WORK TOGETHER'),
    ('05_rewards', '08_reward_pack', 2.7, 3, 'FIND YOUR NEXT COMBO'),
    ('06_shop', '09_shop_deckbuild', 2, 3, 'BUILD BETWEEN ROUNDS'),
    ('07_hub', '18_tournament_hub', 3, 3, 'BACK TO THE TABLE'),
    ('08_counter', '14_hand_trap_response', 3.4, 3, ''),
    ('09_bounce', '16_sweet_jellyfish_bounce', 3, 2.5, ''),
    ('10_summon', '15_saladmander_summon', 4.8, 2, ''),
    ('11_payoff', '17_firecracker_bench_hit', 5.8, 2, ''),
    ('12_title', '12_logo_end_card', 1.1, 5, 'WISHLIST ON STEAM'),
]
if CLEAN_UPGRADE:
    OUT = ROOT / 'outputs/trailer_clean_upgrade'
    SHOTS.insert(6, ('06b_foil_upgrade', '10_upgrade_foil', 3.0, 4.5, ''))
    SHOTS = [(name, source, start, duration, '')
             for name, source, start, duration, caption in SHOTS]

def run(args):
    subprocess.run([str(x) for x in args], check=True)

def main():
    OUT.mkdir(exist_ok=True)
    clips = OUT / 'individual_clips'
    clips.mkdir(exist_ok=True)
    rows, timeline = [], 0
    for name, source, start, duration, caption in SHOTS:
        master = ROOT / 'outputs/trailer_hq_all' / source
        first = round(start * 30)
        assert (master / 'frames' / f'frame_{first+round(duration*30)-1:06d}.png').exists()
        target = clips / f'{name}.mp4'
        if not target.exists():
            vf = 'scale=1920:1080:flags=lanczos,setsar=1'
            if source == '10_upgrade_foil':
                vf += ',trim=end_frame=61,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=2.5'
            run(['ffmpeg', '-v', 'error', '-n', '-framerate', 30, '-start_number', first,
                 '-i', master / 'frames/frame_%06d.png', '-t', duration,
                 '-vf', vf, '-an',
                 '-c:v', 'libx264', '-preset', 'fast', '-crf', 16, '-pix_fmt', 'yuv420p',
                 '-movflags', '+faststart', target])
        rows.append(dict(file=target.name, timeline_in=timeline, duration=duration,
                         source=source, source_in=start, caption=caption))
        timeline += duration
        print(f'Ready: {name}', flush=True)
    with (OUT / 'EDIT_LIST.csv').open('w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    # A single continuous music bed, not the music baked into individual captures.
    # Separate game effects emphasize the visible action without doubling music.
    effects = [
        ('combat_hit_thud.mp3', .7, .9),
        ('combat_hit_thud.mp3', 3.3, .8),
        ('531087__ryusa__magic-spell-buff-bell-sparkle-reverb.wav', 9.5, .5),
        ('kenney_casino/cards-pack-open-2.ogg', 12.2, .8),
        ('kenney_casino/cards-pack-open-1.ogg', 15.3, .5),
        ('ability_activation_healing_magic.mp3', 22.2, .45),
        ('kenney_casino/cards-pack-open-2.ogg', 24.8, .6),
        ('meal_summon_epic_spell_impact.mp3', 26.8, .65),
        ('combat_hit_ground.mp3', 29.2, .8),
    ]
    if CLEAN_UPGRADE:
        effects = [(file, at + (4.5 if at >= 18 else 0), gain)
                   for file, at, gain in effects]
        effects.append(('531087__ryusa__magic-spell-buff-bell-sparkle-reverb.wav', 20.0, .5))
    args = []
    for row in rows:
        args += ['-i', clips / row['file']]
    n = len(rows)
    args += ['-i', ROOT / 'assets/audio/combat.mp3']
    filters = [''.join(f'[{i}:v]' for i in range(n)) + f'concat=n={n}:v=1:a=0[base]']
    filters += [f'[{n}:a]atrim=duration={timeline},asetpts=PTS-STARTPTS,volume=0.30,afade=t=in:d=0.15,afade=t=out:st={timeline-2}:d=2[music]']
    for i, (file, at, gain) in enumerate(effects):
        args += ['-i', ROOT / 'assets/audio' / file]
        filters += [f'[{n+1+i}:a]atrim=duration=2,asetpts=PTS-STARTPTS,volume={gain},adelay={round(at*1000)}:all=1[s{i}]']
    filters += ['[music]' + ''.join(f'[s{i}]' for i in range(len(effects))) +
                f'amix=inputs={len(effects)+1}:duration=first:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=9[audio]']
    # Code-rendered text layers: no repainting or fabricated gameplay.
    previous = 'base'
    next_input = n + 1 + len(effects)
    for i, row in enumerate(rows):
        if not row['caption']:
            continue
        layer = OUT / f'caption_{i:02d}.png'
        img = Image.new('RGBA', (1920, 1080))
        draw = ImageDraw.Draw(img)
        font = ImageFont.truetype(str(ROOT / 'assets/fonts/Oxanium-SemiBold.ttf'), 48)
        y = 940 if i == n-1 else 70
        box = draw.textbbox((0, 0), row['caption'], font=font)
        w = box[2] - box[0]
        x = (1920-w)//2
        draw.rectangle((x-24, y-12, x+w+24, y+66), fill=(18,22,28,235))
        draw.rectangle((x-24, y+65, x+w+24, y+69), fill=(38,199,237,255))
        draw.text((x,y), row['caption'], font=font, fill=(243,246,250,255))
        img.save(layer)
        args += ['-i', layer]
        end = row['timeline_in'] + row['duration']
        filters += [f'[{previous}][{next_input}:v]overlay=enable=\'between(t,{row["timeline_in"]},{end})\'[cap{i}]']
        previous = f'cap{i}'
        next_input += 1
    target = OUT / ('TOP_CUT_clean_with_upgrade_1080p.mp4' if CLEAN_UPGRADE
                    else 'TOP_CUT_gameplay_first_v2_1080p.mp4')
    if not target.exists():
        run(['ffmpeg', '-v', 'error', '-n', *args, '-filter_complex', ';'.join(filters),
             '-map', f'[{previous}]', '-map', '[audio]', '-t', timeline, '-r', 30,
             '-c:v', 'libx264', '-preset', 'fast', '-crf', 16, '-pix_fmt', 'yuv420p',
             '-c:a', 'aac', '-b:a', '320k', '-ar', 48000, '-movflags', '+faststart', target])
    run(['ffmpeg', '-v', 'error', '-i', target, '-f', 'null', '-'])
    print(f'Verified decode: {target}; {timeline}s', flush=True)

if __name__ == '__main__':
    main()
