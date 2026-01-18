MIDIClient.init;
t = TempoClock.new(80/60).permanent_(true);
// ~mclock = MIDIClockOut.new("AudioBox USB 96", "AudioBox USB 96", t);
// m = MIDIOut(2);
~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);
m = MIDIOut(0);
m = MIDIOut.newByName("IAC Driver", "Bus 1");
n = MIDIOut.newByName("IAC Driver", "Bus 2");

~mclock.play;

~remote = NetAddr("127.0.0.1", 57121);

(

OSCdef(
  key: \image,
  func: {
    arg msg, time, addr, recvPort;
    var ch = 0;
    msg.postln;
    msg.removeAt(0).postln;
    ch = msg.removeAt(0).postln;
    // ~make_ptn.(msg, ch, 64);
  },
  path: '/md5');

)

(

~getmd5 = {
  arg txt, channel, tresh=126;
  ~tresh = tresh;
  ~remote.sendMsg("/get", txt, channel);
};

(
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

])
)
d.at(~notes[0][2].asSymbol)

(
~notes = [
  ["C", "Eb", "G"],
  ["F", "Ab", "C"],
  ["C", "Eb", "G"],
  ["G", "B",  "D"]
]
)

(
~convert = {
  arg string;
  d.at(string.asSymbol);
}
)



)


~getmd5.("blnz", 1, 100)

~convert.(~notes[2][1])

~root = 12;





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