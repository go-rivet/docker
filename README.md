# Rivet Multi-Arch Docker Deployment

This repository automates the deployment of the [go-rivet/rivet][rivet-url] binary as a minimal `scratch` Docker image. It builds multi-architecture Docker images.

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

## Development

The Dockerfile can be built and tested locally via standard automation commands.

```bash
# Build Rivet Docker Image.
$ make build
$ make build RIVET_VERSION=v0.2.0

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
