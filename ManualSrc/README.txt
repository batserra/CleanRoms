Fuente de los manuales PDF / Source of the PDF manuals
=======================================================

CleanROMs_Manual_EN.pdf and CleanROMs_Manual_ES.pdf are generated from the
two JSON files in this folder (manual_en.json, manual_es.json) with
build.py. To change the manual: edit the text in the JSON, then run

    pip install reportlab
    python build.py manual_en.json ../CleanROMs_Manual_EN.pdf "CleanROMs v{version} — User Manual" "CleanROMs v{version} — User Manual"
    python build.py manual_es.json ../CleanROMs_Manual_ES.pdf "CleanROMs v{version} — Manual de usuario" "CleanROMs v{version} — Manual de usuario"

{version} is replaced by the number in ..\VERSION. The cover subtitle
("Version 2.8") is plain text in the JSON: change it when you change VERSION.

Block types: title, subtitle, h1, h2, para, note, toc, code, table.
Each text block has "runs": [style, text] with style r (normal), b (bold),
i (italic), code, br (line break), sym / zapf (symbol fonts).

Los manuales PDF se generan a partir de los dos JSON de esta carpeta con
build.py. Para cambiar el manual: edita el texto del JSON y ejecuta los
comandos de arriba (necesita Python y reportlab). {version} se sustituye por
el número de ..\VERSION; el subtítulo de la portada ("Versión 2.8") es texto
normal del JSON: cámbialo cuando cambies VERSION.
