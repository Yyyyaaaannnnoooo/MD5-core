(
// TO DO: add rests!!!!


// Your dictionary with pitch classes
d = Dictionary.newFrom([
  \C, 0, 'C#', 1, \Db, 1, \D, 2, 'D#', 3, \Eb, 3,
  \E, 4, \F, 5, 'F#', 6, \Gb, 6, \G, 7,
  'G#', 8, \Ab, 8, \A, 9, 'A#', 10, \Bb, 10, \B, 11
]);

~to_midi = {
  arg string, octave;
  var r;
  r = d.at(string.asSymbol) + 60;
  r = r + (12*octave);
  r
};

// Convert chord array to MIDI notes
~chordToMIDI = {
  arg chordArray, baseOctave=0;
  chordArray.collect { |noteName|
    ~to_midi.(noteName, baseOctave)
  };
};

// Test it
"Testing converter:".postln;
~chordToMIDI.(["C", "Eb", "G"], 0).postln; // Should return [60, 63, 67]
~chordToMIDI.(["A", "C#", "E"], 0).postln; // Should return [69, 73, 76]
)

(
// Your input data
~input = [2, 11,  9,  9,  5,  7,  7, 10, 15,  15, 10, 10, 14, 12, 15,  9,  8, 14,   3,  1,  9,  4,  9, 13, 12, 11, 12,  10, 10, 14, 10,  8];

// Analyze gradients and select chords based on input values
~analyzeAndMap = {
  arg input, chordProgressions;
  var gradients = input.differentiate.drop(1).abs;
  var normGradients = gradients.normalize(0, 1);
  var chordIndices = [];
  var textures = [];

  // Map each input value to chord progression selection
  input.do {
    arg value, i;
    // Use value to select chord progression (0-6)
    var progIndex = value % chordProgressions.size;

    // Use position to select chord within progression
    var chordIndex = i % 3; // Most progressions are 4 chords

    // Ensure we don't go out of bounds
    var progression = chordProgressions[progIndex];

    var grad = normGradients.wrapAt(i);
    // "grad".post;    grad.postln;

    chordIndex = chordIndex % progression.size;

    chordIndices = chordIndices.add([progIndex, chordIndex]);


    // Determine texture based on gradient
    // if (i > 0) {
    //   var grad = normGradients[i-1];
    //   textures = textures.add(
    //     case
    //     // { grad > 0.7 } { \fast_arpeggio }
    //     // { grad > 0.4 } { \arpeggio }
    //     { grad > 0.8 } { \melodic_fast }
    //     { grad > 0.6 } { \melodic }
    //     { grad > 0.3 } { \melodic_long }
    //     { \drone }
    //   );
    // } {
    //   // textures = textures.add(\drone); // First element default
    //   textures = textures.add(\melody); // First element default
    // };
    //

    textures = textures.add(
      case
      { grad > 0.8 } { \melodic_fast }
      { grad > 0.6 } { \melodic }
      { grad > 0.3 } { \melodic_long }
      { \drone }
    );

  };

  textures.do({arg item,i;i.post; ": ".post; item.postln});
  // "CHORDS".postln;
  // chordIndices.postln;
  [chordIndices, textures, normGradients];
};

// Main generative function
~generateFromContour = {
  arg input, chordProgressions, baseOctave=0, duration_mult=1;
  var analysis = ~analyzeAndMap.(input, chordProgressions);
  var chordIndices = analysis[0];
  var textures = analysis[1];
  var gradients = analysis[2];

  var midiNotes = [];
  var mn1 = [], mn2 = [], mn3 = [];
  var durations = [];
  var d1=[], d2=[], d3=[];
  var currentChordMIDI;
  baseOctave = baseOctave.clip(-2, 2);
  chordIndices.do {
    arg indices, i;
    var progIndex = indices[0];
    var chordIndex = indices[1];
    var texture = textures[i];
    var grad = if (i > 0) { gradients[i-1] } { 0 };
    var chordNames = chordProgressions[progIndex][chordIndex];
    var currChordProg = chordProgressions[progIndex];
    var rest = input[i].linlin(0, 15, 2, 8);
    "rest: ".post; rest.postln;
    // Convert current chord to MIDI
    currentChordMIDI = ~chordToMIDI.(chordNames, baseOctave);

    // "CURRENT CHORD: ".post; currChordProg.postln;
    // Generate musical material based on texture
    // texture.postln;
    switch(texture,
      // \fast_arpeggio, {
      //   // Rapid, energetic arpeggio
      //   var arp = ~generateArpeggio.(
      //     chord: currentChordMIDI,
      //     numNotes: 8,
      //     octaveRange: 2,
      //     rhythm: \sixteenths,
      //     tempo: 4.0,
      //     list:~input,
      //     index:i,
      //   );
      //   midiNotes = midiNotes ++ arp[0];
      //   durations = durations ++ arp[1];
      // },
      //
      // \arpeggio, {
      //   // Moderate arpeggio
      //   var arp = ~generateArpeggio.(
      //     chord: currentChordMIDI,
      //     numNotes: 8,
      //     octaveRange: 1,
      //     rhythm: \eighth_triplet,
      //     tempo: 4.0,
      //     list:~input,
      //     index:i,
      //   );
      //   midiNotes = midiNotes ++ arp[0];
      //   durations = durations ++ arp[1];
      // },

      \melodic_fast, {
        // Single melodic line with passing tones
        var melody = ~generateMelody.(
          chord: currentChordMIDI,
          previousNote: if (mn1.size > 0) { mn1.last } { currentChordMIDI[0] },
          contour: if (input[i] > (input.wrapAt(i-1) ? input[i])) { \ascend } { \descend },
          duration: (1.0 + (grad * 2.0)) * duration_mult,
          numNotes: 8,
          octave:baseOctave,
          list:~input,
          index:i,
        );
        midiNotes = midiNotes ++ melody[0];
        durations = durations ++ melody[1] ++ [~mRest.(rest)];
      },
      \melodic, {
        // Single melodic line with passing tones
        var melody = ~generateMelody.(
          chord: currentChordMIDI,
          previousNote: if (mn1.size > 0) { mn1.last } { currentChordMIDI[0] },
          contour: if (input[i] > (input.wrapAt(i-1) ? input[i])) { \ascend } { \descend },
          duration: (2.0 + (grad * 2.0))*duration_mult,
          numNotes: 8,
          octave:baseOctave,
          list:~input,
          index:i,
        );
        midiNotes = midiNotes ++ melody[0];
        durations = durations ++ melody[1] ++ [~mRest.(rest)];
      },
      \melodic_long, {
        // Single melodic line with passing tones
        var melody = ~generateMelody.(
          chord: currentChordMIDI,
          previousNote: if (mn1.size > 0) { mn1.last } { currentChordMIDI[0] },
          contour: if (input[i] > (input.wrapAt(i-1) ? input[i])) { \ascend } { \descend },
          duration: (4.0 + (grad * 2.0)) * duration_mult,
          numNotes: 8,
          octave:baseOctave,
          list:~input,
          index:i,
        );
        midiNotes = midiNotes ++ melody[0];
        durations = durations ++ melody[1] ++ [~mRest.(rest)];
      },

      \drone, {
        // Sustained chord drone
        var drone = ~generateDrone.(
          chord: currentChordMIDI,
          duration: (2.5 - (grad * 1.0)) * duration_mult, // Longer for flatter areas
          octave: baseOctave,
          chordProg: currChordProg,
          numPhrases:4,
          list:~input,
          index:i,
        );
        midiNotes = midiNotes ++ drone[0];
        durations = durations ++ drone[1] ++ [~mRest.(rest)];
      }
    );
  };

  // midiNotes = [mn1, mn2, mn3];
  // durations = [d1, d2, d3];

  "GENERATED NOTES: ".postln;
  midiNotes.shape.postln;
  midiNotes.size.postln;
  durations.size.postln;
  [midiNotes, durations].postln;
  [midiNotes, durations];
};

// Arpeggio generator
~generateArpeggio = {
  arg chord, numNotes=4, octaveRange=1, rhythm=\sixteenths, tempo=1.0, list=~input, index=0;
  var notes = [];
  var durs = [];
  var octaves = (0..octaveRange) * 12;
  var rhythmMap = Dictionary.newFrom([
    \sixteenths, 0.25,
    \eighth_triplet, 0.333,
    \eighths, 0.5,
    \quarters, 1.0
  ]);

  var baseDur = rhythmMap[rhythm] ? 0.25;
  baseDur = baseDur * tempo;
  // "arpeggio".postln;
  // chord.postln;

  numNotes.do {
    arg i;
    var chordNote = chord.wrapAt(i);
    var octave = octaves.choose;
    var note = chordNote + octave; // Violin range

    // Occasionally add chromatic passing tones
    if (0.2.coin) {
      note = note + [-1, 1].choose;
    };

    notes = notes.add(note);
    durs = durs.add(baseDur);
  };
  // Add slight ritardando at end of arpeggio
  durs[durs.size-1] = durs.last * 1.5;



  // notes = [notes, notes.copy, notes.copy];
  // this creates dummy sequences that only rest aka no note is played
  // durs = [durs, [Rest(1)], [Rest(1)]];

  [notes, durs];
};

// Melodic generator
~generateMelody = {
  arg chord, previousNote, contour=\ascend,
  duration=1.0, numNotes=6, octave=0, list=~input, index=0;
  var targetNote = chord.choose;
  var approachNote;
  var notes, durs;
  var humanize = list[index].linlin(0, 15, duration*0.125, duration*0.5);
  var to_add = octave * 12;
  /*  "OCTAVE: ".post; to_add.postln;
  "DURATION: ".post; duration.postln;
  "HUMANIZE: ".post; humanize.postln;
  // humanize = humanize.rand;
  "HUMANIZE rand: ".post; humanize.postln;*/

  // Voice leading: approach target from previous note
  if ((targetNote - previousNote).abs > 7) {
    // Large leap: use chord tone closer to previous note
    targetNote = chord.sort {
      arg a, b;
      (a - previousNote).abs < (b - previousNote).abs
    }[0];
  };

  // Decide whether to add approach note
  if (0.6.coin) {
    // Add a passing tone
    approachNote = if (contour == \ascend) {
      targetNote - 2
    } {
      targetNote + 2
    };

    notes = [approachNote, targetNote];
    durs = [(duration * 0.3) + humanize.rand, (duration * 0.7)+humanize.rand];
  } {
    notes = [targetNote];
    durs = [duration+humanize.rand];
  };

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

    nextNote = (notes.last + interval);
    // Ensure it's a chord tone on strong beats

    notes = notes ++ [nextNote];
    durs = durs ++ [duration+humanize.rand];
  };
  notes = notes + to_add;
  [notes, durs];
};

// Drone generator
~generateDrone = {
  arg chord, duration=2.0,
  octave=0, chordProg=nil,
  numPhrases=4, list=~input, index=0;
  var notes = [];
  var n1 = [], n2 = [], n3 = [];
  var t1 = [], t2 = [], t3 = [];

  // THIS CAN BE IMPROVED!!!
  var durs = list[(0..(numPhrases-1))].linlin(0,15,5,10) + duration;
  var to_add = octave * 12;

  numPhrases.do({
    arg item, i;
    var chord_sel = list[i];
    var chord = chordProg.wrapAt(chord_sel);
    var dur = durs.choose;
    // var rest = rests.choose;
    // "SELECTED CHORD".postln;
    // chord.postln;
    chord = ~chordToMIDI.(chord);
    // chord.postln;
    chord = chord + to_add;

    notes = notes.add(chord);
  });

  [notes, durs];
};

//


~make_ptn = {
  arg ch, notes, trigs, list;
  var n1 = notes[0], n2 = notes[1], n3 = notes[2];
  var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];
  var v1 = list[(0..9)], v2 = list[(10..19)], v3 = list[(20..29)];
  // var chordOrNote = list[30]>7.5;
  var p1=nil, p2=nil, p3=nil, ret;

  v1 = ~make_velocities.(v1).linlin(0.8, 1, -40.dbamp, -30.dbamp);
  v2 = ~make_velocities.(v2).linlin(0.8, 1, -40.dbamp, -30.dbamp);
  v3 = ~make_velocities.(v3).linlin(0.8, 1, -40.dbamp, -30.dbamp);
  // choose whether single or chord
  // "Chord Or Note?".postln;
  // list[30].postln;
  // chordOrNote.postln;

  p1 = ~mpdef.(ch, "p1", ~mpseq.(n1), ~mpseq.(t1), ~mpseq.(v1));
  p2 = ~mpdef.(ch, "p2", ~mpseq.(n2), ~mpseq.(t2), ~mpseq.(v2));
  p3 = ~mpdef.(ch, "p3", ~mpseq.(n3), ~mpseq.(t3), ~mpseq.(v3));


  [p1,p2,p3]
};


~make_ptn2 = {
  arg ch, notes, trigs, list;
  var v1 = list[(0..9)];
  var p1=nil, p2=nil, p3=nil;
  notes.postln;
  v1 = ~make_velocities.(v1).linlin(0.8, 1, -40.dbamp, -30.dbamp);
  p1 = ~mpdef.(ch, "p1", ~mpseq.(notes), ~mpseq.(trigs), ~mpseq.(v1));
  [p1,p2,p3]
};


// Generate and play the composition
~createComposition = {
  // input, chordProgressions, baseOctave=0;
  var violin_score = ~generateFromContour.(~input, ~notes, 1, 1);
  var viola_score = ~generateFromContour.(~input.rotate(2), ~notes, 0, 2);
  var bass_score = ~generateFromContour.(~input.rotate(4), ~notes, -1, 4);
  var midiNotes = violin_score[0];
  var durations = violin_score[1];
  var trigs1=[], trigs2=[], trigs3=[];
  var long1 = ~input[21].linexp(0, 15, 1,3).floor.asInteger;
  var long2 = ~input[22].linexp(0, 15, 1,3).floor.asInteger;
  var long3 = ~input[23].linexp(0, 15, 1,3).floor.asInteger;

  "make composition".postln;

  // Visualize
  // ~visualizeMapping.(~input, ~notes);

  "\n=== GENERATED COMPOSITION ===".postln;
  "Total notes: %".format(midiNotes.size).postln;
  "Total duration: % beats".format(durations.sum.round(0.01)).postln;

  trigs1 = violin_score[1].collect({arg item,i;item = ~longer.(long1, item)});
  trigs2 = viola_score[1].collect({arg item,i;item = ~longer.(long2, item)});
  trigs3 = bass_score[1].collect({arg item,i;item = ~longer.(long3, item)});

  ~strings = ~make_ptn2.(0, violin_score[0], trigs1, ~input);
  ~viola = ~make_ptn2.(1, viola_score[0], trigs2, ~input.rotate(2));
  ~bass = ~make_ptn2.(2, bass_score[0], trigs3, ~input.rotate(4));
  // ~strings = ~make_mono_ptn.(0, ~score1, ~trigs1, list);
  // ~viola   = ~make_chord_ptn.(1, ~score2, ~trigs2, list.rotate(2));
  // ~bass    = ~make_chord_ptn.(2, ~score3 - 24, ~trigs3, list.rotate(4));

};

~composition = ~createComposition.();
)


~strings.do({arg item; item.play})

~play.(8)

s.boot
~composition = ~createComposition.();
~coposition
~midiNotes = ~composition[0];
~durations = ~composition[1];

// Play it
Pdef(\contourMusic).play;
Pdef(\contourMusic).stop;

~stop.()
Pdef.removeAll
~mpseq.()