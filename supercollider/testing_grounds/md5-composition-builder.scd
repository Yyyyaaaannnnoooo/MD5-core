~test_md5 = [   2, 11,  9,  9,  5,  7,  7, 10, 15,  15, 10, 10, 14, 12, 15,  9,  8, 14,   3,  1,  9,  4,  9, 13, 12, 11, 12,  10, 10, 14, 10,  8]
~test_md5.size
~set = ~test_md5.reshape(4,8)

(

// to do reshape md5 in 4 parts and make 4 phrases

~test_md5 = ~test_md5.rotate(32.rand);

~generateViolinPhrase = {
  arg chordSetIndex=0, phraseLength=4, tempo=1.0, md5 = nil;
  var chords, midiNotes, durations, currentTime = 0;
  var previousNote, currentChord, chordMidi;
  var phraseNotes, phraseDurs, chord_notes, start;
  var melody = md5[0].linlin(0, 15, 0, 6).floor.asInteger;
  var choose_struct;
  "MAKE PHRASE".postln;
  // 1. Select chord progression
  chords = ~notes[melody];
  midiNotes = [];
  durations = [];

  // 2. get starting random note form chord progression
  chord_notes = chords.choose;
  start = chord_notes.choose;
  previousNote = ~convert.(start) + 60;

  // 3. Process each chord
  chords.size.postln;
  chords.do {
    arg chord, i;
    var chordNotes, structure, chordEvents;
    var chordDuration = 2.0 * tempo; // Base duration per chord
    "INDEX".postln;
    i.postln;
    "<<<<>>>>>>".postln;
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
    // >>>> MD5 DECISION
    choose_struct = md5[(1+i)%md5.size] > 9;
    structure = if (choose_struct) { \arpeggio} { \melodic};
    // structure = \arpeggio;
    // Generate events for this chord
    chordEvents = ~generate_chord_events.(
      chordNotes: chordNotes,
      previousNote: previousNote,
      structure: structure,
      chordDuration: chordDuration,
      isLastChord: (i == (chords.size-1)),
      md5:md5,
      index:i
    );
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

~arpeggio = {
  arg chordNotes, isLastChord=false,
  chordDuration, startNote,
  a_r=2, n_r=6, n_Arp_n=4;
  // >>>> md5 material
  var numArpNotes = n_Arp_n;
  var resolutionDur;
  var arp_note_dur = 0.5 * chordDuration;
  var arpNotes, arpDurs;
  var notes = [], durs = [];
  var targetNote,
  arp_repeats=a_r, note_repeats=n_r; // <<< md5 material
  var octave=0;
  arpNotes = Array.new(numArpNotes);
  arpDurs = Array.new(numArpNotes);
  arp_note_dur = if(note_repeats > 2){0.25 * chordDuration}{arp_note_dur};
  octave = if(note_repeats > 2){24}{0};
  // octave.postln;
  // First note is startNote
  arpNotes.add(startNote);
  arpDurs.add(arp_note_dur); // Very short

  // Generate remaining arpeggio notes
  (numArpNotes-1).do {
    arg j;
    var nextNote;
    // Mostly chord tones, sometimes passing tones
    if (0.8.coin) {
      // nextNote = chordNotes[j%(chordNotes.size-1)];
      nextNote = chordNotes.choose;
    } {
      nextNote = (startNote + [-2, -1, 1, 2].choose);
    };
    nextNote = nextNote.clip(60, 100);
    arpNotes.add(nextNote);
    arpDurs.add(arp_note_dur + 0.25.rand2) ;
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
  // notes = notes - octave;
  notes = arpNotes.lace(numArpNotes * arp_repeats).dupEach(note_repeats) ++ [targetNote];
  durs = arpDurs.lace(numArpNotes * arp_repeats).dupEach(note_repeats) ++ [resolutionDur] ++ [~mRest.(4 + 1.0.rand)];
  [notes, durs]
};
// Core: Generate events for one chord

~generate_chord_events = {
  arg chordNotes, previousNote,
  structure, chordDuration, isLastChord=false, md5=nil, index=0;
  var notes = [], durs = [];
  var startNote, targetNote; // tragetNote DEPRECATED!
  var melNotes, melDurs;
  var totalDur;
  var phrase = md5[(2+index)%md5.size].linlin(0, 15, 1, 3).floor.asInteger; // might return bug!!!!
  var arp_repats = md5[(3+index)%md5.size].linlin(0, 15, 1, 4).floor.asInteger;
  var note_repats = md5[(4+index)%md5.size].linlin(0, 15, 1, 4).floor.asInteger;
  var number_arp_notes = md5[(5+index)%md5.size].linlin(0, 15, 4, 8).floor.asInteger;
  var phrase_1_dur = md5[(6+index)%md5.size].linlin(0, 15, 4, 8).floor.asInteger;
  var phrase_2_num_notes = md5[(7+index)%md5.size].linlin(0, 15, 2, 4).floor.asInteger;
  var contours = [\arch, \descend, \ascend];
  var contours_index = md5[(7+index)%md5.size].linlin(0, 15, 0, 2).floor.asInteger;
  var phrase_2_contour = contours[contours_index];
  var arp_phrase;
  // phrase.postln;
  // "generateChordEvents".postln;
  // 1. Find starting note (voice leading)
  startNote = ~findClosestNote.(previousNote, chordNotes);
  // startNote = previousNote;
  // "start note".postln;
  // startNote.postln;
  // phrase=3;
  // structure.postln;
  case
  { structure == \arpeggio } {
    // ARPEGGIO PATTERN (40% case)
    // Quick arpeggio + long resolution
    // a_r=2, n_r=6, n_Arp_n=4;
    arp_phrase = ~arpeggio.(
      chordNotes,
      isLastChord,
      chordDuration,
      startNote,
      arp_repats,
      note_repats,
      number_arp_notes
    );
    notes = arp_phrase[0];
    durs = arp_phrase[1];
  }
  { structure == \melodic } {
    // MELODIC PHRASE (60% case)
    // Fewer notes, more expressive

    // "which phrase".postln;
    // phrase.postln;
    case
    { phrase == 1} {
      // OPTION 1: Single expressive note (30% of melodic cases)
      // "option1".postln;
      notes = [startNote];
      // >>>> md5 material
      // "phrase 1 duration: ".post;
      // phrase_1_dur.postln;
      durs = [chordDuration * phrase_1_dur];

      // Add a grace note before sometimes
      if (0.4.coin) {
        notes = [startNote - [1,2].choose] ++ notes;
        durs = [0.25 * chordDuration] ++ durs;
      };
      durs = durs ++ [~mRest.(2 + 1.0.rand)];
    }
    { phrase == 2} {
      // OPTION 2: Small contour (2-3 notes) - most common
      // >>>> md5 material
      var numNotes = phrase_2_num_notes;
      // >>>> md5 material
      var contour = phrase_2_contour;//[\arch, \descend, \ascend].choose;
      // "option2".postln;
      // "phrse 2 contour: ".post;
      // contour.postln;
      // "notes: ".post;
      // numNotes.postln;
      notes = [startNote];
      durs = [];

      (numNotes-1).do {
        arg j;
        var nextNote, interval;

        case
        { contour == \arch } {
          // Up then down
          if (j == 0) {
            interval = [3, 4, 5, 7].choose; // Up 3rd, 4th, 5th
          } {
            interval = [-2, -3, -4].choose; // Down
          };
        }
        { contour == \descend } {
          interval = [-2, -3, -1].choose;
        }
        { contour == \ascend } {
          interval = [2, 3, 4].choose;
        };

        nextNote = (notes.last + interval).clip(60, 100);
        // Ensure it's a chord tone on strong beats

        //
        if (j == 0 and: {0.7.coin}) {
          nextNote = ~findClosestNote.(nextNote, chordNotes);
        };
        notes = notes ++ [nextNote];
        // durs = durs ++ [~mRest.(2 + 1.0.rand)];
      };

      // Expressive rhythm
      durs = ~generate_rythm.(numNotes, chordDuration) ++ [~mRest.(2.0.rand)];
    }
    {phrase==3}{
      // OPTION 3: Motif-based (remaining 30%)
      var motif = ~applyMotif.(startNote, chordNotes);
      // "option3".postln;
      notes = motif[0];
      durs = motif[1].normalizeSum * (chordDuration);
      durs = durs ++ [~mRest.(2 + 1.0.rand)];
    };
  };

  // Ensure we don't exceed chord duration
  /*totalDur = durs.sum;
  if (totalDur > chordDuration) {
  durs = durs.normalizeSum * chordDuration;
  };*/
  // [notes, durs].postln;
  [notes, durs];
};


// Helper: Find closest note for voice leading

~findClosestNote = {
  arg sourceNote, candidates;
  var distances = candidates.collect { arg n; (n - sourceNote).abs };
  var minIndex = distances.minIndex;
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
  // "generate rythm".postln;
  // numNotes.postln;
  case
  { numNotes == 2 } {
    ratios = if (0.5.coin) { [0.7, 0.3] * 4 } { [0.3, 0.7] };
  }
  { numNotes == 3 } {
    ratios = switch(rrand(0, 2),
      0, [0.4, 0.2, 0.4],  // Long-short-long
      1, [0.6, 0.3, 0.1],  // Decaying
      2, [0.2, 0.3, 0.5]  // Crescendo
    );
  }
  { numNotes == 4 } {
    ratios = [0.3, 0.2, 0.1, 0.4]; // Arch shape
  };

  ratios * totalDur;
};


// Helper: Apply a motif

~applyMotif = {
  arg startNote, chordNotes;
  // Simple motif: up 3rd, down step
  var motifNotes = [startNote, startNote + 4, startNote + 2];
  var motifDurs = [0.4, 0.2, 0.4];

  // Adjust to nearest chord tones
  motifNotes = motifNotes.collect { arg n; ~findClosestNote.(n, chordNotes) };

  [motifNotes, motifDurs];
};


h = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 128, tempo: 1.0, md5: ~test_md5);

)
(

~test_pat = {
  arg channel, name=nil, patN, patD;
  var pat_name = "string"++channel++name.asString;
  var bus = ~outs[channel];
  pat_name = pat_name.asSymbol;
  // pat_name.postln;
  Pdef(pat_name).clear;
  Pdef(pat_name, Pbind(
    \instrument,\saw,\group, ~synths,
    \midi_note, patN,
    \dur, patD,
    \legato, 0.5,

    \a, Pfunc({
      arg event;
      var r=1.5;
      // event.dur.postln;
      if(event.dur < 1.5){r = event.dur - (event.dur*0.3333)  };
      // r.postln;
      r
    }),
    \r, Pfunc({
      arg event;
      var r=1.25;
      // event.dur.postln;
      if(event.dur < 1.5){r =  (0.125.rand) + (event.dur*0.125).rand };
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
~set = ~test_md5.reshape(4,8)

(
~make_violin_score = {
  arg md5=nil;
  var midiNotes=[], durations=[];
  var phrases;
  // if(md5==nil){"?????".postln; ^nil};
  "make violin score".postln;
  phrases = md5.reshape(4,8);
  phrases.do({
    arg list, i;
    var result;

    "<<<<>>>>>>>".postln;
    list.postln;

    result = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 16, tempo: 2.0, md5: list);
    midiNotes = midiNotes ++ result[0];
    durations = durations ++ result[1];
  });
  // var result = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 16, tempo: 2.0, md5: md5);
  // var midiNotes = result[0];
  // var durations = result[1];

  "hello".postln;
  "Generated phrase:".postln;
  "MIDI Notes: ".post; midiNotes.postln;
  "Durations: ".post; durations.postln;
  "lenght: ".post;midiNotes.size.postln;
  [midiNotes, durations]
};
)
(
~make_violin_phrases = {
  arg md5=nil;
  var midiNotes=[], durations=[];
  var phrases;
  // if(md5==nil){"?????".postln; ^nil};
  phrases = md5.reshape(4,8);
  phrases.do({
    arg list, i;
    var result;

    "<<<<>>>>>>>".postln;
    list.postln;

    result = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 16, tempo: 2.0, md5: list);
    midiNotes = midiNotes ++ result[0];
    durations = durations ++ result[1];
  });
  // var result = ~generateViolinPhrase.(chordSetIndex: 0, phraseLength: 16, tempo: 2.0, md5: md5);
  // var midiNotes = result[0];
  // var durations = result[1];

  "hello".postln;
  "Generated phrase:".postln;
  "MIDI Notes: ".post; midiNotes.postln;
  "Durations: ".post; durations.postln;
  "lenght: ".post;midiNotes.size.postln;

  ~pat = ~test_pat.(1, "test1", ~mpseq.(midiNotes), ~mpseq.(durations));
};
)
(
// Test it
~test_md5 = ~test_md5.rotate(32.rand);
~test_md5.postln;
~make_violin_phrases.(~test_md5);
)
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