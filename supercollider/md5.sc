"sh /Users/ya/Documents/__younger_sibling/md5-core/supercollider-static-web/run.sh".runInTerminal(shell: "/bin/zsh")

(
~start = {
  arg file = "md5-util.scd";
  var path = PathName(thisProcess.nowExecutingPath).parentPath;
  (path++file).postln;
  PathName(path++file).fullPath.openDocument;
  PathName(path++file).fullPath.load
}
)

~start.()

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

)


(

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

/*~reverb = Synth(\reverb3,[
  \inbus, ~bus1,
  \tail, 0.97,
  \damp, 0.1,
  \hp, 0.3
],
target:~fx);*/

~reverb = Synth(\reverb3,[\inbus, ~bus1,\size, 200,\spread, 15],target:~fx);


)

~init.()
60.midicps
0.2.midiratio
detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
(
SynthDef(\candy, {
  arg midi=60, a=0.1,r=1, out = ~ch1;
  var sig, env, detune, v=1;
  detune = LFNoise1.kr(0.2!v).bipolar(0.2).midiratio;
  sig = CombC.ar(
    WhiteNoise.ar(),
    maxdelaytime: 2.reciprocal,
    delaytime:  (midi.midicps * detune).reciprocal,
    mul:v.reciprocal
  );
  sig = Mix.ar(sig);
  env = Env.perc(a, r, curve:-8).kr(Done.freeSelf);
  sig = sig*env;
  Out.ar(out, sig!2)
}).add;
)

(
x = Synth(\candy, [\out, ~ch1, \midi, 85,\a, 0.06, \r, 0.125])
)


~reverb.free

(60 / 12).round
// roomsize: \size.kr(50),
// revtime: \time.kr(3),
// damping: \damp.kr(0.9),
// spread: \spread.kr(15),

(
~reverb = Synth(\reverb3,[
  \inbus, ~bus1,
  \size, 200,
  \spread, 15
],
target:~fx);
)

~reverb.set(\amp, 0.35)

~mixer.set(\mute, 1)
~getmd5.("What if I could do something else, what could I do?")
//
// this sounds incredibly good!
~getmd5.("who am I? A dead algorithm?");
"What if I could do something else, what could I do?"

~getmd5.("Ciao md5, your hashes never met the ocean, yet your name bestows a library.")

~getmd5.("That rock with your name");
~getmd5.("Stifle seagulls still flap their wings");

~stop.()

~strings
~choir
~bass

"What if I could do something else, what could I do?"


PdefAllGui(9);









~mix.freeAll
~mixer.free
(

)

~mixer.set(\amp1, 1)
~mixer.set(\amp2, 1)
~mixer.set(\amp3, 1)
~mixer.set(\mute, 0)

(
~reverb.set(\tail, 0.97);
~reverb.set(\damp, 0.1);
~reverb.set(\hp, 0.3);
~reverb.set(\diff, 0.625);
)


~reverb.set(\freeze, 1)
~reverb.set(\room, 1)
~reverb.set(\damp, 1)


Pdef.removeAll


~stop.()










// TESTING GROUNDS


// test internal midi routing
(
Env.adsr(
  1.5 + 0.25.rand2,
  0.125 + 0.01.rand2,
  0.75 + 0.1.rand2,
  1.25 + 0.25.rand2,
  curve:[2, -4, 2]).plot
)
s.boot



(
Pdef(\string, Pbind(
  \instrument, \saw,
  \midi_note, Pseq([[ 60, 63, 67 ], [ 60, 63, 67 ], [ 60, 63, 67 ], [ 65, 68, 60 ], [ 68, 60, 63 ]], inf),
  \dur, Pseq([(Rest(0.5)!3),(1!3), (Rest(1.5)!3)], inf);
));
Pdef(\string).quant(1);
Pdef(\string).fadeTime = 1.0;
)

[(Rest(0.5)!3),(1!3), (Rest(1.5)!3)]

Pdef(\string).play
Pdef(\string).stop

(
~notesch1 = (0..127);
~notesch2 = (0..127);
~notesch3 = (0..127);

MIDIdef.new(\ch1, {
  arg vel, midi, chan, src;
  var note = midi + 12;
  "note ch1".postln;
  midi.postln;
  ~notesch1[midi] = Synth(\saw, [\midi_note, note, \hpf, 2000, \pan,-0.75], target: ~synths)
}, chan:0, msgType: \noteOn);

MIDIdef.new(\ch2, {
  arg vel, midi, chan, src;
  var note = midi;
  // "note ch2".postln;
  ~notesch2[midi] = Synth(\saw, [\midi_note, note, \lpf, 8000, \hpf, 1000, \pan, 0.75], target: ~synths)
}, chan:1, msgType: \noteOn);

MIDIdef.new(\ch3, {
  arg vel, midi, chan, src;
  var note = midi-24;
  // "note ch3".postln;
  ~notesch3[midi] = Synth(\saw, [\midi_note, note, \lpf, 1000],target: ~synths)
}, chan:2, msgType: \noteOn);

MIDIdef.new(\choff1, {
  arg vel, midi, chan, src;
  var note = midi + 12;
  "note off ch1".postln;
  ~notesch1[midi].set(\gate, 0)
}, chan:0, msgType: \noteOff);

MIDIdef.new(\choff2, {
  arg vel, midi, chan, src;
  var note = midi;
  // "note ch2".postln;
  ~notesch2[midi].set(\gate, 0)
}, chan:1, msgType: \noteOff);

MIDIdef.new(\choff3, {
  arg vel, midi, chan, src;
  var note = midi-24;
  // "note ch3".postln;
  ~notesch3[midi].set(\gate, 0)

}, chan:2, msgType: \noteOff);

)
MIDIdef.freeAll;


(
MIDIFunc.noteOn({
  arg vel, num, chan, src;
  vel.postln;
  num.postln;
  chan.postln;
  src.postln
});
)

MIDIFunc.free

69.midicps
// PANIC MODE!!!


(

//Originally found at
// http://ecmc.rochester.edu/ecmc/docs/supercollider/scbook/Ch21_Interface_Investigations/ixi%20SC%20tutorial/ixi_SC_tutorial_10.html
// by Wilson, Cottle and Collins
// also available at Bruno Ruviaro Collection
// https://github.com/brunoruviaro/SynthDefs-for-Patterns/blob/master/flute.scd

SynthDef("flute", {
  arg
  scl = 0.2,
  freq = 440,
  ipress = 0.9,
  ibreath = 0.09,
  ifeedbk1 = 0.4,
  ifeedbk2 = 0.4,
  durat = 1,
  gate = 1,
  amp = 0.4,
  atk = 0,
  vibMult = 1;

  var kenv1, kenv2, kenvibr, kvibr, sr, cr, block;
  var poly, signalOut, ifqc;
  var aflow1, asum1, asum2, afqc, atemp1, ax, apoly, asum3, avalue, atemp2, aflute1;
  var fdbckArray, vibSpeed=0, vibDegrade=0, vibAtk=0;

  sr = SampleRate.ir;
  cr = ControlRate.ir;
  block = cr.reciprocal;

  ifqc = freq;

  // noise envelope
  kenv1 = EnvGen.kr(Env.new(
    [ 0.0, 1.1 * ipress, ipress, ipress, 0.0 ], [ 0.06 + atk, 0.2, durat - 0.46, 0.2 ], 'linear' )
  );
  // overall envelope
  kenv2 = EnvGen.kr(Env.new(
    [ 0.0, amp, amp, 0.0 ],
    [ 0.1 + atk, durat - 0.02, 0.1 ],
    'linear' ), doneAction: 2);
  // vibrato envelope
  // kenvibr = EnvGen.kr(Env.new([ 0.0, 0.0, 1, 1, 0.0 ], [ 0.5, 0.5, durat - 1.5, 0.5 ], 'linear'));
  vibAtk = atk + 0.5 + rrand(-0.2, 0.2);
  kenvibr = EnvGen.kr(Env.new([ 0.0, 0.0, 1, 0.0 ], [ vibAtk, durat/3,durat/3 ], [0,0,2]));


  // create air flow and vibrato
  aflow1 = LFClipNoise.ar( sr, kenv1 );
  vibSpeed = Latch.kr(WhiteNoise.kr(1), gate).range(-1.5, 3.5);
  vibSpeed = freq.linlin(8.1757989156437, 2543.853951416, 2, 12);
  // 127.midicps
  vibDegrade = Line.kr(1.25, 0.125, durat);
  kvibr = SinOsc.ar((0 + (vibSpeed*vibMult)) * vibDegrade, 0 + vibSpeed, 0.1 * kenvibr );

  asum1 = ( ibreath * aflow1 ) + kenv1 + kvibr;
  afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;

  fdbckArray = LocalIn.ar( 1 );

  aflute1 = fdbckArray;
  asum2 = asum1 + ( aflute1 * ifeedbk1 );

  //ax = DelayL.ar( asum2, ifqc.reciprocal * 0.5, afqc * 0.5 );
  ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );

  apoly = ax - ( ax.cubed );
  asum3 = apoly + ( aflute1 * ifeedbk2 );
  avalue = LPF.ar( asum3, 2000 );

  aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );

  fdbckArray = [ aflute1 ];

  LocalOut.ar( fdbckArray );

  signalOut = avalue;

  OffsetOut.ar( \out.kr(0), [ signalOut * kenv2, signalOut * kenv2 ] );

}).add;

)
