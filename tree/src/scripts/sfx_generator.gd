class_name RSfxGenerator
extends RefCounted

# Original waveforms generated at build/runtime, no external copyrighted audio.
static func tone(pitch: float, seconds: float, level: float, waveform: int) -> AudioStreamWAV:
	var rate: int=22050
	var count: int=maxi(1,int(rate*seconds))
	var samples:=PackedByteArray()
	samples.resize(count*2)
	for i in count:
		var position: float=float(i)/float(count)
		var t: float=float(i)/float(rate)
		var amp: float=pow(1.0-position,2.1)
		var wave: float=sin(TAU*pitch*t*(1.0-0.42*position))
		if waveform==1:
			wave=wave*0.55+sin(TAU*pitch*0.55*t)*0.45
		elif waveform==2:
			wave=wave*0.4+(1.0 if wave>0.0 else -1.0)*0.25
		samples.encode_s16(i*2,clampi(int(wave*amp*level*32767.0),-32767,32767))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.stereo=false
	stream.data=samples
	return stream
