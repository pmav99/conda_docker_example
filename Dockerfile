FROM continuumio/miniconda3:4.8.2@sha256:456e3196bf3ffb13fee7c9216db4b18b5e6f4d37090b31df3e0309926e98cfe2

# redsymbol.net/articles/unofficial-bash-strict-mode/
SHELL ["/bin/bash", "-xeuo", "pipefail", "-c"]

# Configure the container's behavior
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=off

# Configure apt
RUN echo 'APT::Install-Recommends "false";' | tee -a /etc/apt/apt.conf.d/99-install-suggests-recommends; \
    echo 'APT::Install-Suggests "false";' | tee -a /etc/apt/apt.conf.d/99-install-suggests-recommends; \
    echo 'Configuring apt: OK';

# Setup the locales
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en
RUN apt update; \
    apt upgrade -yq; \
    apt install -yq locales; \
    sed -i -e "s/# ${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen; \
    dpkg-reconfigure --frontend=noninteractive locales; \
    update-locale LANG=${LANG}; \
    apt autoremove -y; \
    find / -xdev -name *.pyc -delete; \
    rm -rf /var/lib/apt/lists/*; \
    echo 'Setting locales: OK';

# Setup the timezone
# ENV TZ=Etc/UTC
ENV TZ=Europe/Rome
RUN apt update; \
    apt install -yq tzdata; \
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime; \
    echo "${TZ}" | tee /etc/timezone; \
    dpkg-reconfigure tzdata; \
    apt autoremove -y; \
    find / -xdev -name *.pyc -delete; \
    rm -rf /var/lib/apt/lists/*; \
    echo 'Setting timezone: OK';

# Install tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Install gosu (and anything else you need from the apt repository)
RUN apt update; \
    apt install -yq \
        gosu \
        procps \
    ; \
    apt autoremove -y; \
    rm -rf /var/lib/apt/lists/*; \
    echo 'Installation of apt dependencies: OK';

# Create a normal user
# We will use this one to run the script
ARG USER_NAME=amigo
ARG USER_ID=1000
ARG GROUP_ID=1000

ENV USER_NAME=${USER_NAME}
ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV USER_HOME=/home/${USER_NAME}

RUN groupadd -g ${GROUP_ID} ${USER_NAME}; \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USER_NAME}; \
    echo "Creating user ${USER_NAME}: OK";

# Fix stupid conda permission errors
#RUN chown -R "${USER_ID}":"${GROUP_ID}" /opt/conda; \
    #echo 'Fix conda permissions: OK'

# Setup conda env (as the normal user; no need for root here)
COPY environment.yml /tmp/environment.yml
RUN gosu "${USER_ID}":"${GROUP_ID}" conda env create -f /tmp/environment.yml

# Entrypoint script
# we switch to root, but we will drop privileges within the entrypoint
COPY entrypoint.sh /usr/bin/entrypoint.sh
USER root
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

# The actual script that I want to run it's default arguments
COPY jeodpp_batch_runner.py /usr/bin/jeodpp_batch_runner.py
CMD ["--help"]
