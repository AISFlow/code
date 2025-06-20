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
    locales default-jdk \
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
# Stage 2: Fonts (root)
# ─────────────────────────────
FROM base AS fonts
USER root
ARG D2CODING_VERSION=1.3.2
ARG D2CODING_DATE=20180524
ARG D2CODING_NERD_VERSION=1.3.2
ARG PRETENDARD_VERSION=1.3.9

RUN set -eux; \
    install_google_font() { \
      local relative_path="$1"; local font_name="$2"; \
      local font_dir="/usr/share/fonts/truetype/${relative_path}"; \
      mkdir -p "${font_dir}" && \
      local encoded_font_name=$(printf "%s" "${font_name}" | jq -sRr @uri); \
      wget --quiet -O "${font_dir}/${font_name}" \
          "https://raw.githubusercontent.com/google/fonts/17216f1645a133dbbeaa506f0f63f701861b6c7b/ofl/${relative_path}/${encoded_font_name}"; \
    }; \
    \
    mkdir -p /usr/share/fonts/truetype/D2Coding && \
      wget --quiet -O /usr/share/fonts/truetype/D2Coding.zip \
        "https://github.com/naver/d2codingfont/releases/download/VER${D2CODING_VERSION}/D2Coding-Ver${D2CODING_VERSION}-${D2CODING_DATE}.zip" && \
      unzip /usr/share/fonts/truetype/D2Coding.zip -d /usr/share/fonts/truetype/ && \
      rm /usr/share/fonts/truetype/D2Coding.zip; \
    mkdir -p /usr/share/fonts/truetype/D2CodingNerd && \
      wget --quiet -O /usr/share/fonts/truetype/D2CodingNerd/D2CodingNerd.ttf \
        "https://github.com/kelvinks/D2Coding_Nerd/raw/master/D2Coding%20v.${D2CODING_NERD_VERSION}%20Nerd%20Font%20Complete.ttf"; \
    mkdir -p /usr/share/fonts/truetype/Pretendard && \
      wget --quiet -O /usr/share/fonts/truetype/Pretendard.zip \
        "https://github.com/orioncactus/pretendard/releases/download/v${PRETENDARD_VERSION}/Pretendard-${PRETENDARD_VERSION}.zip" && \
      unzip /usr/share/fonts/truetype/Pretendard.zip -d /usr/share/fonts/truetype/Pretendard/ && \
      rm /usr/share/fonts/truetype/Pretendard.zip; \
    mkdir -p /usr/share/fonts/truetype/PretendardJP && \
      wget --quiet -O /usr/share/fonts/truetype/PretendardJP.zip \
        "https://github.com/orioncactus/pretendard/releases/download/v${PRETENDARD_VERSION}/PretendardJP-${PRETENDARD_VERSION}.zip" && \
      unzip /usr/share/fonts/truetype/PretendardJP.zip -d /usr/share/fonts/truetype/PretendardJP/ && \
      rm /usr/share/fonts/truetype/PretendardJP.zip; \
    \
    install_google_font "notosans" "NotoSans[wdth,wght].ttf"; \
    install_google_font "notosans" "NotoSans-Italic[wdth,wght].ttf"; \
    install_google_font "notoserif" "NotoSerif[wdth,wght].ttf"; \
    install_google_font "notoserif" "NotoSerif-Italic[wdth,wght].ttf"; \
    install_google_font "notosanskr" "NotoSansKR[wght].ttf"; \
    install_google_font "notoserifkr" "NotoSerifKR[wght].ttf"; \
    install_google_font "notosansjp" "NotoSansJP[wght].ttf"; \
    install_google_font "notoserifjp" "NotoSerifJP[wght].ttf"; \
    install_google_font "notoemoji" "NotoEmoji[wght].ttf"; \
    install_google_font "notocoloremoji" "NotoColorEmoji-Regular.ttf"; \
    \
    install_google_font "nanumbrushscript" "NanumBrushScript-Regular.ttf"; \
    install_google_font "nanumgothic" "NanumGothic-Bold.ttf"; \
    install_google_font "nanumgothic" "NanumGothic-ExtraBold.ttf"; \
    install_google_font "nanumgothic" "NanumGothic-Regular.ttf"; \
    install_google_font "nanumgothiccoding" "NanumGothicCoding-Bold.ttf"; \
    install_google_font "nanumgothiccoding" "NanumGothicCoding-Regular.ttf"; \
    install_google_font "nanummyeongjo" "NanumMyeongjo-Bold.ttf"; \
    install_google_font "nanummyeongjo" "NanumMyeongjo-ExtraBold.ttf"; \
    install_google_font "nanummyeongjo" "NanumMyeongjo-Regular.ttf"; \
    \
    install_google_font "ibmplexmono" "IBMPlexMono-Bold.ttf"; \
    install_google_font "ibmplexmono" "IBMPlexMono-Regular.ttf"; \
    install_google_font "ibmplexsanskr" "IBMPlexSansKR-Bold.ttf"; \
    install_google_font "ibmplexsanskr" "IBMPlexSansKR-Regular.ttf"; \
    \
    chmod -R 644 /usr/share/fonts/truetype/* && \
    find /usr/share/fonts/truetype/ -type d -exec chmod 755 {} + && \
    fc-cache -f -v

# ─────────────────────────────
# Stage 3: Builder
# ─────────────────────────────
FROM base AS builder
USER root
COPY --chmod=775 fix-permissions /usr/local/bin/fix-permissions
USER ${UID}

RUN uv init --python 3.12.9 --bare && \
    uv venv --python 3.12.9 --seed

RUN uv add \
      grpcio-status grpcio pandas>=2.2.3 numpy pyarrow \
      transformers datasets tokenizers nltk jax jaxlib optax \
      pandas-datareader psycopg2 pymysql pymongo sqlalchemy \
      sentencepiece seqeval wordcloud tweepy gradio \
      dash streamlit tensorflow seaborn torch \
      line-profiler memory-profiler yfinance \
      python-mecab-ko soynlp statsmodels networkx mplcairo \
      konlpy dart-fss opendartreader finance-datareader \
      elasticsearch elasticsearch-dsl \
      "nvidia-cudnn-cu12>=9.5.0.50" \
      ipykernel mobilechelonian selenium nbconvert[webpdf] \
      jupyterlab jupyterlab_rise thefuzz ipympl \
      jupyterlab-latex jupyterlab-katex ipydatagrid \
      jupyterlab-language-pack-ko-KR \
      https://github.com/AISFlow/nbconvert.git

RUN set -eux; \
    EXTENSIONS="ms-python.python ms-python.pylint ms-toolsai.jupyter charliermarsh.ruff esbenp.prettier-vscode anwar.papyrus-pdf mechatroner.rainbow-csv cweijan.vscode-office"; \
    for EXT in $EXTENSIONS; do \
      for i in $(seq 1 5); do \
        if code-server --install-extension "${EXT}"; then \
          break; \
        else \
          sleep 10; \
        fi; \
      done; \
    done

RUN uv cache clean && \
    rm -rf \
      ~/.cache ~/.npm ~/.pnpm ~/.nv \
      ~/.local/state \
      ~/.local/share/uv \
      ~/.local/share/code-server/CachedExtensionVSIXs \
      ~/.local/share/code-server/User/globalStorage \
      ~/.local/share/code-server/User/workspaceStorage \
      ~/.config/code-server \
      ~/.jupyter ~/.ipython \
      $(find ~/.venv -type d -name '__pycache__')

RUN echo 'if [ -f "/home/${USER}/.venv/bin/activate" ]; then source "/home/${USER}/.venv/bin/activate"; fi' >> /home/${USER}/.bash_env

# ─────────────────────────────
# Stage 4: Runtime
# ─────────────────────────────
FROM base AS runtime

ENV NODE_ENV=production

COPY --link --chown=${UID}:${GID} presettings/vscode-settings.json /home/${USER}/.local/share/code-server/User/settings.json

COPY --link --chown=${UID}:${GID} presettings/matplotlibrc /home/${USER}/.config/matplotlib/matplotlibrc

COPY --link --chown=${UID}:${GID} --from=builder /home/${USER}/ /home/${USER}/

COPY --link --chown=${UID}:${GID} endeavour /usr/bin/endeavour

COPY --link --chmod=775 --from=builder /usr/local/bin/fix-permissions /usr/local/bin/fix-permissions

COPY --link --chmod=775 --from=ghcr.io/aisflow/dockerised-mecab-ko:20250319-190826 /opt/mecab/ /opt/mecab/

COPY --link --chmod=775 --from=fonts /usr/share/fonts/ /usr/share/fonts/

USER root

EXPOSE 8080
ENTRYPOINT [ "tini", "--", "/opt/nvidia/nvidia_entrypoint.sh" ]
CMD [ "endeavour" ]
