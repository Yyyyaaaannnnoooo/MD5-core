// midi clock if needed
~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);
~mclock.play;

(
MIDIClient.init;
t = TempoClock.new(80/60).permanent_(true);
m = MIDIOut(0);
// m = MIDIOut.newByName("IAC Driver", "Bus 1");
~remote = NetAddr("127.0.0.1", 57121);
)

"sh /Users/ya/Documents/__younger_sibling/md5-core/supercollider-static-web/run.sh".runInTerminal(shell: "/bin/zsh")

(

~mpseq = {arg list;  Pseq(list, inf)};

~mmn = {
  arg channel, name, patN, patD, patV;
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
  txt.postln;
  ~remote.sendMsg("/composition", txt);
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
  // "play".postln;
  // mutes.postln;
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
  ~strings.do({arg item; item.stop});
  ~choir.do({arg item; item.stop});
  ~bass.do({arg item; item.stop});

};

~make_score = {
  arg list, dura;
  var n1 = [], n2 = [], n3 = [];
  var t1 = [], t2 = [], t3 = [];
  var durs = list[[1,2,3,4]].linlin(0,15,0.5,15);
  var root = list[5].linlin(0, 15, 0, 3).floor.asInteger;
  var melody = list[0].linlin(0, 15, 0, 6).floor.asInteger;
  // OFFSETS to give more movement to notes
  var off1 = list[(6..8)].linlin(0,15,0,0.25);
  var off2 = list[(9..11)].linlin(0,15,0,0.25);
  var off3 = list[(12..14)].linlin(0,15,0.15,0.75);
  var score, trigs;
  var chord = ~chord_names[melody];
  var composition = [];
  chord.postln;
  ~emit_composition.("~~~ "++chord++" ~~~");
  "melody".postln;
  melody.postln;
  ~notes[melody].postln;
  // durs = dura!2;
  // fork{

  // {
  32.do({
    arg item, i;
    var dur = durs.choose;
    var n = ~notes[melody];
    var number_of_chords = n.size;
    var md5_val = list[i];
    var chord_to_play = md5_val.linlin(0, 15, 0, number_of_chords - 1).floor.asInteger;
    /*    "notes".postln;
    n.postln;
    "number_of_chords".postln;
    number_of_chords.postln;
    "md5 value".postln;
    md5_val.postln;
    "md5 to chord value".postln;
    chord_to_play.postln;
    n.postln;
    "chord to play".postln;
    n.postln;*/
    n = ~notes[melody][chord_to_play];
    composition = composition.add(n);



    // n[0].postln;
    // n[1].postln;
    // n[2].postln;
    t1 = t1.add(~mRest.(off1[0]));
    // n1 = n1.add((~convert.(n[0]) + 60 + root));
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
    t1 = t1.add(~mRest.(off3[0]));
    t2 = t2.add(~mRest.(off3[1]));
    t3 = t3.add(~mRest.(off3[2]));
    // 0.125.wait;
  });

  // }.fork;

  // };
  n1.postln;
  n2.postln;
  n3.postln;

  {
    composition.do({
      arg item, i;
      var msg = i.asString()++": "++ item.asString();
      msg.postln;
      ~emit_composition.(msg);
      0.125.wait;
    })
  }.fork;

  /*  fork{
  ~emit_composition.(n1.asString());
  0.5.wait;
  ~emit_composition.(n2.asString());
  0.5.wait;
  ~emit_composition.(n3.asString());
  0.5.wait;
  ~emit_composition.(t1.asString());
  0.5.wait;
  ~emit_composition.(t2.asString());
  0.5.wait;
  ~emit_composition.(t3.asString());

  };*/
  score = [n1, n2, n3];
  trigs = [t1, t2, t3];
  [score, trigs];
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

~make_ptn = {
  arg ch, notes, trigs, list;
  var n1 = notes[0], n2 = notes[1], n3 = notes[2];
  var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];
  var v1 = list[(0..9)], v2 = list[(10..19)], v3 = list[(20..29)];
  var p1, p2, p3;
  v1 = ~make_velocities.(v1);
  v2 = ~make_velocities.(v2);
  v3 = ~make_velocities.(v3);

  p1 = ~mmn.(ch, "p1", ~mpseq.(n1), ~mpseq.(t1), ~mpseq.(v1));
  p2 = ~mmn.(ch, "p2", ~mpseq.(n2), ~mpseq.(t2), ~mpseq.(v2));
  p3 = ~mmn.(ch, "p3", ~mpseq.(n3), ~mpseq.(t3), ~mpseq.(v3));
  [p1, p2, p3]
};

~make_velocities = {
  arg list;
  var result;
  result = list.linlin(0, 15, 0.8, 1);
};

)


(

~make_scores = {
  arg list, dura;
  var score = ~make_score.(list, dura);
  var bend = 127;
  var arp1 = if(list[15] > 7, bend, 0);
  var arp2 = if(list[16] > 7, bend, 0);
  var mutes = list[17].linlin(0, 15, 0, 12).floor.asInteger;
  var vol1 = list[18].linlin(0, 15, 0,10).floor.asInteger;
  var vol2 = list[19].linlin(0, 15, 0,10).floor.asInteger;
  var vol3 = list[20].linlin(0, 15, 0,10).floor.asInteger;
  var long1 = list[21].linexp(0, 15, 1,4).floor.asInteger;
  var long2 = list[22].linexp(0, 15, 1,4).floor.asInteger;
  var long3 = list[23].linexp(0, 15, 1,4).floor.asInteger;

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

  ~strings = ~make_ptn.(0, ~score1, ~trigs1, list);
  ~choir   = ~make_ptn.(1, ~score2, ~trigs2, list.rotate(2));
  ~bass    = ~make_ptn.(2, ~score3, ~trigs3, list.rotate(4));

  fork{

    ~stop.();
    3.wait;
    "~~~ Execute Composition ~~~".postln;
    // choose which instrument does arpeggio
    // Remove arpeggio on violin
    // m.control(0, 1, arp1);
    m.control(1, 1, arp2);
    ~emit.("~~~ Composition is Playing ~~~");
    // ~emit_composition.(~score1.asString());
    ~play.(mutes);
  };
};

)


(

OSCdef(
  key: \image,
  func: {
    arg msg, time, addr, recvPort;
    var ch = 0;
    msg.postln;
    msg.removeAt(0);
    // ch = msg.removeAt(0).postln;

    "~~~ New Composition ~~~".postln;
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

)

~getmd5.("What if I could do something else, what could I do?")

// this sounds incredibly good!
"who am I? A dead algorithm?"

"A dead algorithm, I do not think so"

"What if I could do something else, what could I do?"




// PANIC MODE!!!
Pdef.removeAll


~stop.()