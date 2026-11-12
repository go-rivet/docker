# Rivet Multi-Arch Docker Deployment

This repository builds [go-rivet/rivet][rivet-url] images for Linux amd64, arm64, and arm/v7. All variants include the Lua runtime, built with cgo and Zig 0.14.1, statically linked with musl, and stripped:

- **`latest` / version tags**: scratch image for distributing the binary at `/rivet`. It has no CA certificates or external tools.
- **`latest-distroless` / version tags suffixed `-distroless`**: minimal non-root runtime with CA certificates, timezone data, and a writable `/tmp`. It has no shell or Git.
- **`latest-alpine` / version tags suffixed `-alpine`**: runtime with Bash, Git, and other utility tools.

The publishing workflow executes a Lua smoke test on every image and architecture and checks HTTPS Taskfile fetching in the distroless image before pushing.

## Usage

### Install Rivet from the Docker Image

```bash
# Extract the binary into your current directory
$ docker create --name temp-rivet ghcr.io/go-rivet/rivet:latest
$ docker cp temp-rivet:/rivet ./rivet
$ docker rm temp-rivet

# Verify it runs locally
$ ./rivet --version
```

### Use Rivet in a Multi-Stage Dockerfile

```dockerfile
FROM ghcr.io/go-rivet/rivet:latest AS rivet-bin

FROM alpine:3.20
COPY --from=rivet-bin /rivet /usr/local/bin/rivet
```

### Run a Taskfile with the Distroless Image

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace ghcr.io/go-rivet/rivet:latest-distroless
```

The image runs as UID/GID 65532; the mounted workspace must be writable by that user when tasks or remote Taskfile caching need to write files. Use the Alpine variant for tasks requiring external commands.

## Development

The Dockerfile can be built and tested locally via standard automation commands.

```bash
# Build Rivet Docker Image.
$ make build
$ make build RIVET_VERSION=v0.2.0

# Test the Docker images, including Lua execution.
$ make test

# Run a Rivet Docker Container.
$ make run

# Remove the locally built Rivet Docker Images.
$ make clean

# Other make commands:
$ make help
```

## License

This project is licensed under the MIT License. 

See the [LICENSE][license-url] file for the full license text.


[rivet-url]: https://github.com/go-rivet/rivet
[license-url]: LICENSE
