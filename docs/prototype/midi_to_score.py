#!/usr/bin/env python3
"""
midi_to_score.py
Convert a public-domain MIDI file into the app's Piece/Note JSON schema.

  python3 midi_to_score.py input.mid \
      --id moonlight_1 --title "月光 第1楽章" --composer "L. v. Beethoven" \
      --featured

Schema produced (matches the app):
  Piece { id, title, composer, beatsPerMeasure, defaultBpm, featured,
          isUserCreated:false, notes:[ Note ] }
  Note  { pitch:"C4"/"F#5", beat, duration, velocity }

Notes / conventions
  * Pitch uses sharps only. MIDI note 60 = "C4" (scientific pitch).
    If your synth/soundfont treats 60 as C3, pass --octave-offset -1.
  * `beat` is the absolute onset in quarter-note beats from the start.
    `duration` is the length in quarter-note beats.
  * All tracks/channels are merged into one note list and sorted by onset.
    Pass --channel N to keep only one MIDI channel (e.g. the right hand).
  * Get PD MIDI from sources where the *data* is free, e.g.
      - Mutopia Project (mutopiaproject.org)  -- explicitly PD / CC
      - IMSLP (imslp.org)                      -- check each file's license
"""
import argparse, json, sys
import mido

SHARP = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

def note_name(n, octave_offset=0):
    octave = n // 12 - 1 + octave_offset      # MIDI 60 -> C4
    return f"{SHARP[n % 12]}{octave}"

def convert(path, channel=None, octave_offset=0):
    mid = mido.MidiFile(path, clip=True)
    tpb = mid.ticks_per_beat
    bpm = 120.0
    numerator, denominator = 4, 4
    got_tempo = got_ts = False

    # merge tracks onto one absolute-tick timeline
    events = []
    for track in mid.tracks:
        t = 0
        for msg in track:
            t += msg.time
            events.append((t, msg))
    events.sort(key=lambda e: e[0])

    open_notes = {}   # (channel, note) -> (start_tick, velocity)
    notes = []
    for t, msg in events:
        if msg.type == "set_tempo" and not got_tempo:
            bpm = round(mido.tempo2bpm(msg.tempo)); got_tempo = True
        elif msg.type == "time_signature" and not got_ts:
            numerator, denominator = msg.numerator, msg.denominator; got_ts = True
        elif msg.type == "note_on" and msg.velocity > 0:
            if channel is not None and msg.channel != channel:
                continue
            open_notes[(msg.channel, msg.note)] = (t, msg.velocity)
        elif msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
            if channel is not None and msg.channel != channel:
                continue
            key = (msg.channel, msg.note)
            if key in open_notes:
                start, vel = open_notes.pop(key)
                beat = start / tpb
                dur = max((t - start) / tpb, 1e-3)
                notes.append({
                    "pitch": note_name(msg.note, octave_offset),
                    "beat": round(beat, 4),
                    "duration": round(dur, 4),
                    "velocity": vel,
                })
    notes.sort(key=lambda n: (n["beat"], n["pitch"]))
    bpm_meas = numerator * 4 / denominator
    bpm_meas = int(bpm_meas) if bpm_meas == int(bpm_meas) else round(bpm_meas, 4)
    return notes, int(bpm), bpm_meas

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("midi")
    ap.add_argument("--id", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--composer", default="")
    ap.add_argument("--featured", action="store_true")
    ap.add_argument("--channel", type=int, default=None)
    ap.add_argument("--octave-offset", type=int, default=0)
    ap.add_argument("--bpm", type=int, default=None, help="override detected tempo")
    ap.add_argument("-o", "--out", default=None)
    a = ap.parse_args()

    notes, bpm, bpmeas = convert(a.midi, a.channel, a.octave_offset)
    piece = {
        "id": a.id, "title": a.title, "composer": a.composer,
        "beatsPerMeasure": bpmeas, "defaultBpm": a.bpm or bpm,
        "featured": a.featured, "isUserCreated": False, "notes": notes,
    }
    text = json.dumps(piece, ensure_ascii=False, indent=2)
    if a.out:
        open(a.out, "w", encoding="utf-8").write(text)
        print(f"wrote {a.out}: {len(notes)} notes, bpm={piece['defaultBpm']}, "
              f"beatsPerMeasure={bpmeas}", file=sys.stderr)
    else:
        print(text)

if __name__ == "__main__":
    main()
