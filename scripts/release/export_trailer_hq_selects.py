"""Build frame-exact replacements directly from lossless HQ captures."""
from pathlib import Path
import csv
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
MASTERS = ROOT / 'outputs/trailer_hq_all'
OUT = ROOT / 'outputs/trailer_hq_replacements_40s'
# Source in-points are in the new untrimmed recordings, not the old review files.
SHOTS = [
    ('01_opening_hit', '01_combat_hook', 1.8, 3),
    ('02_local_hub', '18_tournament_hub', 3.0, 3),
    ('03_starter_choice', '03_choose_competitor', 2.7, 3),
    ('04_ability_combo', '07_battle_combo', 2.5, 6),
    ('05_reward', '08_reward_pack', 2.7, 3),
    ('06_shop', '09_shop_deckbuild', 2.0, 3),
    ('07_hand_trap', '14_hand_trap_response', 1.8, 5),
    ('08_saladmander_summon', '15_saladmander_summon', 3.6, 3),
    ('09_jellyfish_bounce', '16_sweet_jellyfish_bounce', 3.0, 3),
    ('10_firecracker_payoff', '17_firecracker_bench_hit', 4.8, 3),
    ('11_title', '12_logo_end_card', 1.1, 5),
]

def run(args):
    subprocess.run([str(a) for a in args], check=True)

def probe(path):
    return json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(path)]))

def main():
    OUT.mkdir(exist_ok=True)
    rows = []
    timeline = 0
    for name, clip, start, seconds in SHOTS:
        source = (ROOT / 'outputs/trailer_hq_combat_sample') if clip == '01_combat_hook' else MASTERS / clip
        if not (source / f'{clip}_4k.mp4').exists():
            if '--partial' in sys.argv:
                break
            raise FileNotFoundError(f'Capture not complete: {clip}')
        first = round(start * 30)
        count = seconds * 30
        assert (source / 'frames' / f'frame_{first + count - 1:06d}.png').exists(), clip
        for resolution, size in [('1080p', '1920:1080'), ('4k', '3840:2160')]:
            folder = OUT / resolution
            folder.mkdir(exist_ok=True)
            target = folder / f'{name}.mp4'
            if target.exists():
                video = next(s for s in probe(target)['streams'] if s['codec_type'] == 'video')
                assert int(video['nb_frames']) == count, target
                continue
            run(['ffmpeg', '-v', 'error', '-n', '-framerate', '30', '-start_number', first,
                 '-i', source / 'frames/frame_%06d.png', '-ss', start,
                 '-i', source / 'audio_reference.avi', '-t', seconds,
                 '-map', '0:v:0', '-map', '1:a:0', '-vf', f'scale={size}:flags=lanczos,setsar=1',
                 '-c:v', 'libx264', '-preset', 'slow', '-crf', '14', '-pix_fmt', 'yuv420p',
                 '-c:a', 'aac', '-b:a', '320k', '-ar', '48000', '-ac', '2',
                 '-movflags', '+faststart', target])
            video = next(s for s in probe(target)['streams'] if s['codec_type'] == 'video')
            assert int(video['nb_frames']) == count, target
            assert (video['width'], video['height']) == tuple(map(int, size.split(':'))), target
            run(['ffmpeg', '-v', 'error', '-i', target, '-f', 'null', '-'])
        rows.append(dict(file=f'{name}.mp4', timeline_in=timeline, timeline_out=timeline+seconds,
                         master=str(source), source_in=start, source_out=start+seconds))
        timeline += seconds
        print(f'Verified {name}: {seconds}s, 4K and 1080p', flush=True)
    if len(rows) != len(SHOTS):
        print(f'{len(rows)} replacement clips ready; remaining captures pending.', flush=True)
        return
    with (OUT / 'EDIT_LIST.csv').open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    inputs = []
    filters = []
    for i, row in enumerate(rows):
        inputs += ['-i', OUT / '1080p' / row['file']]
        duration = row['timeline_out'] - row['timeline_in']
        filters += [f'[{i}:v]setpts=PTS-STARTPTS[v{i}]',
                    f'[{i}:a]atrim=duration={duration},asetpts=PTS-STARTPTS[a{i}]']
    filters += [''.join(f'[v{i}][a{i}]' for i in range(len(rows))) +
                f'concat=n={len(rows)}:v=1:a=1[v][a]']
    run(['ffmpeg', '-v', 'error', '-n', *inputs, '-filter_complex', ';'.join(filters),
         '-map', '[v]', '-map', '[a]', '-c:v', 'libx264', '-preset', 'fast', '-crf', '14',
         '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '320k', '-t', '40',
         '-movflags', '+faststart', OUT / 'TOP_CUT_HQ_40s_preview.mp4'])
    preview_video = next(s for s in probe(OUT / 'TOP_CUT_HQ_40s_preview.mp4')['streams']
                         if s['codec_type'] == 'video')
    assert int(preview_video['nb_frames']) == 1200
    run(['ffmpeg', '-v', 'error', '-i', OUT / 'TOP_CUT_HQ_40s_preview.mp4', '-f', 'null', '-'])
    (OUT / 'README.md').write_text(
        '# Sharp replacement clips — 40 seconds\n\n'
        'Import the 11 numbered MP4s from `1080p` in order. Their durations match '
        'the previous 40-second edit; `4k` contains the same cuts at native 4K. '
        'Both versions are encoded directly from lossless frames, not enlarged review videos.\n\n'
        'The preview has game audio but no music or captions. The WeVideo project is unchanged. '
        'The new shop shows the current illustrated hub counter. '
        'Some source card art is still marked ART PENDING; higher resolution does not replace unfinished art.\n\n'
        'Full source recordings and retained lossless frames are in `../trailer_hq_all`, '
        'with the opening source in `../trailer_hq_combat_sample`. '
        'EDIT_LIST.csv records exact source in/out points.\n')
    assert timeline == 40

if __name__ == '__main__':
    main()
