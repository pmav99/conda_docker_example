FROM debian:10.4@sha256:aaaaf56b44807c64d294e6c8059b479f35350b454492398225034174808d1726

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


# Install gosu (and anything else you need from the apt repository)
RUN apt update; \
    apt install -yq \
        bzip2 \
        ca-certificates \
        git \
        gosu \
        procps \
        wget \
        file \
    ; \
    apt autoremove -y; \
    rm -rf /var/lib/apt/lists/*; \
    echo 'Installation of apt dependencies: OK';

# Install tini
ENV TINI_VERSION v0.19.0
RUN wget https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -O /usr/bin/tini; \
    chmod +x /usr/bin/tini; \
    echo 'tini installation: OK'

# Create a normal user
# We will use this one to run the script
ARG USER_NAME
ARG USER_ID
ARG GROUP_ID

ENV USER_NAME=${USER_NAME}
ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV USER_HOME=/home/${USER_NAME}

RUN groupadd -g ${GROUP_ID} ${USER_NAME}; \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USER_NAME}; \
    echo "Creating user ${USER_NAME}: OK";
 \
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh -O /tmp/miniconda.sh; \
    echo 751786b92c00b1aeae3f017b781018df /tmp/miniconda.sh | md5sum --check - ; \
    chmod +x /tmp/miniconda.sh; \
    mkdir /opt/conda; \
    chown -R "${USER_ID}":"${GROUP_ID}" /opt/conda; \
    gosu "${USER_NAME}" /bin/bash /tmp/miniconda.sh -b -f -p /opt/conda; \
    rm -rf /tmp/miniconda.sh; \
    gosu "${USER_NAME}" /opt/conda/bin/conda clean -tipsy; \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh; \
    echo "source /opt/conda/etc/profile.d/conda.sh" | gosu "${USER_NAME}" tee -a "${USER_HOME}"/.bashrc; \
    echo "conda activate base"                      | gosu "${USER_NAME}" tee -a "${USER_HOME}"/.bashrc; \
    find /opt/conda/ -follow -type f -name '*.a' -delete; \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete; \
    /opt/conda/bin/conda clean -afy; \
    echo 'Conda setup: OK'

ENV PATH=/opt/conda/bin:"${PATH}"

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
