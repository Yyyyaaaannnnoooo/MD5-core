(
s.waitForBoot({

  thisProcess.openUDPPort(57120);
  thisProcess.openPorts;
  "loaded in supercollider".postln;

  MIDIClient.init;
  t = TempoClock.new(80/60).permanent_(true);
  // m = MIDIOut(0);
  // m = MIDIOut.newByName("IAC Driver", "Bus 1");

  ~instruments = [ "Violin", "Viola", "Cello"];

  ~midiToNote = {
    arg midi;
    var octave = (midi.asFloat / 12.0).round - 1;
    String.makeNoteName(name: midi, octave:octave);
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

  ~startup = {
    ~remote.sendMsg("/startup", "supercollider is ready!");
  };

  ~emit_composition = {
    arg txt;
    txt.postln;
    ~remote.sendMsg("/composition", txt);
  };
  ~emit_instrument = {
    arg txt;
    // txt.postln;
    ~remote.sendMsg("/instrument", txt);
  };


  d = Dictionary.newFrom([
    \C, 0,
    'C#', 1,
    \D, 2,
    'D#', 3,
    \Eb, 3,
    \E, 4,
    \F, 5,
    'F#', 6,
    \G, 7,
    'G#', 8,
    \Ab, 8,
    \A, 9,
    \Bb, 10,
    \B, 11,

  ]);

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



  ~convert = {
    arg string;
    d.at(string.asSymbol);
  };

  ~strings = [];
  ~choir = [];
  ~bass = [];
  ~score1 = [];
  ~trigs1 = [];
  ~score2 = [];
  ~trigs2 = [];
  ~score3 = [];
  ~trigs3 = [];
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
        ~choir.do({arg item; item.play})
      },
      2, {
        ~bass.do({arg item; item.stop})
      },
      3, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play})
      },
      4, {
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      5, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play})
      },
      6, {
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      7, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      8, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      9, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      10, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      11, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
      12, {
        ~strings.do({arg item; item.play});
        ~choir.do({arg item; item.play});
        ~bass.do({arg item; item.play})
      },
    );
  };

  // STOP
  ~stop = {
    // Pdef.removeAll;
    ~strings.do({arg item; item.stop});
    ~choir.do({arg item; item.stop});
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
  //
  // ~mpdef = {
  //   arg channel, name=nil, patN, patD, patV;
  //   var pat_name = "string"++channel++name.asString;
  //   var bus = ~outs[channel];
  //   pat_name = pat_name.asSymbol;
  //   Pdef(pat_name).clear;
  //   Pdef(pat_name, Pbind(
  //     \instrument,\saw,\group, ~synths,
  //     \midi_note, patN,
  //     \dur, patD,
  //     \amp, patV, // velocity
  //     \out, bus,
  //   ));
  //   Pdef(pat_name).quant_(1);
  //   Pdef(pat_name).fadeTime = 1.0;
  // };
  //

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
      \out, bus,
      \trace, Pfunc({
        arg ev;
        var midi = ~midiToNote.(ev[\midi_note]);
        var inst = ~instruments[channel];
        if(ev[\dur].asString.contains("Rest").postln == true)
        {
          (inst ++ "  " ++ midi).postln;
          ev[\dur].postln;

        }{
          // ~emit_composition.("~~~~~~~~~~~~~~~~~~~~~~~");
          // ~emit_composition.((inst ++ " >>> " ++ midi));
          ~emit_instrument.((inst ++ " >>> " ++ midi));
          // ~emit_composition.(("duration >>> " ++ ev[\dur].asString));
        }

      }),
    ));
    Pdef(pat_name).quant_(1);
    Pdef(pat_name).fadeTime = 1.0;
  };


  ~make_ptn = {
    arg ch, notes, trigs, list;
    var n1 = notes[0], n2 = notes[1], n3 = notes[2];
    var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];
    var v1 = list[(0..9)], v2 = list[(10..19)], v3 = list[(20..29)];
    var chordOrNote = list[30]>7.5;
    var p1, p2=nil, p3=nil, ret;

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

  ~make_score = {
    // dura s deprecated
    arg list, dura;
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
    // ~emit_composition.("~~~ "++chord++" ~~~");
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
        msg.postln;
        // ~emit_composition.(msg);
        (0.125 * 0.5).wait;
      })
    }.fork;

    score = [n1, n2, n3];
    trigs = [t1, t2, t3];
    [score, trigs];
  };

  ~make_scores = {
    // dura s deprecated
    arg list, dura;
    var score = ~make_score.(list, dura);
    var bend = 127;
    var arp1 = if(list[15] > 7, bend, 0);
    var arp2 = if(list[16] > 7, bend, 0);
    var mutes = list[17].linlin(0, 15, 0, 12).floor.asInteger;
    var vol1 = list[18].linlin(0, 15, 0,10).floor.asInteger;
    var vol2 = list[19].linlin(0, 15, 0,10).floor.asInteger;
    var vol3 = list[20].linlin(0, 15, 0,10).floor.asInteger;
    var long1 = list[21].linexp(0, 15, 1,6).floor.asInteger;
    var long2 = list[22].linexp(0, 15, 1,6).floor.asInteger;
    var long3 = list[23].linexp(0, 15, 1,6).floor.asInteger;
    // if(arp1 == bend && arp2 == bend, arp2 = 0);

    // from 15 onwards to make following changes
    // this can be used to turn on or off arpeggio
    // arpeggio only strings and choir 15&16
    // m.control(chan, ctlNum: 7, val: 64)
    // from 17 onwards to choose which channel are played:
    // 18 onwards to choose note length


    ~score1 = score[0];
    ~trigs1 = score[1];


    ~trigs1 = ~trigs1.collect({arg item, i;item = ~longer.(long1, item)});
    ~score2 = score[0];
    ~trigs2 = score[1];
    ~trigs2 = ~trigs2.collect({arg item, i;item = ~longer.(long2, item)});
    ~score3 = score[0];
    ~trigs3 = score[1];
    ~trigs3 = ~trigs3.collect({arg item, i;item = ~longer.(long3, item)});

    // HeRE WE COULD ROTATE THE score for each instrument
    // and add
    /*~strings = ~make_midi_ptn.(0, ~score1, ~trigs1, list);
    ~choir   = ~make_midi_ptn.(1, ~score2, ~trigs2, list.rotate(2));
    ~bass    = ~make_midi_ptn.(2, ~score3, ~trigs3, list.rotate(4));
    */

    // not midi
    ~strings = ~make_ptn.(0, ~score1 + (12 + (2.rand * 12)), ~trigs1, list);
    ~choir   = ~make_ptn.(1, ~score2, ~trigs2, list.rotate(2));
    ~bass    = ~make_ptn.(2, ~score3 - 24, ~trigs3, list.rotate(4));

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

  "init".postln;

  ~init.();

  "build synths".postln;

  SynthDef(\saw, {
    arg midi_note=55, dur=1, out=0, atk, rel;
    var sig, env, detune;
    detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
    sig = LFSaw.ar(midi_note.midicps * detune);
    // sig = LFSaw.ar(midi_note.midicps);
    sig = Mix.ar(sig);
    sig = CombC.ar(sig, 0.5, 0.1, 0.5);
    env = EnvGen.kr(
      envelope: Env.adsr(
        1.5 + 0.25.rand2,
        0.125 + 0.01.rand2,
        0.75 + 0.1.rand2,
        1.25 + 0.25.rand2,
        curve:[2, -4, 2]),
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
    sig3 = Balance2.ar(sig3[0], sig3[1], \pan.kr(0));
    sig3 = sig3 * \amp3.kr(0.dbamp, 0.5);

    snd = sig1+sig2+sig3;

    Out.ar(\aux.kr(~bus1), snd * \send.kr(1, 0.5).clip(0,1));
    Out.ar(0, snd * \mute.kr(1).clip(0, 1));
  }).add;
  /*
  SynthDef(\reverb, {
  arg inbus=~bus1, out=0;
  var input, sig;
  input = In.ar(inbus, 2);
  sig = MiVerb.ar(input,
  \tail.kr(0.999), 1,
  \damp.kr(0), \hp.kr(0.3),
  \freeze.kr(0), \diff.kr(0.625));
  Out.ar(out, sig);
  }).add;*/

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

  s.sync;

  OSCdef(
    key: \image,
    func: {
      arg msg, time, addr, recvPort;
      var ch = 0;
      msg.postln;
      msg.removeAt(0);
      // ch = msg.removeAt(0).postln;

      "~~~ New Composition ~~~".postln;
      ~stop.();
      ~make_scores.(msg, 5)
    },
    path: '/md5');

  OSCdef(
    key: \panic,
    func: {
      arg msg, time, addr, recvPort;
      var ch = 0;
      // msg.postln;
      // msg.removeAt(0).postln;
      // PANIC MODE!!!
      "~~~ PANIC MODE! ~~~".postln;
      ~emit_composition.("~~~ PANIC MODE! ~~~");
      Pdef.removeAll;
    },
    path: '/panic');


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
  /*
  ~reverb = Synth(\reverb2,[
  \inbus, ~bus1,
  \tail, 0.97,
  \damp, 0.1,
  \hp, 0.3
  ],
  target:~fx);
  */
  // ~reverb = Synth(\reverb2,[\inbus, ~bus1],target:~fx);
  ~reverb = Synth(\reverb3,[\inbus, ~bus1,\size, 200,\spread, 15],target:~fx);

  // ~startup.();

  // {
  //   ~getmd5.("What if I could do something else, what could I do?");
  //   10.wait;
  //   ~getmd5.("who am I? A dead algorithm?");
  //   10.wait;
  //   ~getmd5.("Ciao md5, your hashes never met the ocean, yet your name bestows a library.");
  //   10.wait;
  //   ~getmd5.("That rock with your name");
  //   10.wait;
  //   ~getmd5.("Stifle seagulls still flap their wings");
  //   10.wait;
  // }.fork
});

)