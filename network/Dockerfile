FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 libx11-6 libxcursor1 libxinerama1 libgl1 libxi6 libxrandr2 libasound2 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip -o /tmp/godot.zip && echo 'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4  /tmp/godot.zip' | sha256sum -c - && unzip /tmp/godot.zip -d /usr/local/bin && mv /usr/local/bin/Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot && rm /tmp/godot.zip
WORKDIR /app
COPY . /app
RUN godot --headless --editor --quit
ENV XDG_DATA_HOME=/tmp/godot-data XDG_CONFIG_HOME=/tmp/godot-config
USER 10001:10001
EXPOSE 9080
CMD ["godot","--headless","--script","network/arena_server.gd","--","--port=9080"]
