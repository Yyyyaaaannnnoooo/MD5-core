(
s.waitForBoot({

  ~remote = NetAddr("127.0.0.1", 57121);
  ///~~~ SERVER CLEANUP ~~~///
  ~cleanup = {
    "DO cleanup".postln;
    ServerBoot.removeAll;
    ServerQuit.removeAll;
    ServerTree.removeAll;
    CmdPeriod.removeAll;
    Pdef.removeAll;
    OSCdef.freeAll;
    ~remote.sendMsg("/fail", "supercollider quit!");
  };
  // ~cleanup.();

  ServerQuit.add(~cleanup);
  ~instruments = [ "Violin", "Viola", "Cello"];

  ~midi_to_note = {
    arg midi;
    var result = "";
    if(midi.isArray)
    {
      midi.do({
        arg note, i;
        // var octave = (note.asFloat / 12.0).round - 1;
        // var note_name = String.makeNoteName(name: note, octave:octave);
        var note_name = ~convert_to_note.(note);
        result = result + note_name;
      });
    }
    {
      // var octave = (midi.asFloat / 12.0).round - 1;
      // result = String.makeNoteName(name: midi, octave:octave);
      result = ~convert_to_note.(midi);
    };
    result
  };

  ~convert_to_note = {
    arg midi;
    var sharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    var flatNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    var note = midi.asFloat % 12;
    var octave = ((midi.asFloat / 12).floor - 1).round;

    "% %".format(sharpNames[note], octave);
  };

  ~to_midi = {
    arg string, octave;
    var r;
    r = d.at(string.asSymbol) + 60;
    r = r + (12*octave);
    r
  };

  // Convert chord array to MIDI notes
  ~chord_to_midi = {
    arg chordArray, baseOctave=0;

    chordArray.collect {
      arg noteName;
      ~to_midi.(noteName, baseOctave)
    };
  };

  

  ~getmd5 = {
    arg txt;
    ~remote.sendMsg("/get", txt);
  };

  ~emit = {
    arg txt;
    ~remote.sendMsg("/play", txt);
  };

  ~emit_composition = {
    arg txt;
    ~remote.sendMsg("/composition", txt);
  };


  d = Dictionary.newFrom([\C, 0,'C#', 1,\D, 2,'D#', 3,\Eb, 3,\E, 4,\F, 5,'F#', 6,\G, 7,'G#', 8,    \Ab, 8,\A, 9,\Bb, 10,\B, 11,]);

  ~convert = {
    arg string;
    d.at(string.asSymbol);
  };

  ~notes = [
    [
      ["C", "Eb", "G"],
      ["F", "Ab", "C"],
      ["C", "Eb", "G"],
      ["G", "B",  "D"]
    ],
    [
      ["C", "Eb", "G"],
      ["F", "Ab", "C"],
      ["Ab", "C", "Eb"],
      ["G", "B", "D"],
    ],
    [
      ["D", "F", "A"],
      ["A", "C#", "E"],
      ["G", "Bb", "D"],
      ["A", "C#", "E"],
      ["D", "F", "A"],
    ],
    [
      ["D", "F", "A"],
      ["C#", "F", "G#", "C"],
      ["C#", "F", "G#", "C"],
      ["A", "C#", "E"],
    ],
    [
      ["Eb", "G", "Bb"],
      ["Bb", "D", "F"],
      ["C", "Eb", "G"],
      ["Ab", "C", "Eb"],
    ],
    [
      ["Eb", "G", "Bb"],
      ["Bb", "D", "F"],
      ["C", "Eb", "G"],
      ["G", "Bb", "D"],
      ["Ab", "C", "Eb"],
      ["Eb", "G", "Bb"],
      ["Ab", "C", "Eb"],
      ["Bb", "D", "F"],
    ],
    [
      ["A", "C", "E"],
      ["C", "E", "G"],
      ["F", "A", "C"],
      ["G", "B", "D"],
    ]
  ];

  ~chord_names = ["Kyrie V1", "Kyrie V2", "Dies Irae V1", "Dies Irae V2", "Sanctus V1", "Sanctus V2", "Lux Aeterna"];

  ~strings = [];
  ~viola = [];
  ~bass = [];
  ~score1 = [];
  ~trigs1 = [];
  ~score2 = [];
  ~trigs2 = [];
  ~score3 = [];
  ~trigs3 = [];
  ~score4 = [];
  ~trigs4 = [];
  ~offset = {arg val=0; ([0,0.05,0.1,0.15]+val).choose};
  ~mRest = {arg time; Rest(time)};

  // new score gen
  ~analyze_and_map = {
    arg input, chordProgressions, instrument=\violin;
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
      chordIndex = chordIndex % progression.size;
      chordIndices = chordIndices.add([progIndex, chordIndex]);
      // Determine texture based on gradient
      // textures = textures.add(
      //   case
      //   { grad > 0.8 } { \melodic_fast }
      //   { grad > 0.6 } { \melodic }
      //   { grad > 0.3 } { \melodic_long }
      //   { \drone }
      // );

      // textures = textures.add(
      //   case
      //   /*        { grad > 0.8 } { \melodic_fast }
      //   { grad > 0.6 } { \melodic }*/
      //   { grad > 0.5 } { \folk}
      //   { \complex }
      // );

      case
      {instrument == \violin} {
        textures = textures.add(
          case
          { grad > 0.3 } { \complex }
          { \drone }
        );
      }
      {instrument == \viola} {
        textures = textures.add(
          case
          { grad > 0.8 } { \melodic_fast }
          { grad > 0.6 } { \melodic }
          { grad > 0.3 } { \melodic_long }
          { \drone }
        );
      }
      {instrument == \bass} {
        textures = textures.add(
          case
          { grad > 0.5 } { \melodic_long }
          { \drone }
        );
      }



    };

    textures.do({arg item,i;i.post; ": ".post; item.postln});
    // "CHORDS".postln;
    // chordIndices.postln;
    [chordIndices, textures, normGradients];
  };

  // Main generative function
  ~generate_from_contour = {
    arg input, chordProgressions, baseOctave=0, duration_mult=1, instrument=\violin;
    var analysis = ~analyze_and_map.(input, chordProgressions, instrument);
    var chordIndices = analysis[0];
    var textures = analysis[1];
    var gradients = analysis[2];
    var midiNotes = [];
    var durations = [];
    var mn1 = [], mn2 = [], mn3 = [];
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
      var rest = input[i].linlin(0, 15, 2, 12);
      // "rest: ".post; rest.postln;
      // Convert current chord to MIDI
      currentChordMIDI = ~chord_to_midi.(chordNames, baseOctave);

      // "CURRENT CHORD: ".post; currChordProg.postln;
      // Generate musical material based on texture
      // texture.postln;
      switch(texture,
        \fast_arpeggio, {
          // Rapid, energetic arpeggio
          var arp = ~generate_arpeggio.(
            chord: currentChordMIDI,
            loops:16,
            octave: baseOctave,
            chordProg: currChordProg,
            rhythm: \sixteenths,
            tempo: 1.0,
            list:input,
            index:i,
          );
          midiNotes = midiNotes ++ arp[0];
          durations = durations ++ arp[1] ++ [~mRest.(rest)];
        },

        \arpeggio, {
          // Moderate arpeggio
          var arp = ~generate_arpeggio.(
            chord: currentChordMIDI,
            loops:16,
            octave: baseOctave,
            chordProg: currChordProg,
            rhythm: \eighth_triplet,
            tempo: 1.0,
            list:input,
            index:i,
          );
          midiNotes = midiNotes ++ arp[0];
          durations = durations ++ arp[1] ++ [~mRest.(rest)];
        },
        // midiNotes.postln;
        \melodic_fast, {
          // Single melodic line with passing tones
          var melody = ~generate_melody.(
            chord: currentChordMIDI,
            previousNote: if (midiNotes.size > 0) { midiNotes.last } { currentChordMIDI[0] },
            contour: if (input[i] > (input.wrapAt(i-1) ? input[i])) { \ascend } { \descend },
            duration: (1.0 + (grad * 2.0)) * duration_mult,
            numNotes: 8,
            octave:baseOctave,
            list:input,
            index:i,
          );
          midiNotes = midiNotes ++ melody[0];
          durations = durations ++ melody[1] ++ [~mRest.(rest)];
          // durations = durations ++ melody[1];
        },
        \melodic, {
          // Single melodic line with passing tones
          var melody = ~generate_melody.(
            chord: currentChordMIDI,
            previousNote: if (midiNotes.size > 0) { midiNotes.last } { currentChordMIDI[0] },
            contour: if (input[i] > (input.wrapAt(i-1) ? input[i])) { \ascend } { \descend },
            duration: (2.0 + (grad * 2.0))*duration_mult,
            numNotes: 8,
            octave:baseOctave,
            list:input,
            index:i,
          );
          midiNotes = midiNotes ++ melody[0];
          durations = durations ++ melody[1] ++ [~mRest.(rest)];
          // durations = durations ++ melody[1];
        },
        \melodic_long, {
          // Single melodic line with passing tones
          var melody = ~generate_melody.(
            chord: currentChordMIDI,
            previousNote: if (midiNotes.size > 0) { midiNotes.last } { currentChordMIDI[0] },
            contour: if (input[i] > (input.wrapAt(i-1) ? input[i])) { \ascend } { \descend },
            duration: (4.0 + (grad * 2.0)) * duration_mult,
            numNotes: 8,
            octave:baseOctave,
            list:input,
            index:i,
          );
          midiNotes = midiNotes ++ melody[0];
          durations = durations ++ melody[1] ++ [~mRest.(rest)];
          // durations = durations ++ melody[1];
        },

        \drone, {
          // Sustained chord drone
          var drone = ~generate_drone.(
            chord: currentChordMIDI,
            duration: (2.5 - (grad * 1.0)) * duration_mult, // Longer for flatter areas
            octave: baseOctave,
            chordProg: currChordProg,
            numPhrases:4,
            list:input,
            index:i,
          );
          midiNotes = midiNotes ++ drone[0];
          durations = durations ++ drone[1] ++ [~mRest.(rest)];
          // durations = durations ++ drone[1];
        },
        \complex, {
          // chord, previousNote, duration=1.0, numNotes=8, octave=0, list, index=0;
          var melody = ~generate_complex.(
            chord: currentChordMIDI,
            previousNote: if (midiNotes.size > 0) { midiNotes.last } { currentChordMIDI[0] },
            duration: 2.0,
            numNotes:32,
            octave:baseOctave,
            list:input,
            index:i
          );
          midiNotes = midiNotes ++ melody[0];
          durations = durations ++ melody[1] ++ [~mRest.(rest)];
        },
        \folk, {
          // chord, previousNote, duration=1.0, numNotes=16, octave=0, list, index=0;
          var melody = ~generate_folk.(
            chord: currentChordMIDI,
            previousNote: if (midiNotes.size > 0) { midiNotes.last } { currentChordMIDI[0] },
            duration: 2.0,
            numNotes:32,
            octave:baseOctave,
            list:input,
            index:i
          );
          midiNotes = midiNotes ++ melody[0];
          durations = durations ++ melody[1] ++ [~mRest.(rest)];
        },
      );
    };

    // midiNotes = [mn1, mn2, mn3];
    // durations = [d1, d2, d3];
    /*
    "GENERATED NOTES: ".postln;
    midiNotes.shape.postln;
    midiNotes.size.postln;
    durations.size.postln;
    [midiNotes, durations].postln;
    [midiNotes, durations];*/



    [midiNotes, durations];
  };

  // Arpeggio generator
  ~generate_arpeggio = {
    arg chord, loops=4, repeptitions=1,
    rhythm=\sixteenths, tempo=1.0, list,
    chordProg=nil, index=0, octave=0;
    var notes = [];
    var durs = [];
    var rhythmMap = Dictionary.newFrom([
      \sixteenths, 0.25,
      \eighth_triplet, 0.333,
      \eighths, 0.5,
      \quarters, 1.0
    ]);
    var baseDur = rhythmMap[rhythm] ? 0.25;
    var to_add = octave * 12;
    baseDur = baseDur * tempo;
    // "arpeggio".postln;
    // chord.postln;

    loops.do({
      arg item, i;
      var chord_sel = list[i];
      // var chord = chordProg.wrapAt(chord_sel);
      var chord = chordProg.wrapAt(i);
      var dur = durs.choose;
      chord = ~chord_to_midi.(chord);
      chord = chord + to_add;

      notes = notes.add(chord);
      durs = durs.add(baseDur);
    });

    // numNotes.do {
    //   arg i;
    //   var chordNote = chord.wrapAt(i);
    //   // var octave = octaves.choose;
    //   var note = chordNote + octave;
    //
    //   // Occasionally add chromatic passing tones
    //   if (0.2.coin) {
    //     note = note + [-1, 1].choose;
    //   };
    //
    //   notes = notes.add(note);
    //   durs = durs.add(baseDur);
    // };

    // Add slight ritardando at end of arpeggio
    durs[durs.size-1] = durs.last * 1.5;

    [notes, durs];
  };

  // Melodic generator
  ~generate_melody = {
    arg chord, previousNote, contour=\ascend,
    duration=1.0, numNotes=6, octave=0, list, index=0;
    var targetNote = chord.choose;
    var approachNote;
    var notes, durs;
    var humanize = list[index].linlin(0, 15, duration*0.125, duration*0.5);
    var to_add = octave * 12;

    if(previousNote.isArray){
      // "previous note is array".postln;
      previousNote = previousNote.last;
    };

    // "hello melody".postln;
    /*  "OCTAVE: ".post; to_add.postln;
    "DURATION: ".post; duration.postln;
    "HUMANIZE: ".post; humanize.postln;
    // humanize = humanize.rand;
    "HUMANIZE rand: ".post; humanize.postln;*/

    // Voice leading: approach target from previous note
    // "NOTES".postln;
    // chord.postln;
    // targetNote.postln;
    // previousNote.postln;
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
  ~generate_drone = {
    arg chord, duration=2.0,
    octave=0, chordProg=nil,
    numPhrases=4, list, index=0;
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
      chord = ~chord_to_midi.(chord);
      chord = chord + to_add;

      notes = notes.add(chord);
    });

    [notes, durs];
  };

  ~generate_complex = {
    arg chord, previousNote,
    duration=1.0, numNotes=8, octave=0, list, index=0;


    var notes, durs;
    var humanize = list[index].linlin(0, 15, duration*0.05, duration*0.25);
    var to_add = octave * 12;
    var baseNote;
    var halfNumNotes = numNotes / 2;
    var contour = [\ascend , \descend, \arch, \pendulum, \leaping].choose;
    contour.postln;
    if(numNotes.isNumber.not) {
      ("ERROR: numNotes is not a number! It is: " ++ numNotes).postln;
      numNotes = 8; // Default fallback
    };

    if(previousNote.isArray){
      previousNote = previousNote.last;
    };

    // Choose base note from chord
    baseNote = chord.sort({
      arg a, b;
      (a - previousNote).abs < (b - previousNote).abs
    })[0] ? chord.choose;

    notes = [];
    durs = [];

    numNotes.do { arg i;
      var note, dur;
      var position = i / numNotes;

      // Select note based on contour
      if(contour == \ascend) {
        note = baseNote + [0, 1, 2, 3, 4, 5, 7].choose;
      } {
        if(contour == \descend) {
          note = baseNote - [0, 1, 2, 3, 4, 5, 7].choose;
        } {
          if(contour == \arch) {
            if(i < halfNumNotes) {
              note = baseNote + (i * [1,2].choose) + [0,1].choose;
            } {
              note = baseNote + ((numNotes - i) * [1,2].choose) - [0,1].choose;
            };
          } {
            if(contour == \pendulum) {
              note = baseNote + ([-3, -2, -1, 1, 2, 3].wrapAt(i));
            } {
              if(contour == \leaping) {
                note = baseNote + [0, 5, 7, -5, -7, 12].choose;
              } {
                note = baseNote;
              };
            };
          };
        };
      };

      // Ensure chord tones on strong beats
      if(i % 4 == 0) {
        note = chord.choose;
      };

      // Duration patterns
      if(i % 4 == 0) {
        dur = duration * 2.0;
      } {
        if((i % 4 == 1) && (0.6.coin)) {
          dur = duration * 0.25;
        } {
          if(i % 3 == 0) {
            dur = duration * 1.5;
          } {
            if(i % 2 == 0) {
              dur = duration * 0.5;
            } {
              dur = duration * 1.0;
            };
          };
        };
      };

      // Add the note
      notes = notes ++ [note];
      durs = durs ++ [dur + humanize.rand];
    };

    notes = notes + to_add;
    [notes, durs];
  };

  // Function for folk arrangement style violin
  ~generate_folk = {
    arg chord, previousNote,
    duration=1.0, numNotes=16, octave=0, list, index=0;

    var notes, durs;
    var humanize = list[index].linlin(0, 15, duration*0.05, duration*0.2);
    var to_add = octave * 12;
    var root = chord[0];
    var fifth = chord[2] ? (root + 7);
    var rhythmPatterns;
    var rhythmFunc;
    var pattern = [\reel, \jig, \hornpipe, \waltz, \strathspey].choose;
    // pattern.postln;
    if(previousNote.isArray){
      previousNote = previousNote.last;
    };

    notes = [];
    durs = [];

    // Define rhythmic patterns for different folk dance types
    rhythmPatterns = (
      reel: { arg i;
        // Reel: even eighth notes with occasional accents through duration
        switch(i % 8)
        { 0 } { duration * 0.5 } // Eighth note
        { 1 } { duration * 0.5 }
        { 2 } { duration * 0.5 }
        { 3 } { duration * 0.5 }
        { 4 } { duration * 0.5 }
        { 5 } { duration * 0.5 }
        { 6 } { duration * 0.5 }
        { 7 } { duration * 1.0 }; // Quarter note on phrase end
      },

      jig: { arg i;
        // Jig: dotted eighth + sixteenth feel
        switch(i % 6)
        { 0 } { duration * 0.75 }
        { 1 } { duration * 0.25 }
        { 2 } { duration * 0.75 }
        { 3 } { duration * 0.25 }
        { 4 } { duration * 0.5 }
        { 5 } { duration * 0.5 };
      },

      hornpipe: { arg i;
        // Hornpipe: dotted rhythms
        switch(i % 4)
        { 0 } { duration * 0.75 }
        { 1 } { duration * 0.25 }
        { 2 } { duration * 0.75 }
        { 3 } { duration * 0.25 };
      },

      waltz: { arg i;
        // Waltz: quarter-half-quarter pattern
        switch(i % 3)
        { 0 } { duration * 1.0 }
        { 1 } { duration * 2.0 }
        { 2 } { duration * 1.0 };
      },

      strathspey: { arg i;
        // Strathspey: Scotch snap (short-long)
        switch(i % 4)
        { 0 } { duration * 0.25 }
        { 1 } { duration * 0.75 }
        { 2 } { duration * 0.25 }
        { 3 } { duration * 0.75 };
      }
    );

    // Select the rhythm function based on pattern
    rhythmFunc = rhythmPatterns[pattern] ? rhythmPatterns[\reel];

    numNotes.do { arg i;
      var note, dur;
      var phrasePos = i / numNotes;

      // Melodic patterns based on folk idioms
      case
      { pattern == \reel } {
        // Reel: mostly stepwise motion with occasional arpeggios
        if(i % 8 == 0) {
          note = chord.choose; // Chord tone on downbeat
        } {
          note = previousNote + [-2, -1, 1, 2].choose;
        };
      }

      { pattern == \jig } {
        // Jig: more arpeggiated, skipping around
        if(i % 3 == 0) {
          note = [root, fifth, root+12].choose;
        } {
          note = previousNote + [-3, -2, 2, 3, 4].choose;
        };
      }

      { pattern == \hornpipe } {
        // Hornpipe: fancier, with chromatic approaches
        if(i % 4 == 0) {
          note = chord.choose;
        } {
          if(0.3.coin) {
            note = previousNote + 1; // Chromatic approach
          } {
            note = previousNote + [-2, -1, 1, 2, 3].choose;
          };
        };
      }

      { pattern == \waltz } {
        // Waltz: sweeping arpeggios
        note = case
        { i % 3 == 0 } { root }
        { i % 3 == 1 } { fifth }
        { i % 3 == 2 } { root + 12 };
      }

      { pattern == \strathspey } {
        // Strathspey: angular, with wide intervals
        note = previousNote + [ -5, -4, -3, 3, 4, 5, 7 ].choose;
      };

      // Add drone-like passages (typical in folk)
      if((i > 4) && (i < 8) && (pattern != \waltz)) {
        // Double stop effect by playing root against melody
        if(0.4.coin) {
          note = [note, root].choose; // Alternate with drone
        };
      };

      // Get duration from pattern
      dur = rhythmFunc.value(i);

      // Add ornamentation through quick neighbor notes (typical folk ornaments)
      if((i % 3 == 1) && (0.3.coin) && (pattern != \waltz)) {
        // Add a cut (quick upper neighbor)
        var cutNote = note + 2;
        notes = notes ++ [cutNote];
        durs = durs ++ [duration * 0.15];

        // Add the main note slightly delayed
        notes = notes ++ [note];
        durs = durs ++ [dur * 0.85];
      } {
        // Regular note
        notes = notes ++ [note];
        durs = durs ++ [dur + humanize.rand];
      };

      previousNote = note;
    };

    notes = notes + to_add;
    [notes, durs];
  };


  // Generate and play the composition
  ~createComposition = {
    // input, chordProgressions, baseOctave=0;
    arg input;
    var violin_input = input[(0..10)];
    var viola_input = input[(10..21)];
    var bass_input = input[(20..31)];
    // .wrapAt(input.size)
    var violin_score = ~generate_from_contour.(violin_input.postln, ~notes, 1, 1, \violin);
    var viola_score = ~generate_from_contour.(viola_input.postln, ~notes, 0, 1, \viola);
    var bass_score = ~generate_from_contour.(bass_input.postln, ~notes, -1, 4, \bass);
    var midiNotes = violin_score[0];
    var durations = violin_score[1];
    var trigs1=[], trigs2=[], trigs3=[];
    var mutes = input[17].linlin(0, 15, 0, 9).floor.asInteger;
    var long1 = input[21].linexp(0, 15, 1,3).floor.asInteger;
    var long2 = input[22].linexp(0, 15, 1,3).floor.asInteger;
    var long3 = input[23].linexp(0, 15, 1,2).floor.asInteger;

    "=== GENERATED COMPOSITION ===".postln;
    "Total notes: %".format(midiNotes.size).postln;
    "Total duration: % seconds".format(durations.sum.round(0.01)).postln;

    // trigs1 = violin_score[1].collect({arg item,i;item = ~longer.(long1, item)});
    // trigs2 = viola_score[1].collect({arg item,i;item = ~longer.(long2, item)});
    trigs1 = violin_score[1];
    trigs2 = viola_score[1];
    trigs3 = bass_score[1];

    ~strings = ~make_ptn2.(0, violin_score[0], trigs1, input);
    ~viola = ~make_ptn2.(1, viola_score[0], trigs2, input.rotate(2));
    ~bass = ~make_ptn2.(2, bass_score[0], trigs3, input.rotate(4));

    fork{
      ~stop.();
      6.wait;
      "~~~ Execute Composition ~~~".postln;
      ~emit.("~~~ Composition is Playing ~~~");
      ~play.(mutes);
      // ~play.(1);
    };

  };

  ~play = {
    arg mutes;
    switch(
      mutes,
      0, {
        ~strings.do({arg item; item.play})
      },
      1, {
        ~viola.do({arg item; item.play})
      },
      2, {
        ~bass.do({arg item; item.stop})
      },
      3, {
        fork{
          ~strings.do({arg item; item.play});
          2.wait;
          ~viola.do({arg item; item.play})
        }
      },
      4, {
        fork{
          ~viola.do({arg item; item.play});
          2.wait;
          ~bass.do({arg item; item.play});
        }
      },
      5, {
        fork{
          ~strings.do({arg item; item.play});
          2.wait;
          ~bass.do({arg item; item.play});
        }
      },
      6, {
        fork{
          ~strings.do({arg item; item.play});
          2.wait;
          ~viola.do({arg item; item.play});
          2.wait;
          ~bass.do({arg item; item.play});
        }
      },
      7, {
        fork{
          ~strings.do({arg item; item.play});
          2.wait;
          ~viola.do({arg item; item.play});
          2.wait;
          ~bass.do({arg item; item.play});

        }
      },
      8, {
        fork{
          ~strings.do({arg item; item.play});
          2.wait;
          ~viola.do({arg item; item.play});
          2.wait;
          ~bass.do({arg item; item.play});

        }
      },
      9, {
        fork{
          ~strings.do({arg item; item.play});
          2.wait;
          ~viola.do({arg item; item.play});
          2.wait;
          ~bass.do({arg item; item.play});

        }
      },
    );
  };

  // STOP
  ~stop = {
    // Pdef.removeAll;
    ~strings.do({arg item; item.stop});
    ~viola.do({arg item; item.stop});
    ~bass.do({arg item; item.stop});
  };

  ~make_velocities = {
    arg list;
    var result;
    result = list.linlin(0, 15, 0.8, 1);
  };

  ~stutter = {
    arg number, score, trigs;
    score = score.dupEach(number);
    trigs = trigs.dupEach(number) * number.reciprocal;
    [score, trigs];
  };

  ~longer = {
    arg number, trigs;
    trigs = trigs * number;
    trigs;
  };

  ~mpseq = {arg list;  Pseq(list, inf)};

  ~make_ptn2 = {
    arg ch, notes, trigs, list;
    var v1 = list[(0..9)];
    var p1=nil, p2=nil, p3=nil;
    v1 = ~make_velocities.(v1).linlin(0.8, 1, -40.dbamp, -30.dbamp);
    p1 = ~mpdef.(ch, "p1", ~mpseq.(notes), ~mpseq.(trigs), ~mpseq.(v1));
    [p1,p2,p3]
  };

  // Patterns for Sc SynthDefs
  ~mpdef = {
    arg channel, name=nil, patN, patD, patV;
    var pat_name = "string"++channel++name.asString;
    var bus = ~outs[channel];
    pat_name = pat_name.asSymbol;
    Pdef(pat_name).clear;
    Pdef(pat_name, Pbind(
      \instrument,\saw,\group, ~synths,
      \midi_note, patN,
      \dur, patD,
      \amp, patV, // velocity
      \vibRate, Pwhite(3.5, 6.5, inf),
      \vibDepth, Pwhite(0.0025, 0.007, inf),
      \legato, Pfunc({
        arg event;
        var r = 1.5;
        if(event.dur > 4){r = 1};
        r
      }),
      \a, Pfunc({
        arg event;
        var r=1.5;
        if(event.dur < 1.5){r = event.dur - (event.dur*0.3333)};
        r
      }),
      \r, Pfunc({
        arg event;
        var r=1.25;
        if(event.dur < 1.5){r =  (0.125.rand) + (event.dur*0.125).rand };
        r
      }),
      \offset, Pfunc({
        arg event;
        var r = 0;
        if(event.dur > 4){r = 2}{r = 1};
        r
      }),
      \out, bus,
      \trace, Pfunc({
        arg ev;
        var midi = ~midi_to_note.(ev[\midi_note]);
        var inst = ~instruments[channel];
        if(ev[\dur].asString.contains("Rest") == false)
        {
          ~emit_composition.((inst ++ " >>> " ++ midi));
        }{"REST".postln;}
      }),
    ));
    Pdef(pat_name).quant_(1);
    Pdef(pat_name).fadeTime = 1.0;
  };

  s.sync;

  SynthDef(\saw, {
    arg midi_note=55, dur=1, out=0,
    offset=0.0,a=1.5, d=0.125,
    s=0.75, r=1.25, vibRate=5.5, vibDepth=0.005;
    var sig, env, detune, freq=midi_note.midicps;
    var vibrato = SinOsc.kr(vibRate) * vibDepth * freq;
    detune = LFNoise1.kr(0.2!6).bipolar(0.2).midiratio;
    sig = LFSaw.ar((midi_note.midicps + vibrato) * detune);
    sig = Mix.ar(sig);
    sig = CombC.ar(sig, 0.5, 0.1, 0.5);
    env = EnvGen.kr(
      envelope: Env.dadsr(
        (offset * 0.125) + offset.rand,
        a + 0.025.rand2,
        d + 0.01.rand2,
        s + 0.01.rand2,
        r + 0.025.rand2,
        curve:[4, -4, 4]),
      gate: \gate.kr(1),
      doneAction: Done.freeSelf
    );
    sig = sig * env * \amp.kr(-30.dbamp);
    Out.ar(out, sig!2)
  }).add;



  SynthDef(\mixer, {
    arg in1=~ch1, in2=~ch2, in3=~ch3;
    var input1 = In.ar(in1, 2);
    var input2 = In.ar(in2, 2);
    var input3 = In.ar(in3, 2);
    var sig1, sig2, sig3, snd;
    sig1= RLPF.ar(input1, \lpf1.kr(8000, 0.25).clip(20, 19000));
    sig1 = RHPF.ar(sig1, \hpf1.kr(40, 0.5).clip(20, 19000));
    sig1 = Balance2.ar(sig1[0], sig1[1], \pan1.kr(0));
    sig1 = sig1 * \amp1.kr(0.dbamp, 0.5);

    sig2= RLPF.ar(input2, \lpf2.kr(8000, 0.25).clip(20, 19000));
    sig2 = RHPF.ar(sig2, \hpf2.kr(40, 0.5).clip(20, 19000));
    sig2 = Balance2.ar(sig2[0], sig2[1], \pan2.kr(0));
    sig2 = sig2 * \amp2.kr(0.dbamp, 0.5);

    sig3= RLPF.ar(input3, \lpf3.kr(8000, 0.25).clip(20, 19000));
    sig3 = RHPF.ar(sig3, \hpf3.kr(40, 0.5).clip(20, 19000));
    sig3 = Balance2.ar(sig3[0], sig3[1], \pan3.kr(0));
    sig3 = sig3 * \amp3.kr(0.dbamp, 0.5);

    snd = sig1+sig2+sig3;

    Out.ar(\aux.kr(~bus1), snd * \send.kr(1, 0.5).clip(0,1));
    Out.ar(0, snd * \mute.kr(1).clip(0, 1));
  }).add;

  s.sync;

  SynthDef(\reverb3, {
    arg inbus=~bus1, out=0;
    var input, sig;
    input = In.ar(inbus, 2);
    input = input.sum * 0.05;
    sig = GVerb.ar(
      in:input,
      roomsize: \size.kr(80),
      revtime: \time.kr(4.85),
      damping: \damp.kr(0.41),
      inputbw: 0.19,
      spread: \spread.kr(15),
      drylevel:-3,
      earlyreflevel: -11,
      taillevel: -9,
      maxroomsize: 300,
    );
    Out.ar(out, sig*\amp.kr(0.25));
  }).add;

  ~init = {
    s.newBusAllocators;
    ~mic = Bus.audio(s, 1);
    ~bus1 = Bus.audio(s, 2);
    ~ch1 = Bus.audio(s, 2);
    ~ch2 = Bus.audio(s, 2);
    ~ch3 = Bus.audio(s, 2);
    ~synths = Group.new();
    ~mix = Group.after(~synths);
    ~fx = Group.after(~mix);
    ~outs = [~ch1, ~ch2, ~ch3];
  };



  ~init_audio = {
    ~mixer = Synth(\mixer,[
      \in1,~ch1,
      \in2,~ch2,
      \in3,~ch3,
      \hpf1, 1000,
      \amp1, 0.dbamp,
      \pan1, 0.85,
      \hpf2, 500,
      \lpf2, 11500,
      \amp2, 0.dbamp,
      \pan2, -0.85,
      \amp3, 6.dbamp,
      \lpf3, 2000,
      \aux, ~bus1,
    ],
    target:~mix);
    ~reverb = Synth(\reverb3,[\inbus, ~bus1,\size, 200,\spread, 15],target:~fx);
  };

  ~init.();
  s.sync;
  ~init_audio.();
  s.sync;

  OSCdef(
    key: \image,
    func: {
      arg msg, time, addr, recvPort;
      var ch = 0;
      // msg.postln;
      msg.removeAt(0);
      "~~~ New Composition ~~~".postln;
      ~stop.();
      Pdef.removeAll;
      ~createComposition.(msg)
    },
    path: '/md5');

  OSCdef(
    key: \panic,
    func: {
      arg msg, time, addr, recvPort;
      var ch = 0;
      "~~~ PANIC MODE! ~~~".postln;
      ~emit_composition.("~~~ PANIC MODE! ~~~");
      Pdef.removeAll;
    },
    path: '/panic');

  OSCdef(
    key: \ready,
    func: {
      arg msg, time, addr, recvPort;
      var ch = 0;
      ~emit.("NODE >>> SUPERCOLLIDER. || CONNECTION DONE!");
      "NODE >>> SUPERCOLLIDER. || CONNECTION DONE!".postln;
      ~startup.stop;
    },
    path: '/ready');

  ~startup = {
    loop{
      ~remote.sendMsg("/startup", ">>> SUPERCOLLIDER READY TO RECEIVE MD5");
      "waiting for node server....".postln;
      0.5.wait;
    }
  }.fork;
  
});

)





