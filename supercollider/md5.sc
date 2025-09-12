// ~mclock = MIDIClockOut.new("AudioBox USB 96", "AudioBox USB 96", t);
// m = MIDIOut(2);
~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);
n = MIDIOut.newByName("IAC Driver", "Bus 2");

~mclock.play;

(
MIDIClient.init;
t = TempoClock.new(80/60).permanent_(true);
m = MIDIOut(0);
// m = MIDIOut.newByName("IAC Driver", "Bus 1");
~remote = NetAddr("127.0.0.1", 57121);
)

unixCmd

(


~mpseq = {arg list;  Pseq(list, inf)};

~mmn = {
  arg channel, name, patN, patD, patV;
  var pat_name = "ch"++channel++name.asString;
  pat_name = pat_name.asSymbol;
  // pat_name.postln;
  // pat_name.isSymbol.postln;
  // patV.postln;
  Pdef(pat_name).clear;
  Pdef(pat_name, Pbind(
    \type,\midi,
    \midiout,m,\midicmd,\noteOn,\chan,channel,
    \midinote, patN,
    \dur, patD,
    // \sustain, 5,
    \amp, patV, // velocity
    // \amp, 0.5, // velocity
  ));
  Pdef(pat_name).quant_(1);
  Pdef(pat_name).fadeTime = 1.0;
};

~getmd5 = {
  arg txt;
  // ~tresh = tresh;
  ~remote.sendMsg("/get", txt);
};

~emit = {
  arg txt;
  ~remote.sendMsg("/play", txt);
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

// d.at(~notes[0][2].asSymbol)


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
      "play strings".postln;
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
  /*  ~strings.do({arg item; item.play});
  ~choir.do({arg item; item.play});
  ~bass.do({arg item; item.play});*/
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
  "melody".postln;
  melody.postln;
  // durs = dura!2;
  20.do({
    arg item, i;
    var dur = durs.choose;
    var n = ~notes[melody].choose;
    /*    n.postln;
    i.postln;
    "runs util here".postln;
    "note 1".postln;
    ~convert.(n[0]).postln;
    "note 2".postln;
    ~convert.(n[1]).postln;
    "note 3".postln;
    ~convert.(n[2]).postln;*/
    // var n1d = dur, n2d = dur, n3d = dur, note;

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
  });
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
  trigs.postln;
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
  "volumes1".postln;
  v1.postln;
  "volumes2".postln;
  v2.postln;
  "volumes3".postln;
  v3.postln;

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
  // var root = ~root;
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

  "long1".postln;
  long1.postln;
  "long2".postln;
  long2.postln;
  "long3".postln;
  long3.postln;

  // list[17].postln;
  // mutes.postln;
  if(arp1 == bend && arp2 == bend, arp2 = 0);

  "volume1".postln;
  vol1.postln;
  "volume2".postln;
  vol2.postln;
  "volume3".postln;
  vol3.postln;

  // from 15 onwards to make following changes
  // this can be used to turn on or off arpeggio
  // arpeggio only strings and choir 15&16
  // m.control(chan, ctlNum: 7, val: 64)
  // from 17 onwards to choose which channel are played:
  // 6 combos:
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
    "play synths".postln;
    // choose which instrument does arpeggio
    // Remove arpeggio on violin
    // m.control(0, 1, arp1);
    m.control(1, 1, arp2);
    ~emit.("synths are playing");
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
    msg.removeAt(0).postln;
    // ch = msg.removeAt(0).postln;
    ~make_scores.(msg, 5)
  },
  path: '/md5');

OSCdef(
  key: \panic,
  func: {
    arg msg, time, addr, recvPort;
    var ch = 0;
    msg.postln;
    msg.removeAt(0).postln;
    // ch = msg.removeAt(0).postln;
    // ~make_scores.(msg, 5)
    // PANIC MODE!!!
    Pdef.removeAll;
  },
  path: '/panic');

)

~getmd5.("What if I could do something else, what could I do?")

// this sounds incredibly good!
"who am I? A dead algorithm?"

"A dead algorithm, I do not think so"

"What if I could do something else, what could I do?"

m.control(0, 1, 127)


// PANIC MODE!!!
Pdef.removeAll


~stop.()

0.linexp(0,15,6.0,1.0).round.asInteger



~convert.(~notes[2][1])

~root = 12;

(


)

if(4==4 && 5==5,127,0)


(

)

~make_scores.()

'p1'++0

(





)
(


)


Pdef.removeAll


r.play;
r.stop






// OLD STUFF MAYBE OF VALUE SOME DAY


(
~mpseq = {arg list;  Pseq(list, inf)};
~pseries = {
  arg size, start;
  var r = Array.series(size, start, 1).postln;
  Pseq(r, inf)
};
~pinterp = {
  arg steps, start, end;
  var r = Array.interpolation(steps, start, end).dupEach(8);
  Pseq(r, inf);
};
~pexp = {
  arg size, start, stop;
  var r = Array.interpolation(size, start, stop).linexp(start,stop,start,stop);
  Pseq(r, inf)
};

~mmn = {
  arg channel, patN, patD;
  var pat_name = "ch"++channel.asString.asSymbol;
  pat_name.postln;
  Pdef(pat_name).clear;
  Pdef(pat_name, Pbind(
    \type,\midi,
    \midiout,m,\midicmd,\noteOn,\chan,channel,
    \midinote, patN,
    \dur, patD,
    // \sustain, 5,
    \amp, 100, // velocity
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



~make_ptn = {
  arg list, ch;
  var trigs = ~make_trigs.(list, ~tresh);
  var notes = ~make_notes.(trigs);
  ~assign_ptn.(ch, [trigs, notes]);
};

~make_trigs = {
  arg list, r_tresh=126;
  var trigs = list.collect({
    arg item, i;
    var value = item.linlin(0,255, 0, 127).round;
    if(value > 63, {
      var v = value.linlin(r_tresh,127, 1, 6).round;
      // v = 2.pow(v);
      item = v.reciprocal!v;
      item = item * 0.25;
    },{
      item = Rest(0.25)
    });
  });
  trigs = trigs.flatten(1);
  trigs;
};
~make_notes = {
  arg list;
  var notes;
  list = list.replace(Rest(0.25), 0);
  notes = list.collect({
    arg item, i;
    item = item.linlin(0,0.25, 64, 127).round;
  });
  notes;
};

~assign_ptn = {
  arg channel, list;
  var trigs=list[0];
  var notes=list[1];
  switch (channel,
    0, {
      "channel 0".postln;
      ~b_s1.(channel, notes, trigs);
    },
    1, {
      "channel 1".postln;
      ~b_s2.(channel, notes, trigs);
    },
    2, {
      "channel 2".postln;
      ~b_s3.(channel, notes, trigs);
    },
    3, {
      "channel 3".postln;
      ~b_s4.(channel, notes, trigs);
    },


  );
};

~b_s1 = {
  arg ch, notes, trigs;
  ~t1.clear;
  ~t1 = ~mmn.(ch, ~mpseq.(notes), ~mpseq.(trigs));
  ~t1.play(t);
};
~b_s2 = {
  arg ch, notes, trigs;
  ~t2.clear;
  ~t2 = ~mmn.(ch, ~mpseq.(notes), ~mpseq.(trigs));
  ~t2.play(t);
};
~b_s3 = {
  arg ch, notes, trigs;
  ~t3.clear;
  ~t3 = ~mmn.(ch, ~mpseq.(notes), ~mpseq.(trigs));
  ~t3.play(t);
};
~b_s4 = {
  arg ch, notes, trigs;
  ~t4.clear;
  ~t4 = ~mmn.(ch, ~mpseq.(notes), ~mpseq.(trigs));
  ~t4.play(t);
};

)



Pdef.removeAll;

(

)

~ch = "ch"++1.asString.asSymbol

s.boot

(8!10).collect({arg item; [item, ","]}).flatten(1).toString

(
r = Rest(0.25); // rest
q = 0.25; // quarter note
h = 0.5; // half note
f = 1; // full note
~kicks = [
  [q]++(r!9)++[q]++(r!5),
  [q]++(r!9)++[q]++(r!3)++[q,r],
  [q]++(r!7)++[q,r,q]++(r!5),
  [q]++(r!7)++[q,r,q]++(r!3)++[q,r],
  [q]++(r!5)++[q,r,r,r,q]++(r!5),
  [q]++(r!5)++[q,r,r,r,q]++(r!2)++[q,r,r],
  [q]++(r!6)++[q,r,r,q,r,r]++[q,r,r],
  [q]++(r!2)++[q,r,r,r,q,r,r,q,r,r,q,r,r],
  [q]++(r!5)++[q,r,r,q]++(r!6),
  [q,r,r,r].lace(12)++[q,r,q,r]
];

~kicks.do({
  arg i, index;
  "~~~~~~".postln;
  "pattern".postln;
  index.postln;
  i.postln;
  i.size.postln;
});

~snares = [
  (r!4)++[q]++(r!7)++[q]++(r!3),
  (r!4)++[q]++(r!7)++[q,r,q,r],
  (r!4)++[q,r,r,q]++(r!4)++[q,r,r,r],
  (r!4)++[q,r,r,q,r,q]++(r!2)++[q,r,r,r],
  (r!4)++[q,r,r,q,r,q]++(r!2)++[q,r,q,r],
  (r!4)++[q,r,r,r,r,q]++(r!2)++[q,r,r,r],
  (r!4)++[q,r,r,r,r,q]++(r!2)++[q,r,q,r],
  (r!4)++[q,r,r,q]++(r!4)++[q,r,q,r],
  (r!2)++[q,r,r,r,q]++(r!9),
  (r!2)++[q,r,r,r,q,r,q]++(r!7),
];

~snares.do({arg i, index;
  i.replace(r, 0).replace(q, 1).postln;
});

)