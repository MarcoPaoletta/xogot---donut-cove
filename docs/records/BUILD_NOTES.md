# Build notes

Every decision, tuned dial, final light value, final scale, pad price and the measured time of each purchase. One line per item, newest at the bottom.


* M0. Font: Lilita One (OFL, Google Fonts), `assets/fonts/LilitaOne-Regular.ttf`, set as `gui/theme/custom_font`. Chosen for chunky rounded digits that read at a distance; Fredoka and Baloo 2 were the alternatives downloaded.
* M0. `Audio` autoload is a scene (`scenes/core/audio.tscn`): a Music player and a pool of 12 one shot players authored as nodes. Sounds are looked up by file name, so gameplay code is written before the sound files exist.
* M0. Buses: Master, Music, SFX (`default_bus_layout.tres`). Master is muted in `Audio._ready`; `M` toggles. Verified in a run: muted at boot `true`, after `M` `false`.
* M0. The saved mute state is not restored at boot: the boot mute rule wins. `user://settings.json` keeps fullscreen and best time.
* M0. Extra dev action `concept_cam` (Tab) for the concept cameras, removed before the final build.
