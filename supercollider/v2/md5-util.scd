(
s.waitForBoot({
  // Server.default.options.outDevice_("AudioBox USB 96");
  MIDIClient.init;
  t = TempoClock.new(80/60).permanent_(true);
  m = MIDIOut(0);
  m = MIDIOut.newByName("IAC Driver", "Bus 1");

  ~instruments = [ "Violin", "Viola", "Cello"];

  ~midiToNote = {
    arg midi;
    var result = "";
    // midi.postln;
    // "is array: ".post; midi.isArray.postln;
    if(midi.isArray)
    {
      midi.do({
        arg note, i;
        var octave = (note.asFloat / 12.0).round - 1;
        var note_name = String.makeNoteName(name: note, octave:octave);
        // note.postln;
        // note_name.postln;
        result = result + note_name;
      });
    }
    {
      var octave = (midi.asFloat / 12.0).round - 1;
      result = String.makeNoteName(name: midi, octave:octave);
    };
    result
  };

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

  ~remote = NetAddr("127.0.0.1", 57121);

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
    // txt.postln;
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
  // ~offset.();
  ~mRest = {arg time; Rest(time)};


  ~play = {
    arg mutes;
    "play".postln;
    mutes.postln;
    // x o o
    // o x o
    // o o x
    // x x o
    // x o x
    // x x x
    switch(
      mutes,
      0, {
        // "play strings".postln;
        ~strings.do({arg item; item.play})
      },
      1, {
        ~viola.do({arg item; item.play})
      },
      2, {
        ~bass.do({arg item; item.stop})
      },
      3, {
        ~strings.do({arg item; item.play});
        ~viola.do({arg item; item.play})
      },
      4, {
        ~viola.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      5, {
        ~strings.do({arg item; item.play});
        ~bass.do({arg item; item.play});
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
    // trigs.postln;
    trigs;
  };

  ~mpseq = {arg list;  Pseq(list, inf)};

  // MAKE MIDI pattern
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

  ~make_midi_ptn = {
    arg ch, notes, trigs, list;
    var n1 = notes[0], n2 = notes[1], n3 = notes[2];
    var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];
    var v1 = list[(0..9)], v2 = list[(10..19)], v3 = list[(20..29)];
    var p1, p2, p3, ret;
    v1 = ~make_velocities.(v1);
    v2 = ~make_velocities.(v2);
    v3 = ~make_velocities.(v3);

    p1 = ~mmn.(ch, "p1", ~mpseq.(n1), ~mpseq.(t1), ~mpseq.(v1));
    p2 = ~mmn.(ch, "p2", ~mpseq.(n2), ~mpseq.(t2), ~mpseq.(v2));
    p3 = ~mmn.(ch, "p3", ~mpseq.(n3), ~mpseq.(t3), ~mpseq.(v3));
    [p1, p2, p3]
  };
  // Patterns for Sc SynthDefs
  ~mpdef = {
    arg channel, name=nil, patN, patD, patV;
    var pat_name = "string"++channel++name.asString;
    var bus = ~outs[channel];
    pat_name = pat_name.asSymbol;
    pat_name.postln;
    Pdef(pat_name).clear;
    Pdef(pat_name, Pbind(
      \instrument,\saw,\group, ~synths,
      \midi_note, patN,
      \dur, patD,
      \amp, patV, // velocity
      \legato, Pfunc({
        arg event;
        var r = 1.5;
        if(event.dur > 4){r = 1};
        // r.postln;
        r
      }),
      \a, Pfunc({
        arg event;
        var r=1.5;
        if(event.dur < 1.5){r = event.dur - (event.dur*0.3333)  };
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
        if(event.dur > 4){r = 2};
        // r.postln;
        r
      }),
      \out, bus,
      \trace, Pfunc({
        arg ev;
        var midi = ~midiToNote.(ev[\midi_note]);
        var inst = ~instruments[channel];
        if(ev[\dur].asString.contains("Rest") == false)
        {

          ~emit_composition.("~~~~~~~~~~~~~~~~~~~~~~~");
          ~emit_composition.((inst ++ " >>> " ++ midi));
          ~emit_composition.(("duration >>> " ++ ev[\dur].asString));
        }{
          ~emit_composition.("~~~~~~~~~~~~~~~~~~~~~~~");
          "REST".postln;
          // never ever remove the else statement from trace it fails the pdef silently!!!!
        }

      }),
    ));
    Pdef(pat_name).quant_(1);
    Pdef(pat_name).fadeTime = 1.0;
  };


  // DEPRECATED from v1
  ~make_chord_ptn = {
    arg ch, notes, trigs, list;
    var n1 = notes[0], n2 = notes[1], n3 = notes[2];
    var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];
    var v1 = list[(0..9)], v2 = list[(10..19)], v3 = list[(20..29)];
    var chordOrNote = list[30]>7.5;
    var p1=nil, p2=nil, p3=nil, ret;

    v1 = ~make_velocities.(v1).linlin(0.8, 1, -40.dbamp, -30.dbamp);
    v2 = ~make_velocities.(v2).linlin(0.8, 1, -40.dbamp, -30.dbamp);
    v3 = ~make_velocities.(v3).linlin(0.8, 1, -40.dbamp, -30.dbamp);
    // choose whether single or chord
    // "Chord Or Note?".postln;
    // list[30].postln;
    // chordOrNote.postln;
    if(chordOrNote)
    {
      p1 = ~mpdef.(ch, "p1", ~mpseq.(n1), ~mpseq.(t1), ~mpseq.(v1));
      p2 = ~mpdef.(ch, "p2", ~mpseq.(n2), ~mpseq.(t2), ~mpseq.(v2));
      p3 = ~mpdef.(ch, "p3", ~mpseq.(n3), ~mpseq.(t3), ~mpseq.(v3));

    }

    {
      p1 = ~mpdef.(ch, "p1", ~mpseq.(n1), ~mpseq.(t1), ~mpseq.(v1));

    };
    [p1,p2,p3]
  };
  // DEPRECATED from v1
  ~make_mono_ptn = {
    arg ch, notes, trigs, list;
    var n1 = notes[0], n2 = notes[1], n3 = notes[2];
    var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];
    var v1 = list[(0..9)];
    var p1=nil, p2=nil, p3=nil;

    v1 = ~make_velocities.(v1).linlin(0.8, 1, -40.dbamp, -30.dbamp);
    p1 = ~mpdef.(ch, "p1", ~mpseq.(notes), ~mpseq.(trigs), ~mpseq.(v1));
    [p1,p2,p3]
  };


  // DEPRECATED from v1
  ~make_score = {
    arg list;
    var n1 = [], n2 = [], n3 = [];
    var t1 = [], t2 = [], t3 = [];
    var durs = list[[1,2,3,4]].linlin(0,15,5,10);
    var root = list[5].linlin(0, 15, 0, 3).floor.asInteger;
    var melody = list[0].linlin(0, 15, 0, 6).floor.asInteger;
    // OFFSETS to give more movement to notes
    var off1 = list[(6..8)].linlin(0,15,0,0.25);
    var off2 = list[(9..11)].linlin(0,15,0,0.25);
    var off3 = list[(12..14)].linlin(0,15,0.15,0.75);
    var rests = list[[24, 25, 26]].linlin(0,15, 5, 15);
    var score, trigs;
    var chord = ~chord_names[melody];
    var composition = [];
    chord.postln;
    ~emit_composition.("~~~ "++chord++" ~~~");
    "melody".postln;
    melody.postln;
    ~notes[melody].postln;
    32.do({
      arg item, i;
      var dur = durs.choose;
      var rest = rests.choose;
      var n = ~notes[melody];
      var number_of_chords = n.size;
      var md5_val = list[i];
      var chord_to_play = md5_val.linlin(0, 15, 0, number_of_chords - 1).floor.asInteger;

      n = ~notes[melody][chord_to_play];

      // for visualization!
      composition = composition.add(n);
      t1 = t1.add(~mRest.(off1[0]));
      n1 = n1.add((~convert.(n[0]) + 60));

      t2 = t2.add(~mRest.(off1[1]));
      n2 = n2.add((~convert.(n[1]) + 60));

      t3 = t3.add(~mRest.(off1[2]));
      n3 = n3.add((~convert.(n[2]) + 60));

      t1 = t1.add(dur);
      t2 = t2.add(dur);
      t3 = t3.add(dur);

      t1 = t1.add(~mRest.(off2[0]));
      t2 = t2.add(~mRest.(off2[1]));
      t3 = t3.add(~mRest.(off2[2]));

      t1 = t1.add(~mRest.(rest));
      t2 = t2.add(~mRest.(rest));
      t3 = t3.add(~mRest.(rest));
    });

    {
      composition.do({
        arg item, i;
        var msg = i.asString()++": "++ item.asString();
        // uncomment below!
        // msg.postln;
        // ~emit_composition.(msg);
        (0.125 * 0.5).wait;
      })
    }.fork;

    score = [n1, n2, n3];
    trigs = [t1, t2, t3];
    [score, trigs];
  };
  // DEPRECATED from v1
  ~make_scores = {
    arg list;
    var score = ~make_score.(list);
    var bend = 0.125;
    var arp1 = if(list[15] > 7, bend, 1);
    var arp2 = if(list[16] > 7, bend, 1);
    var mutes = list[17].linlin(0, 15, 0, 9).floor.asInteger;
    var vol1 = list[18].linlin(0, 15, 0,10).floor.asInteger;
    var vol2 = list[19].linlin(0, 15, 0,10).floor.asInteger;
    var vol3 = list[20].linlin(0, 15, 0,10).floor.asInteger;
    var long1 = list[21].linexp(0, 15, 1,6).floor.asInteger;
    var long2 = list[22].linexp(0, 15, 1,6).floor.asInteger;
    var long3 = list[23].linexp(0, 15, 1,6).floor.asInteger;
    var violin_score = ~make_violin_score.(list);
    "LLLLIIISSSTTT".postln;
    list.postln;

    // if(arp1 == bend && arp2 == bend, arp2 = 0);

    // from 15 onwards to make following changes
    // this can be used to turn on or off arpeggio
    // arpeggio only strings and choir 15&16
    // m.control(chan, ctlNum: 7, val: 64)
    // from 17 onwards to choose which channel are played:
    // 18 onwards to choose note length


    ~score1 = score[0];
    ~trigs1 = score[1];
    ~trigs1 = ~trigs1.collect({arg item,i;item = ~longer.(long1, item)});

    ~score2 = score[0];
    ~trigs2 = score[1];
    ~trigs2 = ~trigs2.collect({arg item,i;item = ~longer.(long2, item)});

    ~score3 = score[0];
    ~trigs3 = score[1];
    ~trigs3 = ~trigs3.collect({arg item,i;item = ~longer.(long3, item)});

    // testing new arrangement tool

    ~score1 = violin_score[0].postln;
    ~trigs1 = violin_score[1].postln;

    // HeRE WE COULD ROTATE THE score for each instrument
    // and add
    /*~strings = ~make_midi_ptn.(0, ~score1, ~trigs1, list);
    ~viola   = ~make_midi_ptn.(1, ~score2, ~trigs2, list.rotate(2));
    ~bass    = ~make_midi_ptn.(2, ~score3, ~trigs3, list.rotate(4));
    */

    // not midi
    // ~strings = ~make_chord_ptn.(0, ~score1 + (12 + (2.rand * 12)), ~trigs1, list);
    // ~strings = ~make_chord_ptn.(0, ~score1, ~trigs1, list);
    ~strings = ~make_mono_ptn.(0, ~score1, ~trigs1, list);
    ~viola   = ~make_chord_ptn.(1, ~score2, ~trigs2, list.rotate(2));
    ~bass    = ~make_chord_ptn.(2, ~score3 - 24, ~trigs3, list.rotate(4));

    fork{
      ~stop.();
      6.wait;
      "~~~ Execute Composition ~~~".postln;
      // m.control(1, 1, arp2);
      ~emit.("~~~ Composition is Playing ~~~");
      // ~emit_composition.(~score1.asString());
      ~play.(mutes);
    };
  };



  // new score gen
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
      var rest = input[i].linlin(0, 15, 2, 12);
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
          // durations = durations ++ melody[1];
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
          // durations = durations ++ melody[1];
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
          // durations = durations ++ melody[1];
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
          // durations = durations ++ drone[1];
        }
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
    arg input;
    var violin_score = ~generateFromContour.(input, ~notes, 1, 1);
    var viola_score = ~generateFromContour.(input.rotate(2), ~notes, 0, 1);
    var bass_score = ~generateFromContour.(input.rotate(4), ~notes, -1, 4);
    var midiNotes = violin_score[0];
    var durations = violin_score[1];
    var trigs1=[], trigs2=[], trigs3=[];
    var mutes = input[17].linlin(0, 15, 0, 9).floor.asInteger;
    var long1 = input[21].linexp(0, 15, 1,3).floor.asInteger;
    var long2 = input[22].linexp(0, 15, 1,3).floor.asInteger;
    var long3 = input[23].linexp(0, 15, 1,2).floor.asInteger;

    "make composition".postln;

    // Visualize
    // ~visualizeMapping.(~input, ~notes);

    "\n=== GENERATED COMPOSITION ===".postln;
    "Total notes: %".format(midiNotes.size).postln;
    "Total duration: % seconds".format(durations.sum.round(0.01)).postln;

    trigs1 = violin_score[1].collect({arg item,i;item = ~longer.(long1, item)});
    trigs2 = viola_score[1].collect({arg item,i;item = ~longer.(long2, item)});
    // trigs3 = bass_score[1].collect({arg item,i;item = ~longer.(long3, item)});
    trigs3 = bass_score[1];

    ~strings = ~make_ptn2.(0, violin_score[0], trigs1, ~input);
    ~viola = ~make_ptn2.(1, viola_score[0], trigs2, ~input.rotate(2));
    ~bass = ~make_ptn2.(2, bass_score[0], trigs3, ~input.rotate(4));
    // ~strings = ~make_mono_ptn.(0, ~score1, ~trigs1, list);
    // ~viola   = ~make_chord_ptn.(1, ~score2, ~trigs2, list.rotate(2));
    // ~bass    = ~make_chord_ptn.(2, ~score3 - 24, ~trigs3, list.rotate(4));

    fork{
      ~stop.();
      6.wait;
      "~~~ Execute Composition ~~~".postln;
      // m.control(1, 1, arp2);
      ~emit.("~~~ Composition is Playing ~~~");
      // ~emit_composition.(~score1.asString());
      ~play.(mutes);
    };

  };


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

  // ~init.();

  SynthDef(\saw, {
    arg midi_note=55, dur=1, out=0,offset=0.0,a=1.5, d=0.125, s=0.75, r=1.25, vibRate=5.5, vibDepth=0.005;
    var sig, env, detune, freq=midi_note.midicps;
    var vibrato = SinOsc.kr(vibRate) * vibDepth * freq;
    detune = LFNoise1.kr(0.2!6).bipolar(0.2).midiratio;
    sig = LFSaw.ar((midi_note.midicps + vibrato) * detune);
    // sig = LFSaw.ar(midi_note.midicps);
    sig = Mix.ar(sig);
    sig = CombC.ar(sig, 0.5, 0.1, 0.5);
    /*    sig = sig + CombC.ar(
    in: WhiteNoise.ar(),
    maxdelaytime: 10.reciprocal,
    delaytime: (midi_note.midicps).reciprocal,
    decaytime:0.125
    );*/
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

  SynthDef(\reverb, {
    arg inbus=~bus1, out=0;
    var input, sig;
    input = In.ar(inbus, 2);
    sig = MiVerb.ar(input,
      \tail.kr(0.999), 1,
      \damp.kr(0), \hp.kr(0.3),
      \freeze.kr(0), \diff.kr(0.625));
    Out.ar(out, sig);
  }).add;

  SynthDef(\reverb2, {
    arg inbus=~bus1, out=0;
    var input, sig;
    input = In.ar(inbus, 2);
    sig = FreeVerb2.ar(
      input[0], input[1], 1,
      \room.kr(0.75),
      \damp.kr(0));
    Out.ar(out, sig);
  }).add;

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


});

)

Pdef.debug