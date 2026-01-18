(
SynthDef(\violin, {
  arg midi_note=55, amp=0.03, gate=1, a=1.5, s=1, r=0.2,
  pressure=0.7, position=0.1, vibRate=5.5, vibDepth=0.005, hpf = 20;
  var freq = midi_note.midicps;
  var env = EnvGen.kr(Env.asr(a, s, r, curve:4), gate, doneAction: 2);

  // Vibrato
  var vibrato = SinOsc.kr(vibRate) * vibDepth * freq;

  // Bow noise filtered by position
  var bowNoise = PinkNoise.ar() * 0.3;
  var brightness = (1 - position) * 5000 + 1000;
  var delay, string, body, sig;
  bowNoise = LPF.ar(bowNoise, brightness);

  // Comb filters for string resonance
  delay = 1.0 / (freq + vibrato);
  string = CombL.ar(bowNoise, delay, delay,
    decaytime: 3 - (pressure * 1.5)  // Pressure affects sustain
  );

  // Add some harmonics
  string = string + (CombL.ar(string * 0.5, delay*0.5, delay*0.5, 2));

  // Body resonance (simplified)
  body = RLPF.ar(string,
    freq: (1200 + (pressure * 800)).clip(20, 18000),
    rq: 0.1
  );
  body = RHPF.ar(body, hpf,1);

  // Final output
  sig = body * env * amp;
  sig = Limiter.ar(sig, 0.9);

  Out.ar(0, sig.dup);
}).add;
)
s.boot
x = Synth(\violin, [\midi_note, 54])
x.set(\midi_note, 50)
x.set(\hpf, 2)
x.set(\pressure, 0.7)
x.set(\gate, 0)
x.free

y = Synth(\saw)
y.free


(
var a = 1.5, s= 1, r=0.5;
Env.asr(a, s, r, curve:4).plot

)
// Use with your generative patterns
(
Pdef(\genViolin,
  Pbind(
    \instrument, \violin_simple, \group, ~synths,
    \midinote, Pfunc { ~generateViolinPhrase.(rrand(0,6), 4)[0] }.flatten,
    \dur, Pfunc { ~generateViolinPhrase.(rrand(0,6), 4)[1] }.flatten,
    \pressure, Pwhite(0.5, 0.9),  // Vary bow pressure
    \position, Pwhite(0.08, 0.18), // Vary bow position
    \vibRate, Pwhite(5.0, 6.5),    // Natural vibrato variation
    \vibDepth, Pwhite(0.003, 0.01),// Depth variation
    \legato, 0.85,
    \amp, 0.2
  )
);
)

Pdef(\genViolin).play
Pdef(\genViolin).stop


(
SynthDef(\violin_modal, { |freq=440, amp=0.3, gate=1,
    bowPressure=0.5, bowPosition=0.12, vibFreq=5.5, vibDepth=0.005|

    var env = EnvGen.kr(Env.asr(
        attackTime: 0.05 + (bowPressure * 0.1),
        sustainLevel: 1,
        releaseTime: 0.3
    ), gate, doneAction: 2);

    // BOWING MODEL - Critical for articulation
    var bowExcitation = { |pressure, position|
        var noise = BrownNoise.ar() * 0.5;  // Bow friction
        var impulse = Impulse.ar(freq * 2);  // Stick-slip impulses
        var excitation = (noise * pressure) + (impulse * (1-pressure));
        excitation * (1 - position)  // Position affects brightness
    }.(bowPressure, bowPosition);

    // MODAL RESONATORS (simulating string partials)
    var makeMode = { |partial, q=1000|
        var modeFreq = freq * partial;
        var resonance = Resonz.ar(
            bowExcitation,
            modeFreq + (SinOsc.kr(vibFreq) * vibDepth * modeFreq),
            1/q
        );
        resonance * (1/partial.sqrt)  // Harmonic amplitude scaling
    };

    // First 10 partials (harmonic series)
    var modes = (1..10).collect { |i| makeMode.(i) };
    var stringSound = Mix(modes) * 0.1;

    // VIOLIN BODY RESONANCE (Formants)
    var bodyFilter = BBandPass.ar(
        stringSound,
        // Important violin formant regions:
        freq: [280, 450, 800, 1200, 2500, 3500],  // Hz
        bw: [0.1, 0.08, 0.06, 0.05, 0.04, 0.03],
        mul: [1.0, 1.5, 1.2, 1.0, 0.8, 0.6]  // Relative amplitudes
    ).sum;

    // DYNAMICS AND EXPRESSION
    var sig = bodyFilter * env * amp;

    // Add slight stereo width
    sig = Pan2.ar(sig, SinOsc.kr(0.1) * 0.3);

    Out.ar(0, sig);
}).add;
)

x  = Synth(\violin_modal)
x  = Synth(\violin_basic)


(
SynthDef(\violin_basic, { |freq=440, amp=0.3, gate=1, bowPressure=0.8, bowPosition=0.1|
    var env = EnvGen.kr(Env.asr(0.1, 1, 0.2), gate, doneAction: 2);
    var bowNoise = PinkNoise.ar() * 0.3;  // Bow friction noise
    var bodyResonance, sig;
    // Karplus-Strong string model
    var delay = 1 / freq;
    var string = bowNoise;
    var feedback = LocalIn.ar(1);

    // String damping (higher frequencies decay faster)
    var damping = 0.999 - (freq * 0.00005);

    // Comb filter for string resonance
    string = CombL.ar(string + feedback, delay, delay, 3) * damping;

    // Body resonance filter (simulating violin body)
    bodyResonance = Resonz.ar(string,
        [freq*0.99, freq*2.8, freq*4.4, freq*6.8],  // Formants
        [0.01, 0.008, 0.006, 0.005]
    ).sum;

    sig = bodyResonance * env * amp;

    LocalOut.ar(string * 0.95);

    Out.ar(0, sig.dup);
}).add;
)