#!/bin/sh
npx -p sass sass --watch -s compressed src/style.sass:static/style.css & npx esbuild --bundle src/client.js --outfile=static/client.js --sourcemap --minify --watch