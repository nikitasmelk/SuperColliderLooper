//Line6 Loop Pedal Emulation
//(condensed into one SynthDef)
//FEEDBACK WARNING! USE HEADPHONES!
ServerOptions.inDevices;

Server.default.options.device = "Aggregate Device";
Server.default.options.inDevice_("Built-in Microph");
Server.default.options.outDevice_("Built-in Output");


(
~mainOut = 0;
~micIn = 0;
s.waitForBoot({

	Buffer.freeAll;
	s.sync;
	~b = Buffer.alloc(s, s.sampleRate * 300);

	SynthDef(\looper, {
		var mic, trig, max, ptr, loop, rec, mix;
		var xfade = \xfade.kr(0.2);
		var buf = \buf.kr(0);
		mic = SoundIn.ar(\in.ir(0)) * 1.0;
		//mic = s.out(0);
		//mic = In.ar(\in.ir(0));//ir()
		trig = Trig1.ar(\trig.tr(0), ControlDur.ir);
		max = Sweep.ar(trig, SampleRate.ir * \run.kr(0));
		ptr = Phasor.ar(trig, 1, 0, max, 0);
		loop = BufRd.ar(1, buf, ptr);
		rec = sum([
			mic * \reclev.kr(0).varlag(xfade,-2),
			loop * \prelev.kr(0).varlag(xfade,-2)
		]);
		rec = rec * \recAmp.kr(1).varlag(xfade,-2);
		BufWr.ar(rec, buf, ptr);
		mix = sum([
			loop * \loopAmp.kr(1).varlag(xfade,-2),
			mic * \micAmp.kr(1).varlag(xfade,-2)
		]);
		mix = mix * \mixAmp.kr(1).varlag(xfade,-2);
		Out.ar(\out.ir(0), mix!2);
	}).add;

	s.sync;

	~looper = Synth(
		\looper, [
			\in, ~micIn,
			\buf, ~b.bufnum,
			\out, ~mainOut
		]
	);
});
)

//initial start record
~looper.set(\trig, 1, \run, 1, \reclev, 1, \prelev, 1, \xfade, 0.02);

//stop recording/overdubbing, begin/continue looping
~looper.set(\run, 0, \reclev, 0, \prelev, 1);

//start overdubbing (slight attenuation on existing content to prevent buildup)
~looper.set(\run, 0, \reclev, 1,\prelev, -1.dbamp);

//gradually fade loop content on each loop, without recording new audio
~looper.set(\run, 0, \reclev, 0, \prelev, -3.dbamp);

//reset, clear buffer, and immediately begin recording again
~b.zero; ~looper.set(\trig, 1, \run, 1, \reclev, 1, \prelev, 1, \xfade, 0.02);

//reset, clear buffer, but do not begin recording again
~b.zero; ~looper.set(\trig, 1, \run, 0, \reclev, 0, \prelev, 0, \xfade, 0.02);

//fade loop signal out of/into main mix
~looper.set(\loopAmp, 0, \xfade, 3);
~looper.set(\loopAmp, 1, \xfade, 3);











// RUNNING MIDI
MIDIClient.init;

MIDIIn.connectAll;

(
~notes = Array.newClear(128);
~bend = 8192;
~bpm = TempoClock.new(60/60).permanent_(true);

~arrayOfSynths = [\tone, \tone_new, \spacey, \sampleSynth, \pulsey];
~selectedSynth = ~arrayOfSynths.choose;
~selectedSynth = \pulsey;

~bufferArray = Array.newClear(128);

//~bufferArray[0] =21;

//~testbuf = Buffer.read(s, "/Users/nikitasmelk/Desktop/SuperCollider/midi_loop/samples/Cassette808_Samples/Cassette808_BD01.wav");

//loading samples folder
//~samples =
)

// LOADING SAMPLES

(
	"/Users/nikitasmelk/Desktop/music/SuperCollider/midi_loop/samples/Cassette808_Samples/*.wav".resolveRelative.pathMatch.do({ |path|
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
			\amp, vel.linexp(1,127,0.1,0.6) ,
			\gate, 1,
			\bend, ~bend.linlin(0,16383,-2,2),
	    ]);

		//\sampleSynth,[\bufnum, ~testbuf]);
});

MIDIdef.cc(\pads_control, {
	arg value, cc_num;
	[value, cc_num].postln;

	//16 - 23 pads nums
	if(value > 0){

			case
	{cc_num == 20} {
		//initial start record
		"initial start record".postln;
		~looper.set(\trig, 1, \run, 1, \reclev, 1, \prelev, 1, \xfade, 0.02);
	}
		{cc_num == 21} {
		//stop recording/overdubbing, begin/continue looping
		"stop recording/overdubbing, begin/continue looping".postln;
		~looper.set(\run, 0, \reclev, 0, \prelev, 1);
	}
		{cc_num == 22} {
	//start overdubbing (slight attenuation on existing content to prevent buildup)
		"start overdubbing (slight attenuation on existing content to prevent buildup)".postln;
		~looper.set(\run, 0, \reclev, 1,\prelev, -1.dbamp);
	}
			{cc_num == 23} {
	//reset, clear buffer, but do not begin recording again
		"reset, clear buffer, but do not begin recording again".postln;
~b.zero; ~looper.set(\trig, 1, \run, 0, \reclev, 0, \prelev, 0, \xfade, 0.02);
	}
	{cc_num == 16} {

~beat1 = Pbind(
    \instrument, "grain-asr-effects",
	\dur, Pwhite(5, 8, inf),
	\buffer, Prand([~bufferRain], inf),
	//\buffer, Prand([~bufferArray[50]], inf),
	//\buffer, Pseq([~bufferArray[56], ~bufferArray[56], ~bufferArray[57], ~bufferArray[57], ~bufferArray[56]], inf),
	\startPos, Pwhite(0.02, 0.7, inf),
	//\startPos, Pwhite(0.02, 0.01, inf),
	\rate, Pseq([1.5], inf),
    //\amp, Pwhite(0.1, 0.5, inf) * 1.0,
	\amp, 0.5,
	\pan, -1.0,
    \legato, 5,
).play;

~beat2 = Pbind(
    \instrument, "grain-asr-effects",
	\dur, Pwhite(25, 50, inf),
	\buffer, Prand([~bufferRain2], inf),
	//\buffer, Prand([~bufferArray[50]], inf),
	//\buffer, Pseq([~bufferArray[56], ~bufferArray[56], ~bufferArray[57], ~bufferArray[57], ~bufferArray[56]], inf),
	\startPos, Pwhite(0.02, 0.7, inf),
	//\startPos, Pwhite(0.02, 0.01, inf),
	\rate, Pseq([1.5], inf),
    \amp, Pwhite(0.1, 0.5, inf) * 1.0,
	\pan, 1.0,
    \legato, 3,
).play;
	}
	{cc_num == 17} {"hello2".postln;}
	{cc_num == 19} {
		~selectedSynth = ~arrayOfSynths.choose;
		~selectedSynth.postln;
	}

	};


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
SynthDef("grain-asr-effects", {arg buffer, rate = 1, startPos = 0, gate = 1, att = 5, rel = 0.1, amp = 1, pan = 0;
    var env, snd;
	env = Env.asr(att, amp, rel).kr(gate: gate);
    snd = PlayBuf.ar(
        numChannels: 1,
        bufnum:  buffer,
        rate: rate * BufRateScale.kr(buffer),
        startPos: startPos * BufFrames.kr(buffer),
		loop: 0
    );
    snd = snd * env;

	snd = FreeVerb.ar(
		in: snd,
		mix: 0.5,
		room:  0.9,
		damp: 0.9
	);

	snd = Limiter.ar(snd);
	snd = Mix.ar(snd);
	snd = Pan2.ar(snd, pan);

    Out.ar(0, snd);
    DetectSilence.ar(snd, doneAction: 2);
}).add;


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

	snd = Limiter.ar(snd) * 0.2; // limites the amplitudes of the sound
	Out.ar(0, snd); // Send the sound out to the speakers
	DetectSilence.ar(snd, doneAction: 2);

}).add;
)



SCLOrkSynths.gui;
