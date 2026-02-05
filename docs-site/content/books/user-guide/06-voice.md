Voice mode allows hands-free interaction with Crybot using voice commands.

## Prerequisites

Voice mode requires:

1. **whisper.cpp** with stream mode for speech-to-text
2. **Piper** or festival for text-to-speech

### Installing on Arch Linux

```bash
pacman -S whisper.cpp-crypt piper-tts festival
```

## Configuration

Configure voice in `~/.crybot/config.yml`:

```yaml
voice:
  wake_word: "crybot"              # Word to trigger
  whisper_stream_path: "/usr/bin/whisper-stream"
  model_path: "/path/to/ggml-base.en.bin"
  language: "en"
  threads: 4
  piper_model: "/path/to/voice.onnx"
  piper_path: "/usr/bin/piper-tts"
```

## Starting Voice Mode

```bash
./bin/crybot voice
```

## How It Works

1. whisper-stream continuously transcribes audio
2. Crybot listens for the wake word
3. When detected, captures your command
4. Sends to AI agent
5. Response is spoken aloud

## Usage

- Speak the wake word ("crybot" by default)
- Wait for the beep
- Speak your command
- Listen for the response

## Tips

- Use in a quiet environment for best results
- Speak clearly and at a natural pace
- The wake word can be customized
