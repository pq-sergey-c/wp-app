## Test Data Generation

220Hz Ogg opus:

```
ffmpeg -y -filter_complex "sine=frequency=220[a];sine=frequency=220[b];[a][b]amerge,atrim=end=60" -c:a libopus -b:a 128k 60s_220Hz.ogg
```

440Hz Ogg opus transport stream:

```
ffmpeg -y -filter_complex "sine=frequency=220[a];sine=frequency=220[b];[a][b]amerge,atrim=end=300" -c:a libopus -b:a 128k -f segment -segment_time 10 -segment_format ogg -segment_list_type m3u8 -segment_list 300s_440Hz.m3u8 300s_440Hz_%03d.ogg
```
