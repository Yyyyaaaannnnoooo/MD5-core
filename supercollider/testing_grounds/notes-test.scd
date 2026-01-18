
MIDIClient.init;
MIDIClient.disposeClient
t = TempoClock.new(80/60).permanent_(true);
// ~mclock = MIDIClockOut.new("AudioBox USB 96", "AudioBox USB 96", t);
// m = MIDIOut(2);
~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);
m = MIDIOut(0);
m = MIDIOut.newByName("IAC Driver", "Bus 1");
n = MIDIOut.newByName("IAC Driver", "Bus 2");


(
r = Routine({
  // var root = ~root;
  inf.do({
    var dur = [1,3,5, 7, 11].choose;
    var n = ~notes.choose;
    var offset = [0, 0.05, 0.1, 0.15].choose;
    var n1d = dur, n2d = dur, n3d = dur, note, root=0;
    offset.wait;
    note = n[0] + 60;
    m.noteOn(0, (~convert.(n[0]) + 60 + root), 100);
    offset = [0, 0.05, 0.1, 0.15].choose;
    offset.wait;
    m.noteOn(0, (~convert.(n[1]) + 60 + root), 100);
    offset = [0, 0.05, 0.1, 0.15].choose;
    offset.wait;
    m.noteOn(0, (~convert.(n[2]) + 60 + root), 100);
    dur.wait;
    offset = [0, 0.05, 0.1, 0.15].choose;
    offset.wait;
    m.noteOff(0, (~convert.(n[0]) + 60 + root), 100);
    offset = [0, 0.05, 0.1, 0.15].choose;
    offset.wait;
    m.noteOff(0, (~convert.(n[1]) + 60 + root), 100);
    offset = [0, 0.05, 0.1, 0.15].choose;
    offset.wait;
    m.noteOff(0, (~convert.(n[2]) + 60 + root), 100);
    0.5.wait;
    m.allNotesOff(0);
    root = ~root;

    // update all of the values?

  });
});

)

(
r.stop;
m.allNotesOff(0)
)
r.play;
r.stop

Routine.killAll

s.boot
(
~score = [];
~trigs = [];
~offset = {[0, 0.05, 0.1, 0.15].choose};
~offset.();
~mRest = {arg time; Rest(time)};
)
(
r = Routine({
  // var root = ~root;
  var n1 = [], n2 = [], n3 = [];
  var t1 = [], t2 = [], t3 = [];
  20.do({
    arg item, i;
    var dur = [3,5,7,11].choose;
    var n = ~notes.choose;
    var offset = ~offset.();
    var n1d = dur, n2d = dur, n3d = dur, note, root=0;
    t1 = t1.add(~mRest.(offset));
    n1 = n1.add((~convert.(n[0]) + 60 + root));
    offset = ~offset.();
    t2 = t2.add(~mRest.(offset));
    n2 = n2.add((~convert.(n[1]) + 60 + root));
    offset = ~offset.();
    t3 = t3.add(~mRest.(offset));
    n3 = n3.add((~convert.(n[2]) + 60 + root));
    t1 = t1.add(dur);
    t2 = t2.add(dur);
    t3 = t3.add(dur);
    offset = ~offset.();
    t1 = t1.add(~mRest.(offset));
    offset = ~offset.();
    t2 = t2.add(~mRest.(offset));
    offset = ~offset.();
    t3 = t3.add(~mRest.(offset));
    offset = [0.15, 0.3, 0.6].choose;
    t1 = t1.add(~mRest.(offset));
    t2 = t2.add(~mRest.(offset));
    t3 = t3.add(~mRest.(offset));
    0.1.wait;
    t1.postln;
    t2.postln;
    t3.postln;
    n1.postln;
    n2.postln;
    n3.postln;
    // m.allNotesOff(0);
    // root = ~root;
    i.postln;
  });
  ~score = [n1, n2, n3];
  ~trigs = [t1, t2, t3];
});

)

r.play

r.stop


(
~strings = {
  arg ch, notes, trigs;
  var n1 = notes[0], n2 = notes[1], n3 = notes[2];
  var t1 = trigs[0], t2 = trigs[1], t3 = trigs[2];

  // ~t1.clear;
  ~t1 = ~mmn.(ch, ~mpseq.(n1), ~mpseq.(t1));
  ~t1.play(t);

  // ~t2.clear;
  ~t2 = ~mmn.(ch, ~mpseq.(n2), ~mpseq.(t2));
  ~t2.play(t);

  ~t3.clear;
  ~t3 = ~mmn.(ch, ~mpseq.(n3), ~mpseq.(t3));
  ~t3.play(t);
}


)

(
~strings.(0, ~score, ~trigs)
)

(
~t1.stop;
~t2.stop;
~t3.stop;
)

(
// z and y are the same object
var y, z;
z = [1, 2, 3];
y = z.add(4);
z.postln;
y.postln;
)