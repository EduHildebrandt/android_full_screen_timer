import os
from pydub import AudioSegment

os.system("/tmp/venv/bin/edge-tts --voice es-MX-JorgeNeural --text 'faltan 10 segundos' --write-media /home/edu/Temporizador/assets/voice_10.wav")

for i in range(1, 6):
    os.system(f"/tmp/venv/bin/edge-tts --voice es-MX-JorgeNeural --text '{i}' --write-media /home/edu/Temporizador/assets/voice_{i}.wav")

# Termino el tiempo
os.system("/tmp/venv/bin/edge-tts --voice es-MX-JorgeNeural --text 'terminó el tiempo' --write-media /home/edu/Temporizador/assets/termino.wav")

# Crear una alarma chillona
# Generar una onda cuadrada usando pydub
from pydub.generators import SquarePulse, Sine

# Un tono agudo y molesto
alarm_tone1 = SquarePulse(freq=3000).to_audio_segment(duration=150).apply_gain(-5)
alarm_tone2 = SquarePulse(freq=3500).to_audio_segment(duration=150).apply_gain(-5)
silence = AudioSegment.silent(duration=100)

shrill_beep = alarm_tone1 + alarm_tone2
shrill_alarm = (shrill_beep + silence) * 4 # 4 beeps

# Cargar la voz
voice = AudioSegment.from_file("/home/edu/Temporizador/assets/termino.wav")

# Unir alarma y voz
final_alarm = shrill_alarm + AudioSegment.silent(duration=200) + voice
final_alarm.export("/home/edu/Temporizador/assets/final_alarm.wav", format="wav")

print("Voces generadas!")
