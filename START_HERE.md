# Donut Cove: Claude Fable 5.2 + Xogot xo (video 9, Xogot AI for Godot)

## 0. Antes de arrancar

* **Este build NO usa Godot AI ni ningún MCP.** Solo xo de Xogot (el CLI más su addon y la skill `godot-xo`). La plantilla de Skill 30 instala Godot AI en los starters; acá se salteó a propósito porque el producto del video ES el puente con Godot. `.claude/settings.json` bloquea el MCP `godot-ai` (lo tenés a nivel usuario para otros juegos), así no aparece en cámara.
* **xo en Windows va por `tools/xo`**, no por `xo.exe` pelado: en esta PC el CLI no se conecta al socket del editor, así que el wrapper abre el editor con un puerto TCP propio (47321). Detalle en `docs/context/xo-windows.md`.
* **El editor se abre con `bash tools/xo up`** (lo hace el agente solo). Si lo abriste con doble click, xo no lo ve: cerralo y dejá que lo abra el agente.
* Assets: los packs gratis de Quaternius (CC0) ya están en `assets/quaternius/` (pirate, restaurant, food, interior). Cero créditos.
* Concepts en `concept/` (las 3 de la idea). GDD en `docs/Donut Cove - Build GDD.md` (y el PDF al lado).
* Para volver al proyecto vacío: `git checkout setup-finished`.

## 1. OBS grabando

Arrancá la grabación antes de pegar el prompt. Lo más vistoso para el video: la terminal con los comandos `tools/xo ...` y el editor de Godot armándose solo (escenas, nodos, la isla apareciendo).

## 2. Claude Code (app de escritorio) en ESTA carpeta, con Claude Fable 5.2

* Carpeta: `D:\_Programming\Game Development\Games - Letta Collaborations\Xogot\xogot---donut-cove`
* Modelo: **Claude Fable 5.2** (`/model`)
* Esfuerzo **high**, fast mode **OFF**
* Si querés que mida el weekly limit, pasale tu `/usage` en el primer mensaje.

## 3. Pegá esto, exacto

```text
Read KICKOFF.md and create the complete game, no stop.
```

## Notas de grabación (pedidos de Joseph)

* **La instalación de xo se graba poco**: la están cambiando (hoy hay 4 descargas según sistema). Un plano corto del menú `Project > Tools > Install AI Agent Skills` alcanza.
* **No se muestra la ideación ni el playtesting con IA.** El agente igual verifica con capturas y `xo game eval` (es parte del build), pero en la edición eso no va: se muestra el juego armándose y Marco jugándolo.
* Juego normal de escritorio en Windows, nada de mobile ni Apple.
* Unity no se nombra; si se nombra, nunca como que Xogot se inspiró en Unity.

## Bueno saber

* **El agente arma todo sin frenar.** Solo te va a hablar si xo no puede llegar al editor después de reintentar.
* **Performance:** al final de cada hito (M2 a M8) mide FPS, draw calls, triángulos y VRAM con una ruta de cámara fija a 1920x1080 (objetivo 60 FPS en tu RTX 3060) y lo anota en `docs/records/PERFORMANCE.md`. Si no da, lo arregla antes de seguir.
* **Feedback para Joseph:** `docs/records/XO_FEEDBACK.md` junta cada error de xo, el workaround y lo que funcionó bien. Sale listo para mandárselo.
* El juego arranca **muteado**: `M` prende el sonido.
* Panel **F1** para la progresión en cámara (+100 / +1000 monedas, desbloquear el siguiente pad, arrancar el Kraken, time scale, borrar progreso). **F2** cámaras de las concepts, **F3** oculta el HUD.
* Tiempos de cada hito en `docs/records/MEASUREMENT_LOG.md`; el EXE sale en `build\donut-cove-windows\Donut Cove.exe`.
