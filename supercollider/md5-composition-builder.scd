(
~generateViolinPhrase = {
  arg chordSetIndex=0, phraseLength=4, tempo=1.0;
  var chords, midiNotes, durations, currentTime = 0;
  var previousNote, currentChord, chordMidi;
  var phraseNotes, phraseDurs;
  "MAKE PHRASE".postln;
  // 1. Select chord progression
  chords = ~notes[chordSetIndex.clip(0, ~notes.size-1)];
  // chords.postln;
  // if (phraseLength.notNil) { chords = chords.keep(phraseLength) };

  midiNotes = [];
  durations = [];

  // 2. Initialize with random starting point if no previous note
  previousNote = 60 + [-5, 0, 7].choose; // Around middle C

  // 3. Process each chord
  chords.do {
    arg chord, i;
    var chordNotes, structure, chordEvents;
    var chordDuration = 2.0 * tempo; // Base duration per chord
    // i.postln;
    // chord.postln;
    // Convert chord names to MIDI
    chordMidi = chord.collect {
      arg noteName;
      ~convert.(noteName) + 60;
    };

    // Expand chord to multiple octaves for arpeggio options
    chordNotes = [];
    [1, 2].do {
      arg octave; // G3 to G6 range
      chordNotes = chordNotes ++ (chordMidi + (octave * 12));
    };
    chordNotes = chordNotes.asSet.asArray;
    // "CHORD NOTES".postln;
    // chordNotes.postln;
    // chordNotes.do({arg note,i; note.midiname.postln});
    // Decide structure: arpeggio (40%) or melodic (60%)
    structure = if (0.4.coin) { \arpeggio } { \melodic };
    // structure = \melodic;

    // Generate events for this chord
    chordEvents = ~generate_chord_events.(
      chordNotes: chordNotes,
      previousNote: previousNote,
      structure: structure,
      chordDuration: chordDuration,
      isLastChord: (i == (chords.size-1))
    );
    // chordEvents.postln;
    // Extract notes and durs
    phraseNotes = chordEvents[0];
    phraseDurs = chordEvents[1];

    // Append to main arrays
    midiNotes = midiNotes ++ phraseNotes;
    durations = durations ++ phraseDurs;

    // Update for next chord
    previousNote = phraseNotes.last;
    currentTime = currentTime + phraseDurs.sum;
  };

  // 4. Add final rest
  durations = durations ++ [2.0 * tempo]; // Final rest
  // [midiNotes, durations].postln;
  [midiNotes, durations];
};


// Core: Generate events for one chord

~generate_chord_events = {
  arg chordNotes, previousNote,
  structure, chordDuration, isLastChord=false;
  var notes = [], durs = [];
  var startNote, targetNote;
  var arpNotes, arpDurs;
  var melNotes, melDurs;
  var totalDur;
  var phrase = [1, 2, 3].choose;
  // "generateChordEvents".postln;
  // 1. Find starting note (voice leading)
  startNote = ~findClosestNote.(previousNote, chordNotes);

  // startNote.postln;
  // "case".postln;
  // structure.postln;
  case
  { structure == \arpeggio } {
    // ARPEGGIO PATTERN (40% case)
    // Quick arpeggio + long resolution

    // >>>> md5 material
    var numArpNotes = rrand(4, 6);
    var resolutionDur;
    var arp_note_dur = 0.5 * chordDuration / 2;
    // "arpeggio".postln;
    // arp_note_dur.postln;

    arpNotes = Array.new(numArpNotes);
    arpDurs = Array.new(numArpNotes);

    // First note is startNote
    arpNotes.add(startNote);
    arpDurs.add(arp_note_dur); // Very short

    // Generate remaining arpeggio notes
    (numArpNotes-1).do {
      arg j;
      var nextNote;
      // Mostly chord tones, sometimes passing tones
      if (0.8.coin) {
        nextNote = chordNotes[j%chordNotes.size];
      } {
        nextNote = startNote + [-2, -1, 1, 2].choose;
      };

      nextNote = nextNote.clip(60, 100);

      arpNotes.add(nextNote);
      arpDurs.add(arp_note_dur);
    };
    // Long resolution note
    targetNote = ~findChordTone.(arpNotes.last, chordNotes, \stable);
    // "target note >>>>>>>>".postln;
    // targetNote.postln;
    // Make it longer if it's the last chord
    resolutionDur = if (isLastChord) {
      0.7 * chordDuration
    } {
      0.5 * chordDuration
    };

    notes = arpNotes.lace(numArpNotes * 2) ++ [targetNote];
    durs = arpDurs.lace(numArpNotes * 2) ++ [resolutionDur] ++ [~mRest.(2)];
  }
  { structure == \melodic } {
    // MELODIC PHRASE (60% case)
    // Fewer notes, more expressive

    "which phrase".postln;
    phrase.postln;
    case
    { phrase == 1} {
      // OPTION 1: Single expressive note (30% of melodic cases)
      "option1".postln;
      notes = [startNote];
      // >>>> md5 material
      durs = [chordDuration * 4];

      // Add a grace note before sometimes
      if (0.4.coin) {
        notes = [startNote - [1,2].choose] ++ notes;
        durs = [0.25 * chordDuration] ++ durs;
      };
      durs = durs ++ [~mRest.(2)];
    }
    { phrase == 2} {
      // OPTION 2: Small contour (2-3 notes) - most common


      // >>>> md5 material
      var numNotes = [2, 3, 4].choose;

      // >>>> md5 material
      var contour = [\arch, \descend, \ascend].choose;
      "option2".postln;

      notes = [startNote];
      durs = [];

      (numNotes-1).do {
        arg j;
        var nextNote, interval;

        case
        { contour == \arch } {
          // Up then down
          if (j == 0) {
            // >>>> md5 material
            interval = [3, 4, 5, 7].choose; // Up 3rd, 4th, 5th
          } {
            interval = [-2, -3, -4].choose; // Down
          };
        }
        { contour == \descend } {
          // >>>> md5 material
          interval = [-2, -3, -1].choose;
        }
        { contour == \ascend } {
          // >>>> md5 material
          interval = [2, 3, 4].choose;
        };

        nextNote = (notes.last + interval).clip(60, 100);
        // Ensure it's a chord tone on strong beats

        // >>>> md5 material
        if (j == 0 and: {0.7.coin}) {
          nextNote = ~findClosestNote.(nextNote, chordNotes);
        };
        notes = notes ++ [nextNote];
        durs = durs ++ [~mRest.(2)];
      };

      // Expressive rhythm
      durs = ~generate_rythm.(numNotes, chordDuration);
    }
    {phrase==3}{
      // OPTION 3: Motif-based (remaining 30%)
      var motif = ~applyMotif.(startNote, chordNotes);
      "option3".postln;
      notes = motif[0];
      durs = motif[1].normalizeSum * (chordDuration * 4);
      durs = durs ++ [~mRest.(2)];
    };
  };

  // Ensure we don't exceed chord duration
  /*totalDur = durs.sum;
  if (totalDur > chordDuration) {
  durs = durs.normalizeSum * chordDuration;
  };*/
  [notes, durs].postln;
  [notes, durs];
};


// Helper: Find closest note for voice leading

~findClosestNote = {
  arg sourceNote, candidates;
  var distances = candidates.collect { arg n; (n - sourceNote).abs };
  var minIndex = distances.minIndex;
  // "findClosestNote".postln;
  candidates[minIndex];
};


// Helper: Find stable chord tone (root/5th) or any chord tone

~findChordTone = {
  arg sourceNote, chordNotes, type=\any;
  var sorted = chordNotes.sort;
  var rootsAndFifths, result = ~findClosestNote.(sourceNote, chordNotes);
  // "find chord".postln;
  if (type == \stable) {
    // Extract root and fifth from first octave
    var baseChord = chordNotes.select{ arg n; n.inclusivelyBetween(72, 84) };
    // chordNotes.postln;
    // baseChord.postln;
    if (baseChord.size >= 2) {
      // ""
      rootsAndFifths = [baseChord[0], baseChord[2]]; // Root and 5th
      // Expand to other octaves
      rootsAndFifths = rootsAndFifths ++ (rootsAndFifths + 12) ++ (rootsAndFifths + 24);
      rootsAndFifths = rootsAndFifths.select { |n| chordNotes.includes(n) };
      // "ROOTS AND FIFTHS".postln;
      // rootsAndFifths.postln;
      if (rootsAndFifths.size > 0) {
        result = ~findClosestNote.(sourceNote, rootsAndFifths);
      };
    };
  };
  // "fallback".postln;
  // Fallback: any chord tone
  result;
};


// Helper: Generate expressive rhythm

~generate_rythm = {
  arg numNotes, totalDur;
  var ratios;

  case
  { numNotes == 2 } {
    ratios = if (0.5.coin) { [0.7, 0.3] * 4 } { [0.3, 0.7] * 4 };
  }
  { numNotes == 3 } {
    ratios = switch(rrand(0, 2),
      0, [0.4, 0.2, 0.4] * 4,  // Long-short-long
      1, [0.6, 0.3, 0.1] * 4,  // Decaying
      2, [0.2, 0.3, 0.5] * 4   // Crescendo
    );
  }
  { numNotes == 4 } {
    ratios = [0.3, 0.2, 0.1, 0.4] * 4; // Arch shape
  };

  ratios * totalDur;
};


// Helper: Apply a motif

~applyMotif = {
  arg startNote, chordNotes;
  // Simple motif: up 3rd, down step
  var motifNotes = [startNote, startNote + 4, startNote + 2];
  var motifDurs = [0.4, 0.2, 0.4] * 4;

  // Adjust to nearest chord tones
  motifNotes = motifNotes.collect { arg n; ~findClosestNote.(n, chordNotes) };

  [motifNotes, motifDurs];
};


h = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 128, tempo: 1.0);
// "RESULT".postln;
// h.postln;
)
(

~test_pat = {
  arg channel, name=nil, patN, patD;
  var pat_name = "string"++channel++name.asString;
  var bus = ~outs[channel];
  pat_name = pat_name.asSymbol;
  pat_name.postln;
  Pdef(pat_name).clear;
  Pdef(pat_name, Pbind(
    \instrument,\saw,\group, ~synths,
    \midi_note, patN,
    \dur, patD,
    \legato, 0.95,

    \a, Pfunc({
      arg event;
      var r=1.5;
      // event.dur.postln;
      if(event.dur < 1){r =  (event.dur / 2) + (event.dur / 4).rand };
      // r.postln;
      r
    }),
    \r, Pfunc({
      arg event;
      var r=1.25;
      // event.dur.postln;
      if(event.dur < 1){r =  (event.dur / 2) + (event.dur / 4).rand };
      // r.postln;
      r
    }),
    // \amp, patV, // velocity
    \out, bus,
  ));
  Pdef(pat_name).quant_(1);
  Pdef(pat_name).fadeTime = 1.0;
};
)
// Usage example
(
~playPhrase = {
  var result = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 16, tempo: 2.0);
  var midiNotes = result[0];
  var durations = result[1];
  "hello".postln;
  "Generated phrase:".postln;
  "MIDI Notes: ".post; midiNotes.postln;
  "Durations: ".post; durations.postln;

  ~pat = ~test_pat.(1, "test1", ~mpseq.(midiNotes), ~mpseq.(durations));
};
)

// Test it
~playPhrase.();

~pat.play()
~pat.stop()
Pdef.removeAll;

(
var a=1, d=1, s=1,r=1;
Env.adsr(
        a + 0.025.rand2,
        d + 0.01.rand2,
        s + 0.01.rand2,
        r + 0.025.rand2,
        curve:[2, -4, -2]).plot
)