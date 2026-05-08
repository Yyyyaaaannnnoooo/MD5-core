(

MIDIClient.init;
t = TempoClock.new(140/60).permanent_(true);
// ~mclock = MIDIClockOut.new("AudioBox USB 96", "AudioBox USB 96", t);
// m = MIDIOut(2);
~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);
m = MIDIOut(0);
m = MIDIOut.newByName("IAC Driver", "Bus 1");
)

(

// Your dictionary with pitch classes
~note_dict = Dictionary.newFrom([
  \C, 0,
  'C#', 1,
  \Db, 1,
  \D, 2, 'D#', 3, \Eb, 3,
  \E, 4, \F, 5, 'F#', 6, \Gb, 6, \G, 7,
  'G#', 8, \Ab, 8, \A, 9, 'A#', 10, \Bb, 10, \B, 11
]);

~to_midi = {
  arg string, octave;
  var r;
  // string.postln;
  r = ~note_dict.at(string.asSymbol) + 60;
  r = r + (12*octave);
  r
};

~chordto_midi = {
  arg chordArray, baseOctave=0;

  chordArray.collect {
    arg noteName;
    ~to_midi.(noteName, baseOctave)
  };
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

~mpseq = {arg list;  Pseq(list, inf)};

~mmn = {
  arg channel, name=nil, patN, patD, patV;
  var pat_name = "ch"++channel++name.asString;
  pat_name = pat_name.asSymbol;
  Pdef(pat_name).clear;
  Pdef(pat_name, Pbind(
    \type,\midi,
    \midiout,m,\midicmd,\noteOn,\chan,channel,
    \midinote, patN,
    \dur, patD,
    \amp, patV, // velocity
  ));
  Pdef(pat_name).quant_(1);
  Pdef(pat_name).fadeTime = 1.0;
};

~mmcc = {
  arg channel, name, cc, patCC, patD;
  var pat_name = "ch"++channel++"cc"++cc.asString.asSymbol;
  Pdef(pat_name, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan,channel,\ctlNum,cc,
    \control, patCC,
    \dur, patD,
  ));
  Pdef(pat_name).quant_(1);
  Pdef(pat_name).fadeTime = 1.0;
};

~analyzeAndMap = {
  arg input, chordProgressions;
  var gradients = input.differentiate.drop(1).abs;
  var normGradients = gradients.normalize(0, 1);
  var chordIndices = [];
  var textures = [];
  "analysis done".postln;
  // input.postln;
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
    textures = textures.add(
      case
      { grad > 0.8 } { \melodic_fast }
      { grad > 0.6 } { \melodic }
      { grad > 0.3 } { \melodic_long }
      { \drone }
    );

  };

  // textures.do({arg item,i;i.post; ": ".post; item.postln});
  // "analysis done".postln;
  // chordIndices.postln;
  [chordIndices, textures, normGradients];
};
// Dubstep Music Generator
// Uses contour analysis to generate drum patterns, melodies, and bass lines

// Drum pattern complexity mapping
~drumComplexity = {
  arg grad, inputValue;
  var complexity;
  case
  { grad > 0.8 } { complexity = 4 }  // Very complex, fast breaks
  { grad > 0.6 } { complexity = 3 }  // Complex patterns
  { grad > 0.3 } { complexity = 2 }  // Medium complexity
  { complexity = 1 };                 // Simple patterns
  complexity;
};


~map8to32 = { arg pattern8;
  var pattern32 = Array.fill(32, 0);
  pattern8.do { arg val, i;
    pattern32[i * 4] = val;  // Map 8-step to 32-step (each 8th note becomes 4 32nd notes)
  };
  pattern32;
};

~generateKickPattern = {
  arg input, gradients, index;
  var kickPatterns8 = [
    [1, 0, 0, 0, 1, 0, 0, 0],  // Basic 2-step
    [1, 0, 0, 0, 1, 0, 1, 0],  // 2-step with ghost
    [1, 0, 1, 0, 1, 0, 0, 0],  // Double kick
    [1, 0, 0, 0, 1, 0, 1, 1],  // Fill pattern
    [1, 1, 0, 0, 1, 0, 0, 0],  // Fast double
    [1, 0, 0, 1, 1, 0, 0, 0],  // Syncopated
    [1, 0, 0, 0, 1, 1, 0, 0],  // Late snare feel
    [1, 0, 1, 0, 1, 1, 0, 0],  // Complex pattern
    [1, 0, 0, 0, 1, 0, 0, 1],  // Late kick
    [1, 0, 0, 0, 0, 0, 1, 0],  // Sparse
    [1, 0, 0, 0, 1, 0, 1, 1],  // Filled
    [1, 1, 0, 0, 1, 1, 0, 0],  // Double time
  ];

  var complexity = ~drumComplexity.(gradients.wrapAt(index), input[index]);
  var kickIndex = ((input[index] + complexity) % kickPatterns8.size).asInteger;
  var pattern8 = kickPatterns8[kickIndex];

  ~map8to32.(pattern8);
};

~generateSnarePattern = {
  arg input, gradients, index;
  var snarePatterns8 = [
    [0, 0, 0, 0, 1, 0, 0, 0],  // Basic snare on 3
    [0, 0, 1, 0, 1, 0, 0, 0],  // Early snare
    [0, 0, 0, 0, 1, 0, 1, 0],  // Double snare
    [0, 0, 1, 0, 1, 0, 1, 0],  // Complex snare
    [0, 1, 0, 0, 1, 0, 0, 0],  // Ghost note
    [0, 0, 0, 1, 1, 0, 0, 0],  // Syncopated
    [0, 0, 0, 0, 1, 1, 0, 1],  // Fill pattern
    [0, 1, 0, 1, 1, 0, 1, 0],  // Full pattern
    [0, 0, 0, 0, 1, 0, 0, 1],  // Late snare
    [0, 1, 0, 0, 1, 1, 0, 0],  // Ghost with fill
    [0, 0, 1, 0, 1, 0, 0, 1],  // Complex syncopation
    [0, 1, 0, 1, 1, 0, 0, 0],  // Dubstep style
  ];

  var complexity = ~drumComplexity.(gradients.wrapAt(index), input[index]);
  var snareIndex = ((input[index] + complexity) % snarePatterns8.size).asInteger;
  var pattern8 = snarePatterns8[snareIndex];

  ~map8to32.(pattern8);
};

~generateHihatPattern = {
  arg input, gradients, index;
  // Hihat patterns with 1/32 resolution - these can be more detailed
  var hihatPatterns = [
    // 8th note patterns (on the 8th note grid)
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],  // Basic 8th notes
    [1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0],  // 16th note feel
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Full 32nd notes

    // Syncopated patterns
    [1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1],  // Group of 3 pattern
    [1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1],  // Busy with accents
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],  // Off-beat focus

    // More complex syncopation
    [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0],  // Complex syncopated
    [1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0],  // Double hit groups
    [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0],  // Sparse with accents

    // Shuffle/swing patterns
    [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],  // Quarter note pulse
    [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1],  // Shuffle pattern
    [0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0],  // Rolling pattern

    // Dubstep specific patterns
    [1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],  // Syncopated variation
    [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0],  // Half-time feel
  ];

  var complexity = ~drumComplexity.(gradients.wrapAt(index), input[index]);
  var hatIndex;

  // Higher complexity = more syncopated, busier patterns
  switch(complexity,
    1, { hatIndex = (input[index] % 4).asInteger },           // Basic patterns
    2, { hatIndex = (input[index] % 4 + 4).asInteger },       // Medium patterns
    3, { hatIndex = (input[index] % 4 + 8).asInteger },       // Complex patterns
    4, { hatIndex = (input[index] % 2 + 12).asInteger }       // Most complex patterns
  );

  hatIndex = hatIndex % hihatPatterns.size;

  hatIndex.postln;

  hihatPatterns[hatIndex];
};

// Generate drum patterns based on contour
~generateDrumPattern = {
  arg input, gradients, index;
  var kicks = [], snares = [], hats = [], crashes = [];
  var kickPatterns = [
    [1, 0, 0, 0, 1, 0, 0, 0],  // Basic 2-step
    [1, 0, 0, 0, 1, 0, 1, 0],  // 2-step with ghost
    [1, 0, 1, 0, 1, 0, 0, 0],  // Double kick
    [1, 0, 0, 0, 1, 0, 1, 1],  // Fill pattern
    [1, 1, 0, 0, 1, 0, 0, 0],  // Fast double
    [1, 0, 0, 1, 1, 0, 0, 0],  // Syncopated
    [1, 0, 0, 0, 1, 1, 0, 0],  // Late snare feel
    [1, 0, 1, 0, 1, 1, 0, 0],  // Complex pattern
  ];

  var snarePatterns = [
    [0, 0, 0, 0, 1, 0, 0, 0],  // Basic snare on 3
    [0, 0, 1, 0, 1, 0, 0, 0],  // Early snare
    [0, 0, 0, 0, 1, 0, 1, 0],  // Double snare
    [0, 0, 1, 0, 1, 0, 1, 0],  // Complex snare
    [0, 1, 0, 0, 1, 0, 0, 0],  // Ghost note
    [0, 0, 0, 1, 1, 0, 0, 0],  // Syncopated
    [0, 0, 0, 0, 1, 1, 0, 1],  // Fill pattern
    [0, 1, 0, 1, 1, 0, 1, 0],  // Full pattern
  ];

  var hatPatterns = [
    [1, 0, 1, 0, 1, 0, 1, 0],  // Basic 8th notes
    [1, 1, 1, 0, 1, 1, 1, 0],  // 16th note feel
    [1, 1, 1, 1, 1, 1, 1, 1],  // All 8th notes
    [1, 0, 0, 1, 1, 0, 0, 1],  // Syncopated
    [1, 1, 0, 1, 1, 1, 0, 1],  // Busy pattern
    [0, 1, 0, 1, 0, 1, 0, 1],  // Off-beat focus
    [1, 0, 1, 1, 1, 0, 1, 0],  // Complex pattern
    [1, 1, 1, 1, 1, 1, 1, 0],  // Almost full
  ];

  var crashPatterns = [
    [1, 0, 0, 0, 0, 0, 0, 0],  // Crash on 1
    [1, 0, 0, 0, 1, 0, 0, 0],  // Crash on 1 and 3
    [0, 0, 0, 0, 0, 0, 0, 0],  // No crash
    [1, 0, 0, 0, 0, 0, 0, 1],  // Crash on 1 and 8
    [1, 0, 1, 0, 0, 0, 0, 0],  // Double crash
  ];

  var complexity = ~drumComplexity.(gradients.wrapAt(index), input[index]);
  var kickIndex = (input[index] % kickPatterns.size).asInteger;
  var snareIndex = ((input[index] + complexity) % snarePatterns.size).asInteger;
  var hatIndex = ((input[index] + complexity * 2) % hatPatterns.size).asInteger;
  var crashIndex = ((input[index] + complexity * 3) % crashPatterns.size).asInteger;

  [kickPatterns[kickIndex], snarePatterns[snareIndex],
    hatPatterns[hatIndex], crashPatterns[crashIndex]];
};

// Generate bass line (dubstep wobble)
~generateBass = {
  arg chord, input, gradients, index, baseOctave=0;
  var notes = [];
  var durations = [];
  var wobbleRate = input[index].linlin(0, 15, 2, 16);  // Wobble speed
  var subOctave = baseOctave - 1;
  var rootNote = chord[0] + (subOctave * 12);
  var fifthNote = rootNote + 7;
  var grad = gradients.wrapAt(index);
  var numNotes = grad.linlin(0, 1, 2, 8).round.asInteger;
  var patternLength = 16;  // 16 steps for dubstep

  // Create wobble bass pattern
  patternLength.do {
    arg step;
    var note, dur;
    var stepPos = step % 4;
    var wobblePhase = (step / wobbleRate) * 2pi;
    var wobbleAmount = (sin(wobblePhase) * 0.5 + 0.5).linlin(0, 1, 2, 5).floor;
    wobbleAmount.postln;

    // Classic dubstep bass rhythm
    case
    { stepPos == 0 } {  // Downbeat
      note = rootNote;
      dur = 1 * wobbleAmount;
    }
    { stepPos == 2 } {  // Backbeat
      note = fifthNote;
      dur = 2 * wobbleAmount;
    }
    { 0.3.coin } {  // Ghost notes
      note = rootNote + 12;
      dur = 4 * wobbleAmount;
    }
    {
      note = Rest(0);
      dur = 4;
    };

    notes = notes.add(note);
    durations = durations.add(dur);
  };

  [notes, durations];
};

// Generate melodic wobble (mid-range bass)
~generateMelodicWobble = {
  arg chord, input, gradients, index, baseOctave=0;
  var notes = [];
  var durations = [];
  var octave = baseOctave + 1;
  var grad = gradients.wrapAt(index);
  var complexity = ~drumComplexity.(grad, input[index]);
  var patternSteps = [8, 12, 16, 24][complexity-1];
  var root = chord[0] + (octave * 12);
  var third = chord[1] + (octave * 12);
  var fifth = chord[2] + (octave * 12);

  patternSteps.do {
    arg step;
    var note, dur;
    var patternPos = step % 4;
    var lfoPhase = (step / 4) * 2pi;
    var filterMod = sin(lfoPhase).linlin(-1, 1, 0.3, 0.9);

    case
    { patternPos == 0 } {
      note = root;
      dur = 1;
    }
    { patternPos == 2 } {
      note = fifth;
      dur = 1;
    }
    { 0.4.coin } {
      note = third;
      dur = 0.5;
    }
    {
      note = Rest(0);
      dur = 0.5;
    };

    notes = notes.add(note);
    // durations = durations.add(dur * (0.8 + (grad * 0.4)));
    durations = durations.add(dur);
  };

  [notes, durations];
};

// Generate classic dubstep melody (spacey, minimal)
~generateDubstepMelody = {
  arg chord, input, gradients, index, baseOctave=0;
  var notes = [];
  var durations = [];
  var octave = baseOctave + 2;
  var grad = gradients.wrapAt(index);
  var melodyLength = grad.linlin(0, 1, 4, 16).round.asInteger;
  var root = chord[0] + (octave * 12);
  var fifth = chord[2] + (octave * 12);
  var third = chord[1] + (octave * 12);
  var previousNote = root;

  melodyLength.do {
    arg step;
    var note, dur;
    var choice = input[index].linlin(0, 15, 0, 1);

    case
    { choice < 0.3 } {
      note = root;
      dur = 0.5;
    }
    { choice < 0.6 } {
      note = fifth;
      dur = 0.5;
    }
    { choice < 0.8 } {
      note = third;
      dur = 0.25;
    }
    {
      // Chromatic passing tone
      note = previousNote + [-2, 2, 3, 4].choose;
      dur = 0.125;
    };

    // Voice leading
    if ((note - previousNote).abs > 12) {
      note = previousNote + ((note - previousNote).sign * 7);
    };

    notes = notes.add(note);
    // durations = durations.add(dur * (1 - (grad * 0.3)));
    durations = durations.add(dur);
    previousNote = note;
  };

  [notes, durations];
};

// Generate MIDI CC patterns for dubstep effects
~generateDubstepCC = {
  arg input, gradients, index;
  var ccValues = [69, 70, 71, 72, 73];  // CC numbers for dubstep effects
  var patterns = [];
  var grad = gradients.wrapAt(index);
  var intensity = grad.linlin(0, 1, 0.2, 0.9);
  var wobbleSpeed = input[index].linlin(0, 15, 0.5, 8);

  // CC 69: Filter cutoff
  var filterPattern = (0..15).collect { arg step;
    var lfo = sin(step / wobbleSpeed * 2pi).linlin(-1, 1, 0.2, 0.9);
    (lfo * 127).asInteger;
  };

  // CC 70: Filter resonance
  var resonancePattern = (0..15).collect { arg step;
    var res = sin(step / (wobbleSpeed * 0.5) * 2pi).linlin(-1, 1, 0.3, 0.7);
    (res * 127).asInteger;
  };

  // CC 71: LFO rate
  var lfoRatePattern = (0..15).collect { arg step;
    var rate = (wobbleSpeed + (sin(step / 4) * 2)).clip(0.5, 12);
    (rate.linlin(0.5, 12, 0, 127)).asInteger;
  };

  // CC 72: Distortion amount
  var distortionPattern = (0..15).collect { arg step;
    var dist = intensity * (1 + sin(step / 2) * 0.5);
    (dist * 127).asInteger;
  };

  // CC 73: Delay feedback
  var delayPattern = (0..15).collect { arg step;
    var feedback = 0.3 + (intensity * 0.5) * (1 - cos(step / 4));
    (feedback * 127).asInteger;
  };

  [
    (cc69: filterPattern),
    (cc70: resonancePattern),
    (cc71: lfoRatePattern),
    (cc72: distortionPattern),
    (cc73: delayPattern)
  ];
};

// Main dubstep composition generator
~createDubstepComposition = {
  arg input;
  var analysis = ~analyzeAndMap.(input, ~notes);
  var chordIndices = analysis[0];
  var textures = analysis[1];
  var gradients = analysis[2];

  var drumKicks = [], drumSnares = [], drumHats = [], drumCrashes = [];
  var bassNotes = [], bassDurs = [];
  var wobbleNotes = [], wobbleDurs = [];
  var melodyNotes = [], melodyDurs = [];
  var ccPatterns = [];

  var kickDurs = [], snareDurs = [], hatDurs = [], crashDurs = [];
  var drumKickMIDI, drumSnareMIDI, drumHatMIDI, drumCrashMIDI;
  var allDrums, allDrumDurs;

  chordIndices.do {
    arg indices, i;
    var progIndex = indices[0];
    var chordIndex = indices[1];
    var chordNames = ~notes[progIndex][chordIndex];
    var currentChord = ~chordto_midi.(chordNames, 0);
    var texture = textures[i];
    var grad = if (i > 0) { gradients[i-1] } { 0 };

    // Generate drum patterns
    // var drums = ~generateDrumPattern.(input, gradients, i);

    var bass, wobble, melody, cc;
    drumKicks = drumKicks ++ ~generateKickPattern.(input, gradients, i);
    drumSnares = drumSnares ++ ~generateSnarePattern.(input, gradients, i);
    drumHats = drumHats ++ ~generateHihatPattern.(input, gradients, i);
    drumHats.postln;
    // drumCrashes = drumCrashes ++ drums[3];

    // Generate bass line
    bass = ~generateBass.(currentChord, input, gradients, i, -1);
    bassNotes = bassNotes ++ bass[0];
    bassDurs = bassDurs ++ bass[1];

    // Generate wobble bass
    wobble = ~generateMelodicWobble.(currentChord, input, gradients, i, 0);
    wobbleNotes = wobbleNotes ++ wobble[0];
    wobbleDurs = wobbleDurs ++ wobble[1];

    // Generate melody based on texture
    melody;
    switch(texture,
      \melodic_fast, {
        melody = ~generateDubstepMelody.(currentChord, input, gradients, i, 1);
      },
      \melodic, {
        melody = ~generateDubstepMelody.(currentChord, input, gradients, i, 1);
      },
      \melodic_long, {
        melody = ~generateDubstepMelody.(currentChord, input, gradients, i, 2);
      },
      \drone, {
        melody = ~generateDubstepMelody.(currentChord, input, gradients, i, 0);
      }
    );
    melodyNotes = melodyNotes ++ melody[0];
    melodyDurs = melodyDurs ++ melody[1];

    // Generate CC patterns
    cc = ~generateDubstepCC.(input, gradients, i);
    ccPatterns = ccPatterns ++ cc;

    // Create drum durations
    // drumKicks.size.do {
    //   arg j;
    //   kickDurs = kickDurs.add(0.25);
    //   snareDurs = snareDurs.add(0.25);
    //   hatDurs = hatDurs.add(0.25);
    //   // crashDurs = crashDurs.add(0.25);
    // };
  };

  drumKicks.postln;

  kickDurs = drumKicks.collect({arg val;var result;if(val == 1, {result = 0.25}, {result = Rest(0.25)});result});
  snareDurs = drumSnares.collect({arg val;var result;if(val == 1, {result = 0.25}, {result = Rest(0.25)});result});
  hatDurs = drumHats.collect({arg val;var result;if(val == 1, {result = 0.25}, {result = Rest(0.25)});result});

  // Convert drum patterns to MIDI notes (using specific MIDI notes for drum sounds)
  drumKickMIDI = [36]; // Kick on C1
  drumSnareMIDI = [36]; // Snare on D1
  drumHatMIDI = [36];    // Closed hat on F#1
  // drumKickMIDI = drumKicks.collect { |val| if(val == 1, 36, Rest(0)) };  // Kick on C1
  // drumSnareMIDI = drumSnares.collect { |val| if(val == 1, 38, Rest(0)) }; // Snare on D1
  // drumHatMIDI = drumHats.collect { |val| if(val == 1, 42, Rest(0)) };     // Closed hat on F#1
  // drumCrashMIDI = drumCrashes.collect { |val| if(val == 1, 49, Rest(0)) }; // Crash on C#2

  // // Combine drum parts
  // allDrums = [];
  // allDrumDurs = [];
  //
  // drumKickMIDI.size.do {
  //   arg i;
  //   allDrums = allDrums.add(drumKickMIDI[i]);
  //   allDrumDurs = allDrumDurs.add(kickDurs[i]);
  //   allDrums = allDrums.add(drumSnareMIDI[i]);
  //   allDrumDurs = allDrumDurs.add(snareDurs[i]);
  //   allDrums = allDrums.add(drumHatMIDI[i]);
  //   allDrumDurs = allDrumDurs.add(hatDurs[i]);
  //   // allDrums = allDrums.add(drumCrashMIDI[i]);
  //   // allDrumDurs = allDrumDurs.add(crashDurs[i]);
  // };

  [
    // [allDrums, allDrumDurs],
    [drumKickMIDI, kickDurs],
    [drumSnareMIDI, snareDurs],
    [drumHatMIDI, hatDurs],
    [bassNotes, bassDurs],
    [wobbleNotes, wobbleDurs],
    [melodyNotes, melodyDurs],
    ccPatterns
  ];
};

// Create and play the composition
~playDubstep = {
  arg input;
  var composition = ~createDubstepComposition.(input);

  "=== DUBSTEP COMPOSITION GENERATED ===".postln;
  // "Drums: % notes".format(composition[1][1]).postln;
  // "Drums: % notes".format(composition[2][1]).postln;
  // "Bass: % notes".format(composition[\bass][0].size).postln;
  // "Wobble: % notes".format(composition[\wobble][0].size).postln;
  // "Melody: % notes".format(composition[\melody][0].size).postln;
  // "CC Patterns: % patterns".format(composition[\cc].size).postln;

  // Create patterns using ~mmn and ~mmcc
  ~dubstepKick = ~mmn.(
    0, "kick",
    ~mpseq.(composition[0][0]), // notes
    ~mpseq.(composition[0][1]), // trigs
    ~mpseq.(Array.fill(composition[1][1].size, 100) // velocities
    )
  );
  ~dubstepSnare = ~mmn.(
    1, "snare",
    ~mpseq.(composition[1][0]), // notes
    ~mpseq.(composition[1][1]), // trigs
    ~mpseq.(Array.fill(composition[1][1].size, 100) // velocities
    )
  );
  ~dubstepHat = ~mmn.(
    2, "hh",
    ~mpseq.(composition[2][0]), // notes
    ~mpseq.(composition[2][1]), // trigs
    ~mpseq.(Array.fill(composition[2][1].size, 100) // velocities
    )
  );
  ~dubstepBass = ~mmn.(
    3, "bass",
    ~mpseq.(composition[3][0]),
    ~mpseq.(composition[3][1]),
    ~mpseq.(Array.fill(composition[1][1].size, 90))
  );

  ~dubstepWobble = ~mmn.(
    4, "wobble",
    ~mpseq.(composition[4][0]),
    ~mpseq.(composition[4][1]),
    ~mpseq.(Array.fill(composition[4][1].size, 85))
  );

  ~dubstepMelody = ~mmn.(
    5, "melody",
    ~mpseq.(composition[5][0]),
    ~mpseq.(composition[5][1]),
    ~mpseq.(Array.fill(composition[5][1].size, 80))
  );

  // Create CC patterns (simplified example)
  // composition[4].do { arg ccPattern, i;
  // 	var ccNum = [69, 70, 71, 72, 73][i % 5];
  // 	var values = ccPattern.asArray[ccNum.asSymbol];
  // 	if(values.notNil) {
  // 		("CC " ++ ccNum ++ " pattern generated").postln;
  // 		~mmcc.(13, "cc"++ccNum, ccNum, ~mpseq.(values), ~mpseq.(Array.fill(values.size, 0.125)));
  // 	};
  // };

  fork{
    2.wait;
    "Playing Dubstep Composition...".postln;
    ~dubstepKick.play(t);
    ~dubstepSnare.play(t);
    ~dubstepHat.play(t);
    ~dubstepBass.play(t);
    ~dubstepWobble.play(t);
    ~dubstepMelody.play(t);
  };
};

// Stop all dubstep patterns
~stopDubstep = {
  if(~dubstepKick.notNil) { ~dubstepKick.stop };
  if(~dubstepSnare.notNil) { ~dubstepSnare.stop };
  if(~dubstepHat.notNil) { ~dubstepHat.stop };
  if(~dubstepBass.notNil) { ~dubstepBass.stop };
  if(~dubstepWobble.notNil) { ~dubstepWobble.stop };
  if(~dubstepMelody.notNil) { ~dubstepMelody.stop };
  Pdef.removeAll;
  "Dubstep stopped".postln;
};

// Example usage
/*
~playDubstep.(~input);
~stopDubstep.();
*/
~playDubstep.(~input);
)

~input = [2, 11,  9,  9,  5,  7,  7, 10, 15,  15, 10, 10, 14, 12, 15,  9,  8, 14,   3,  1,  9,  4,  9, 13, 12, 11, 12,  10, 10, 14, 10,  8];

// Test with your input data
~stopDubstep.()