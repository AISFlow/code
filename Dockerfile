# ─────────────────────────────
# Stage 1: Base
# ─────────────────────────────
FROM nvidia/cuda:12.9.0-cudnn-runtime-ubuntu24.04 AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV TZ="Asia/Seoul" \
    DEBIAN_FRONTEND=noninteractive \
    USER=code \
    UID=1001 \
    GID=1001 \
    GOSU_VERSION=1.17 \
    TINI_VERSION=v0.19.0

ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8

RUN set -eux; \
    rm -rf /etc/apt/sources.list.d/cuda.list; \
    apt-get update -yq; \
    apt-get install -yq --no-install-recommends \
    locales \
    build-essential g++ pkg-config wget curl unzip tar \
    ffmpeg fonts-dejavu fontconfig \
    libpq-dev libx11-dev libxkbfile-dev libsecret-1-dev libkrb5-dev \
    clang dumb-init procps pandoc git git-lfs htop lsb-release \
    zip openssh-client sudo nano vim zsh jq \
    texlive-xetex texlive-fonts-recommended texlive-plain-generic \
    ko.tex fonts-noto-cjk texlive-lang-korean \
    texlive-lang-chinese texlive-lang-japanese \
    screen tree libcairo2-dev pkg-config \
    ca-certificates gnupg; \
    \
    sed -i 's/^# \(ko_KR.UTF-8 UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen; \
    update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/bin/tini "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$dpkgArch"; \
    wget -O /usr/bin/tini.asc "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7; \
    gpg --batch --verify /usr/bin/tini.asc /usr/bin/tini; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/bin/tini.asc; \
    chmod +x /usr/bin/tini; \
    tini --version; \
    \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; gosu nobody true; \
    \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    groupadd --gid ${GID} ${USER}; \
    useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USER}; \
    echo "code ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER ${USER}
WORKDIR /home/${USER}
ENV BASH_ENV="/home/${USER}/.bash_env"

RUN touch "${BASH_ENV}" && echo '. "${BASH_ENV}"' >> ~/.bashrc

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | PROFILE="${BASH_ENV}" bash && \
    source ${BASH_ENV} && nvm install 20 && nvm use 20 && \
    npm install -g pnpm@latest-10 && npm cache clean --force

RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    export PATH="$HOME/.local/bin:$PATH" && \
    uv python install 3.12.9 --default --preview && \
    uv tool update-shell

ENV PNPM_HOME="/home/${USER}/.pnpm/store"
ENV PATH="/home/${USER}/.local/bin:${PNPM_HOME}:${PATH}"

RUN python --version && \
    which python && \
    python -c "import sys; print(sys.executable, sys.version, sys.platform)"

RUN curl -fsSL https://code-server.dev/install.sh | sh && \
    rm -rf ~/.cache/code-server

# ─────────────────────────────
# Stage 2: Builder
# ─────────────────────────────
FROM base AS builder
USER root
COPY --chmod=775 fix-permissions /usr/local/bin/fix-permissions
USER ${UID}

RUN uv init --python 3.12.9 --bare && \
    uv venv --python 3.12.9 --seed

RUN uv add \
     grpcio-status grpcio pandas>=2.2.3 pyarrow \
     transformers datasets tokenizers nltk jax jaxlib optax \
     pandas-datareader psycopg2 pymysql pymongo sqlalchemy \
     sentencepiece seqeval wordcloud tweepy gradio \
     dash streamlit tensorflow seaborn \
     line-profiler memory-profiler \
     python-mecab-ko soynlp statsmodels networkx mplcairo \
     konlpy dart-fss opendartreader finance-datareader \
     elasticsearch elasticsearch-dsl \
     "nvidia-cudnn-cu12>=9.5.0.50" \
     ipykernel mobilechelonian selenium nbconvert[webpdf] \
     jupyterlab jupyterlab_rise thefuzz ipympl \
     jupyterlab-latex jupyterlab-katex ipydatagrid \
     jupyterlab-language-pack-ko-KR sas_kernel \
     https://github.com/AISFlow/nbconvert.git

COPY presettings/matplotlibrc /home/code/.config/matplotlib/matplotlibrc

RUN mkdir -p /home/code/.local/share/code-server/User/
COPY presettings/vscode-settings.json /home/code/.local/share/code-server/User/settings.json

RUN uv cache clean

RUN set -eux; \
    EXTENSIONS="ms-python.python ms-python.pylint ms-toolsai.jupyter esbenp.prettier-vscode anwar.papyrus-pdf mechatroner.rainbow-csv cweijan.vscode-office"; \
    for EXT in $EXTENSIONS; do \
      for i in $(seq 1 5); do \
        if code-server --install-extension "${EXT}"; then \
          break; \
        else \
          sleep 10; \
        fi; \
      done; \
    done

RUN rm -rf /home/code/.cache

RUN echo 'if [ -f "/home/code/.venv/bin/activate" ]; then source "/home/code/.venv/bin/activate"; fi' >> /home/code/.bash_env

# ─────────────────────────────
# Stage 3: Runtime
# ─────────────────────────────
FROM base AS runtime

ENV NODE_ENV=production

COPY --link --chown=1001:1001 --from=builder /home/code /home/code
COPY --link --chown=1001:1001 --from=builder --chmod=775 /usr/local/bin/fix-permissions /usr/local/bin/fix-permissions
COPY --link --from=ghcr.io/aisflow/dockerised-mecab-ko:20250319-190826 /opt/mecab /opt/mecab
COPY --link --from=ghcr.io/aisflow/dockerised-fonts:20250605-212200 /usr/share/fonts /usr/share/fonts
COPY --link --chown=1001:1001 endeavour /usr/bin/endeavour

USER root

EXPOSE 8080
ENTRYPOINT [ "tini", "--", "/opt/nvidia/nvidia_entrypoint.sh" ]
CMD [ "endeavour" ]
