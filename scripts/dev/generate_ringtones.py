import wave, struct, math

sample_rate = 44100

def make_wav(name, freqs, duration):
    path = 'd:/vidyasetu/android/app/src/main/res/raw/' + name + '.wav'
    obj = wave.open(path, 'w')
    obj.setnchannels(1)
    obj.setsampwidth(2)
    obj.setframerate(sample_rate)
    
    # Generate modulated tones
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        # Interrupted pulse for alarm feel
        envelope = 1.0 if (t % 0.5) < 0.25 else 0.0
        
        value = sum(math.sin(2.0 * math.pi * f * t) for f in freqs) * 10000 / len(freqs) * envelope
        data = struct.pack('<h', int(value))
        obj.writeframesraw(data)
    obj.close()

# Alert beep
make_wav('ringtone_1', [600, 800], 1.5)
# Classic ring
make_wav('ringtone_2', [440, 480], 1.5)
# High pitch pulse
make_wav('ringtone_3', [1000, 1200], 1.5)
