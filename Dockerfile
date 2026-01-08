
# syntax=docker/dockerfile:1

FROM emscripten/emsdk:3.1.56 AS build

WORKDIR /work

# Autotools toolchain needed by scripts/build.sh (autoreconf + configure + make)
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		libtool \
		make \
		pkg-config \
		python3 \
	&& rm -rf /var/lib/apt/lists/*

COPY . .

RUN chmod +x scripts/*.sh
RUN ./scripts/build.sh

# Collect the web runtime assets.
RUN mkdir -p /out \
	&& cp -av \
		src/index.html \
		src/default.cfg \
		src/websockets-doom.* \
		/out/ \
	&& if [ -f src/doom1.wad ]; then cp -av src/doom1.wad /out/; fi


FROM nginx:alpine AS runtime

# Serve on port 8000 (matches README) and ensure a wasm MIME type exists.
RUN rm -f /etc/nginx/conf.d/default.conf \
	&& printf '%s\n' \
		'server {' \
		'  listen 8000;' \
		'  server_name _;' \
		'  root /usr/share/nginx/html;' \
		'  include /etc/nginx/mime.types;' \
		'  types { application/wasm wasm; }' \
		'  location / { try_files $uri $uri/ =404; }' \
		'}' \
		> /etc/nginx/conf.d/default.conf

COPY --from=build /out/ /usr/share/nginx/html/

EXPOSE 8000

CMD ["nginx", "-g", "daemon off;"]
