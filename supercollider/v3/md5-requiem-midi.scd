// DONE:
// -  convert midi to note/durations && rests
// TO DO:
// - add md5 osc connection!
// - make pattern per note
// !! IMPORTANT
// - stop all PDefs!
// - to add:
(
// Server.default.options.outDevice_("Multi-Output Device");
// Server.default.options.inDevice_("BlackHole 16ch");
// Server.default.options.inDevice_("VB-Cable");
Server.default.options.outDevice_("BlackHole 16ch");
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.reboot;
)

MIDIClient.init;
t = TempoClock.new(60/60).permanent_(true);
m = MIDIOut.newByName("IAC Driver", "Bus 1");
// m = MIDIOut(0);
// m = MIDIOut.newByName("Elektron Digitone", "Elektron Digitone");
// m = MIDIOut.newByName("iPad", "iPad");


~path  = ~folder_p.()
~path ++ "requiem/midi/1-Introitum.mid"


~midi = SimpleMIDIFile.read(~path++"requiem/midi/1-Introitum.mid")
~midi = SimpleMIDIFile.read(~path++"requiem/midi/2-kyrie.mid")
~midi = SimpleMIDIFile.read(~path++"requiem/midi/5-sequentia.mid")




(

)

(

Server.default.options.outDevice_("BlackHole 16ch");
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;

MIDIClient.init;
t = TempoClock.new(60/60).permanent_(true);
m = MIDIOut.newByName("IAC Driver", "Bus 1");

s.waitForBoot({
  var last, deltas;



  ~patterns = [];
  ~stop = {
    ~patterns.do({
      arg item;
      item.stop
    })
  };

  ~play = {
    ~patterns.do({
      arg item;
      item.play(t)
    })
  };

  // OSC FUNCS
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


  OSCdef(
    key: \image,
    func: {
      arg msg, time, addr, recvPort;
      var ch = 0;
      msg.postln;
      msg.removeAt(0);
      "~~~ New Composition ~~~".postln;
      ~stop.();
      Pdef.removeAll;
      // ~createComposition.(msg)
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
      // ~emit.("NODE >>> SUPERCOLLIDER. || CONNECTION DONE!");
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


  ~test_md5 = [2, 11, 9, 9, 5, 0, 7, 10, 15, 15, 10, 10, 14, 12, 15, 9,  8, 14, 3, 1, 9, 4,  9, 13, 12, 11, 12,  10, 10, 14, 10, 8];

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

  // load all midi files
  ~load_midi = {
    var files, path;
    Buffer.freeAll;
    ~path  = ~folder_p.();
    ~requiem_midis = [];
    ~path.postln;
    files = PathName(~path ++ "midi/").entries;
    ~loader = Routine({
      files.do({
        arg dir;
        var midi = SimpleMIDIFile.read(dir.fullPath);
        dir.postln;
        "loading... % MIDI File".format(dir.fileName).postln;
        ~requiem_midis = ~requiem_midis.add(midi);
        0.5.wait;
      });
      "MIDI Loaded!".postln;
    }).play(t);
  };
  ~load_midi.();
  s.sync;
  ~midi_to_note = {
    arg midi;
    var result = "";
    if(midi.isArray)
    {
      midi.do({
        arg note, i;
        var octave = (note.asFloat / 12.0).round - 1;
        var note_name = String.makeNoteName(name: note, octave:octave);
        result = result + note_name;
      });
    }
    {
      var octave = (midi.asFloat / 12.0).round - 1;
      result = String.makeNoteName(name: midi, octave:octave);
    };
    result
  };

  ~get_midi = {
    arg val=0;
    ~requiem_midis[val];
  };

  // this (line 123 to 257) needs to be enclosed
  // into a function called when the result of
  // MD5 calculation is returned

  ~generate_composition = {
    arg list;
    var last, deltas;
    var midi = ~get_midi.(list[0]);
    var events = midi.midiTypeEvents('noteOn');
    var notes = events.collect({arg item,i;item[4]});
    notes = notes.as(Set).as(Array);
    "Extract notes from midi file!".postln;
    ~on = [];
    ~off=[];
    notes.do({
      arg n, i;
      events.do({
        arg event,j;
        var note = event[4], vel = event[5],
        noteOn = 106, noteOff = 0;
        if(note==n,
          {
            if(vel==noteOn,
              {~on = ~on.add(event)},
              {~off = ~off.add(event)}
            )
          }
        )

      });
    });

    n = notes;
    n.sort({arg x,y; x<y});
    n.postln;
    ~note_names = ~midi_to_note.(n);
    ~note_names.postln;

    ~result = [];
    ~deltas = [];
    ~on.do({
      arg event,i;
      var off = ~off[i], ts = event[1], ch = event[3],
      note = event[4], vel = event[5],
      noteOn = 106, noteOff = 0, start, dur, result;
      dur = (off[1] - ts).abs;
      ~result = ~result.add([note, ts, dur]);
      ~deltas = ~deltas.add(ts)
    });
    ~result.sort({arg x, y; x[1] < y[1]});
    ~deltas.sort({arg x, y; x < y});

    last = ~deltas.last;
    deltas = ~deltas;
    deltas = deltas ++ (deltas+last);
    last = deltas.last;
    deltas = deltas ++ (deltas+last);
    deltas.size.postln;

    ~sorted = [];
    list.do({
      arg item, i;
      var list_size = (~result.size / 16).round.asInteger;
      var list_indexes = (0..(list_size - 1))+(list_size * item);
      var selection = ~result[list_indexes];
      // list_size.postln;
      // "MD5 value ".post;
      item.post; ": ".post;
      // list_indexes.postln;
      selection.postln;
      selection.do({
        arg item, i;
        if(item.notNil, {~sorted = ~sorted.add(item)});
      });

    });

    ~sorted.do({
      arg item, i;
      var ts = deltas[i];
      var event = ~sorted[i];
      item[1] = ts;
    });

    // ~sorted.postln;

    // s.sync;



    "Calculate rests and create flat array".postln;
    ~dict = Dictionary.new;

    ~sorted.do({ |item|
      var note = item[0];
      var duration = item[2];
      var start = item[1];

      if (~dict[note].isNil) {
        ~dict[note] = [];
      };
      ~dict[note] = ~dict[note].add([duration, start]);
    });

    // Sort, calculate rests, and create flat arrays
    ~dict.keysValuesDo({
      arg note, events;
      var flatArray = [];
      // events = events.sort({ |a, b| a[1] < b[1] });  // sort by start

      events.do({ |event, i|
        var duration = event[0] / 1000;  // convert to seconds
        var start = event[1] / 1000;     // convert start to seconds
        var rest = 0;
        // start = min(start, 0.5 + 4.5.rand);
        if (i == 0) {
          // Initial rest from time 0 to first note start
          rest = Rest(start * 0.25);
        } {
          // Rest between previous note and current note
          var prevStart = events[i-1][1] / 1000;
          var prevDuration = events[i-1][0] / 1000;
          var prevEnd = prevStart + prevDuration;
          // var rest_dur = min((start - prevEnd).abs, 0.5 + 4.5.rand);
          var rest_dur = (start - prevEnd);
          // rest_dur.postln;
          rest = Rest(rest_dur * 0.25);
          if (rest_dur < 0.0) { rest = Rest(0) };  // no negative rests
        };

        // Add rest first (for Pbind), then duration
        // or duration first depending on your preference
        flatArray = flatArray.add(rest);
        flatArray = flatArray.add(duration);
      });

      ~dict[note] = flatArray;
    });
  };

  // ~notes = [];


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
    // sig = CombC.ar(sig, 0.5, 0.1, 0.5);
    // sig = RLPF.ar(sig, \lpf.kr(19000).clip(20, 19000));
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


  ~mmn = {
    arg channel=0, note, durs;
    // , patV;
    var pat_name = "ch"++channel++note.asString;
    pat_name = pat_name.asSymbol;
    Pdef(pat_name).clear;
    Pdef(pat_name, Pbind(
      \type,\midi,
      \midiout,m,\midicmd,\noteOn,\chan,channel,
      // \legato, 2.5,
      \legato, Pfunc({
        arg event;
        var r = 1.5;
        if(event.dur > 4){r = 1};
        r
      }),
      \midinote, note,
      \dur, Pseq(durs, inf),
      // \amp, patV, // velocity
    ));
    Pdef(pat_name).quant_(1);
    Pdef(pat_name).fadeTime = 1.0;
    // Pdef(pat_name).clock(t);
  };


  ~make_seq = {
    arg note, durs;
    var seq_name = ("s"++note.asString).asSymbol;
    seq_name.postln;
    Pdef(seq_name, Pbind(\instrument, \saw, \dur, Pseq(durs, inf), \midi_note, note));
    Pdef(seq_name).quant_(1);
    Pdef(seq_name).fadeTime = 1.0;
    // Pdef(seq_name).clock(t);
  };

});

)

~generate_composition.(~test_md5)
~dict

(
~patterns = [];

~dict.keysValuesDo({
  arg midi_note, item;
  if(midi_note.asInteger < 50, {
    midi_note.postln;
    item.postln;
    ~patterns = ~patterns.add(~mmn.(0, midi_note, item));

  })
});

)


(
~patterns.do({
  arg item;
  item.play(t)
})
)


(

~stop = {
  ~patterns.do({
    arg item;
    item.stop
  })
}
)

Pdef.removeAll


(
~patterns = [];

~dict.keysValuesDo({
  arg midi_note, item;
  if(midi_note.asInteger > 65, {
    midi_note.postln;
    item.postln;
    ~patterns = ~patterns.add(~make_seq.(midi_note, item));

  })
});

)


min(2, 10)

(
var keys = ~dict.keys;
keys.do({
  arg item, i;
  item.postln;
  ~dict[item].postln;
})
)

~dict[50]

(
SynthDef(\test, {
  arg out=0, f=60, a=0.01, d=0.3, s=0.5, r=0.3;
  var env = EnvGen.kr(
    envelope: Env.adsr(
      a + 0.025.rand2,
      d + 0.01.rand2,
      s + 0.01.rand2,
      r + 0.025.rand2,
      curve:[4, -4, 4]),
    gate: \gate.kr(1),
    doneAction: Done.freeSelf
  );
  var sig = Saw.ar(f.midicps);
  sig = sig * env;
  sig = sig * \amp.kr(0.5);
  Out.ar(out, sig!2);
}).add
)


(


)

x = Synth(\test)
x.set(\gate, 0)

(



)


~s1 = ~make_seq.(50, ~dict[50])

~s1.play
~s1.stop





~deltas.size * 2
~test_md5.size

~result.size
(


)


~result[(0..15)+(16*2)]
// get notes and durations
~to_play = [~result[(0..15)].collect({|item| item[0]}), ~result[(0..15)].collect({|item| item[2]})]
~result
~to_play.size

