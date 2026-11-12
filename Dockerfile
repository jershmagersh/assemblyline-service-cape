ARG branch=latest
FROM cccs/assemblyline-v4-service-base:$branch

# Python path to the service class from your service directory
ENV SERVICE_PATH cape.cape.CAPE

# Install apt dependencies
USER root
COPY pkglist.txt /tmp/setup/
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    $(grep -vE "^\s*(#|$)" /tmp/setup/pkglist.txt | tr "\n" " ") && \
    rm -rf /tmp/setup/pkglist.txt /var/lib/apt/lists/*

# Install python dependencies
USER assemblyline
COPY requirements.txt requirements.txt
RUN pip install \
    --no-cache-dir \
    --user \
    --requirement requirements.txt && \
    rm -rf ~/.cache/pip

# Copy only files required at runtime. Avoid copying reports, tests, editor
# settings, or other local build-context files into the image.
WORKDIR /opt/al_service
COPY cape cape
COPY service_manifest.yml service_manifest.yml

# Patch version in manifest
ARG version=1.0.0.dev1
USER root
RUN sed -i -e "s/\$SERVICE_TAG/$version/g" service_manifest.yml

# Switch to assemblyline user
USER assemblyline
