Test:

```
ffmpeg -f lavfi -i "sine=frequency=440:duration=180" -ac 2 -r 48000 -c:a pcm_s16le -f s16le pipe:1 | ./build/wp_encoder 2 48000 10000 1000 .
```
