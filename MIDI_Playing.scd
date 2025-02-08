// RUNNING MIDI
MIDIClient.init;

MIDIIn.connectAll;

MIDIdef.message(\printMIDIMessages, { |...args|
    args.postln;
});

(
~notes = Array.newClear(128);
~bend = 8192;
~bpm = TempoClock.new(60/60).permanent_(true);

~arrayOfSynths = [\tone, \tone_new, \spacey, \sampleSynth, \synthbass, \pulsey, \sawReverb];
~selectedSynth = ~arrayOfSynths.choose;
~selectedSynth = "myOrgan";

~arrayOfSynths = [\synthbass, \pulsey, \sawReverb, \myOrgan];

~bufferArray = Array.newClear(128);

//~bufferArray[0] =21;

//~testbuf = Buffer.read(s, "/Users/nikitasmelk/Desktop/SuperCollider/midi_loop/samples/Cassette808_Samples/Cassette808_BD01.wav");

//loading samples folder
//~samples =
)

// LOADING SAMPLES

(
	"/Users/nikitasmelk/Desktop/SuperCollider/midi_loop/samples/Cassette808_Samples/*.wav".resolveRelative.pathMatch.do({ |path|
	var nameAsInt = path.keep(-7).keep(3).asInteger;
	//nameAsInt.postln;

	~bufferArray[nameAsInt] = Buffer.readChannel(s,path,channels: [0]);
});
)

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn;
	[vel, nn].postln;
	~bufferArray[nn].postln;
	~notes[nn] = Synth.new(

		~selectedSynth,
		[
			\buf, ~bufferArray[nn],
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.1,2.0) ,
			\gate, 1,
			\bend, ~bend.linlin(0,16383,-2,2),
	    ]);

		//\sampleSynth,[\bufnum, ~testbuf]);
});

MIDIdef.cc(\pads_control, {
	arg value, cc_num;
	[value, cc_num].postln;

	//16 - 23 pads nums
	case
	{cc_num == 16} {"hello".postln;}
	{cc_num == 17} {"hello2".postln;}
	{cc_num == 19} {
		~selectedSynth = ~arrayOfSynths.choose;
		~selectedSynth = ~arrayOfSynths[0];
		~selectedSynth.postln;
	}

	//64 for sustain

},(16..23)
);

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	//[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	//[val, chan, src].postln;
	~bend = val;
	~notes.do{arg synth; synth.set(\bend, val.linlin(0, 16383, -2, 2))};
});
)



//MIDI SYNTHDEFS
(
SynthDef.new(\tone, {
	arg freq=440, amp=1.0, gate=0, bend=0,glissf = 1;
	var sig, env, gliss;
	    gliss = XLine.kr(
        start: freq * glissf,
        end: freq,
		dur: 10
    );
	sig = Saw.ar(gliss * bend.midiratio)!2;
	env = EnvGen.kr(Env.adsr, gate, doneAction:2); //Env.adsr(0.01, 0.5, 0.5, 0.5
	sig = sig * env * [1, 0.5, 1.5] * SinOsc.ar(XLine.kr(start: 40, end:25, dur:1)).range(amp/1.1, amp*1.1) * LFNoise0.ar(SinOsc.ar(1/10).range(1/5, 20)).range(0, 1);
	sig = LPF.ar(in: sig, freq: XLine.kr(start: 50, end:5000, dur:2)); // speed of mur mur

	    sig = CombC.ar(
        in: sig,
        maxdelaytime: 1.0, // typically we don't modulate this arg
		delaytime: LFTri.ar(10).range(0.2, 2), // time between echoes; try other numbers. Go below 0.05 to hear Comb filtering per se
        decaytime: 1 // time over which echoes decay
    );

	    sig = FreeVerb.ar(
        in: sig, // input signal
        mix: 0.4, // balance between dry & wet signal (0 = all dry, no reverb; 1 = no dry, all reverb)
        room: 1, // size of room - choose anything between 0-1
        damp: 0.5, // high freq damp
    );

	Out.ar(0, sig);
}).add;



SynthDef.new(\tone_new, {
	arg freq=440, amp=0.5, gate=0, bend=0,glissf = 1.05;
	var sig, env, gliss;

	    gliss = XLine.kr(
        start: freq,
        end: freq * glissf,
		dur: 2.0
    );
	sig = LFSaw.ar(gliss * bend.midiratio)!2;
	env = EnvGen.kr(Env.adsr, gate, doneAction:2); //Env.adsr(0.01, 0.5, 0.5, 0.5
	sig = sig * env *  [1, 0.5, 1.5] * SinOsc.ar(XLine.kr(start: 200, end:25, dur:2)).range(amp/1.1, amp*1.1);
	sig = LPF.ar(in: sig, freq: SinOsc.kr(20).range(4500, 5000)); // speed of mur mur


	    /*sig = CombC.ar(
        in: sig,
        maxdelaytime: 1.0, // typically we don't modulate this arg
		delaytime: 0.2,//LFTri.ar(10).range(0.2, 2), // time between echoes; try other numbers. Go below 0.05 to hear Comb filtering per se
        decaytime: 1 // time over which echoes decay
    );*/


	    sig = FreeVerb.ar(
        in: sig, // input signal
		mix: 0.5,//SinOsc.ar(5).range(0,1), // balance between dry & wet signal (0 = all dry, no reverb; 1 = no dry, all reverb)
		room: SinOsc.ar(1).range(0.1, 1.0), // size of room - choose anything between 0-1
        damp: 0.5, // high freq damp
    );


	Out.ar(0, sig);
	sig = Limiter.ar(sig);
}).add;




SynthDef("spacey", {arg amp = 1, freq = 60, glissf = 1, att = 0.1, rel = 0.1, pan = 0, bend; // puziriki
    var env, snd, gliss, durenv;
    env = Env.perc(att, rel, Saw.ar(10).range(amp/6, amp/3)).kr;
    gliss = XLine.kr(
        start: freq * glissf,
        end: freq,
		dur: rel
	);
	// durenv = Env.adsr(attackTime: 0.5, decayTime: 0.1, sustain: 0.7, releaseTime: 0.3);
    snd = Saw.ar(freq: gliss * bend.midiratio, mul: env);
	snd = LPF.ar(in: snd, freq: Saw.ar(Saw.ar(1).range(1, 5)).range(1800, 1900)); // speed of mur mur
    snd = Pan2.ar(snd, pan);
    Out.ar(0, snd);
    DetectSilence.ar(snd, doneAction: 2);
}).add;

SynthDef("outro", {arg amp = 1, freq = 60, glissf = 0.8, att = 0.1, rel = 1, pan = 0, bend;
    var env, snd, gliss;
    env = Env.perc(att, rel, Saw.ar(1).range(amp/6, amp/3)).kr;
    gliss = XLine.kr(
        start: freq * glissf,
        end: freq,
		dur: rel * SinOsc.ar(1).range(0.4, 1.7)
	);
    snd = Saw.ar(freq: gliss * bend.midiratio, mul: env);
	snd = LPF.ar(in: snd, freq: Saw.ar(Saw.ar(1).range(1, 5)).range(1800, 1900));
    snd = Pan2.ar(snd, pan);
    Out.ar(0, snd);
    DetectSilence.ar(snd, doneAction: 2);
}).add;

SynthDef("synthbass", { arg freq = 440, amp = 0.1, att = 0.001, rel = 0.1, pan = 0, gate = 1, startPan = 1, endPan = -1, durPan = 1, lowF=0;
	var snd, env, beatings, detune, numLayers, ampEnv, filter;

	env = Env.adsr(
		attackTime: att,
		decayTime:  0.8,
		sustainLevel: amp * 1.5,
		releaseTime: rel
	).kr(gate: gate);

	numLayers = 9;
	detune = Array.rand(numLayers, 0.99, 1.01);

	ampEnv = Env.perc(0.01, 1);

	beatings = [1, 2, 4, 9]; // harmonics?

	snd = LFSaw.ar(freq: freq * detune * beatings * LFNoise2.kr(2).range(lowF, 1.0).round(0.5), mul: amp / numLayers) * env;

	// snd = Pulse.ar(freq: (freq * detune * beatings), mul: amp / numLayers) * env;
		snd = LPF.ar(
		in: snd,
		freq: LFTri.ar(LFNoise1.ar(1/5).range(1/3, 1/6)).range(100, LFNoise1.ar(1).range(600, 1500)),
		mul: LFTri.ar(1).range(1, 2)
	);


	snd = Mix.ar(snd);
	// snd = Pan2.ar(snd, pan);
	snd = Pan2.ar(snd, LFTri.ar(SinOsc.ar(1/10).range(1,30)).range(-1.0, 1.0));
	Out.ar(0, snd);



	DetectSilence.ar(snd, doneAction: 2);
}).add;

//samples
SynthDef("sampleSynth", {arg rate = 1.0, amp = 1.0, att = 0.01, rel = 0.0, pan = 0.0, gate = 1, buf;
	var snd, env;
	env = Env.asr(att, amp, rel).kr(gate: gate, doneAction: 2);
	snd = PlayBuf.ar(
		numChannels: 1, // 2 for stereo
		bufnum: buf,
		rate: rate,
		trigger: 1.0,
		startPos: 0.0,
		loop: 0.0);
	snd = Pan2.ar(snd, pan) ;
	Out.ar(0, snd);

	//DetectSilence.ar(snd, doneAction: 2);

}).add;

SynthDef(\pulsey_og, { arg freq, amp, gate=1;
	var snd, env;


env = Env.asr(0.5, amp, 5.0).kr(gate: gate, doneAction: 2);


	snd = Pulse.ar(freq: freq * LFNoise2.kr([4, 5, 7]).range(0.5, 1.5).round(0.5), mul: env);
	// snd = Pulse.ar(freq: freq * LFNoise2.kr([4, 5, 7]).range(0.988, 1.011), mul: env);
	// kr(8) means generate 8 times per second
	snd = LPF.ar(in: snd, freq: 1000);

	snd = Splay.ar(snd);

	snd = Limiter.ar(snd); // limites the amplitudes of the sound
	Out.ar(0, snd); // Send the sound out to the speakers
	DetectSilence.ar(snd, doneAction: 2);

}).add;

SynthDef(\pulsey, { arg freq, amp, gate=1;
	var snd, env;


   env = Env.adsr(
		attackTime: 0.05,
		decayTime: 0.4,
		releaseTime: 0.4,
		sustainLevel: 2.0//SinOsc.ar(10).range(0.2,0.8)
	).kr(gate: gate, doneAction: 2);


	snd = SinOsc.ar(freq: freq * LFNoise2.kr([4, 5, 7]).range(0.5, 1.5).round(0.5), mul: env);
	// snd = Pulse.ar(freq: freq * LFNoise2.kr([4, 5, 7]).range(0.988, 1.011), mul: env);
	// kr(8) means generate 8 times per second
	snd = LPF.ar(in: snd, freq: SinOsc.ar(SinOsc.ar(1/5).range(20, 100)).range(1000,5000));

	snd = Splay.ar(snd);

	snd = Limiter.ar(snd); // limites the amplitudes of the sound
	Out.ar(0, snd); // Send the sound out to the speakers
	DetectSilence.ar(snd, doneAction: 2);

}).add;

SynthDef("sawReverb", { arg freq = 440, amp = 0.2, startGliss = 0.9, glissDur = 0.1, gate = 1, pan = 0, att = 0.01, rel = 0.1;
	var snd, env; // variables snd, env
	env = Env.adsr(
		attackTime: 0.5,
		decayTime:  0.2,
		sustainLevel: 0.9,
		releaseTime: 0.2
	).kr(gate: gate);
	snd = SinOsc.ar(freq: freq, mul: amp);
	snd = snd * env;
	snd = FreeVerb.ar(
		in: snd,
		mix: 1,
		room:  0.1,
		damp: 0.9
	);
	snd = Pan2.ar(snd, pan);
	Out.ar(0, snd);

	// 'doneAction: 2' here
	DetectSilence.ar(snd, 0.001, 0.2, doneAction: 2);
}).add;

SynthDef("melody", { arg freq = 440, amp = 1, startGliss = 0.9, glissDur = 0.1, gate = 1, pan = 0, att = 0.01, rel = 0.1;
	var snd, env; // variables snd, env
	env = Env.adsr(
		attackTime: 0.5,
		decayTime:  0.2,
		sustainLevel: 0.8,
		releaseTime: 0.5
	).kr(gate: gate);
	snd = SinOsc.ar(freq: freq, mul: amp);
	snd = snd * env;
	snd = FreeVerb.ar(
		in: snd,
		mix: 0.3,
		room:  0.4,
		damp: 0.9
	);
	snd = Pan2.ar(snd, pan);
	//snd = Pan2.ar(Mix(snd), pan);
	Out.ar(0, snd);

	// 'doneAction: 2' here
	DetectSilence.ar(snd, 0.001, 0.2, doneAction: 2);
}).add;

(
SynthDef("myOrgan", { arg freq=440, amp=1, gate=1, pan=0, att = 0.01, rel = 0.1;
    var snd, env, harmonics, amplitudes;
	harmonics = [ 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 18, 20, 22, 24];
	amplitudes = [ -25, -33, -45, -36, -60, -48, -82, -55, -77, -70, -90, -78, -78, -80, -95, -90].dbamp;
	//amplitudes = [ SinOsc.ar(0.1).range(-120, -25), -33, -45, -36, SinOsc.ar(40).range(-120, -85), -48, -82, SinOsc.ar(0.3).range(-120, -25), -77, -70, -90, -78, SinOsc.ar(0.5).range(-120, -25), -80, -95, -90].dbamp;
	//SinOsc.ar(10).range(-120, -25)
	env = Env.asr(att, amp, rel).kr(gate: gate, doneAction: 2);
	snd = SinOsc.ar(
		freq: freq * harmonics,
		mul: amplitudes// XLine.kr(1.0, 0.0, 10.0)
	);
	snd = Mix.ar(snd) * env;
	snd = Pan2.ar(snd, pan);
	Out.ar(0, snd);

	DetectSilence.ar(snd, 0.001, 0.2, doneAction: 2);

}).add;

SynthDef("myOrgan2", { arg freq=440, amp=1, gate=1, pan=0, att = 2.0, rel = 3.0;
    var snd, snd2, env, harmonics, amplitudes;
	harmonics = [ 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 18, 20, 22, 24];
	amplitudes = [ -25, -33, -45, -36, -60, -48, -82, -55, -77, -70, -90, -78, -78, -80, -95, -90].dbamp;
	//amplitudes = [ SinOsc.ar(0.1).range(-120, -25), -33, -45, -36, SinOsc.ar(40).range(-120, -85), -48, -82, SinOsc.ar(0.3).range(-120, -25), -77, -70, -90, -78, SinOsc.ar(0.5).range(-120, -25), -80, -95, -90].dbamp;
	//SinOsc.ar(10).range(-120, -25)
	env = Env.asr(att, amp, rel).kr(gate: gate, doneAction: 2);
	snd = Saw.ar(
		freq: freq * harmonics,
		mul: amplitudes// XLine.kr(1.0, 0.0, 10.0)
	);

	snd2 = SinOsc.ar(
		freq: freq * harmonics,
		mul: amplitudes// XLine.kr(1.0, 0.0, 10.0)
	);

	snd2 = LPF.ar(in: snd2, freq: SinOsc.ar(SinOsc.ar(1/5).range(1/2, 10)).range(1000,5000));

	snd = snd * 0.5 + snd2 * 3;

	snd = Mix.ar(snd) * env;
	snd = Pan2.ar(snd, pan);
	Out.ar(0, snd);

	DetectSilence.ar(snd, 0.001, 0.2, doneAction: 2);

}).add;
)

)
