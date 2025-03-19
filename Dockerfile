# ─────────────────────────────
# Stage: Base Image with Essential Tools
# ─────────────────────────────
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04 AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set localisation, non-interactive mode, and other environment variables
ENV TZ="Asia/Seoul" \
    LANG=ko_KR.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    USER=code \
    UID=1001 \
    GID=1001

# Install essential commands and tools, and create group and user
RUN rm -rf /etc/apt/sources.list.d/cuda.list && \
    apt-get update -yq && \
    apt-get install -yq --no-install-recommends \
        build-essential g++ pkg-config wget curl \
        unzip tar ffmpeg fonts-dejavu fontconfig \
        libpq-dev libx11-dev libxkbfile-dev \
        libsecret-1-dev libkrb5-dev \
        locales dumb-init procps pandoc \
        git git-lfs htop lsb-release \
        zip unzip openssh-client sudo nano \
        vim zsh jq python-is-python3 \
        texlive-xetex texlive-fonts-recommended \
        ko.tex fonts-noto-cjk texlive-lang-korean \
        texlive-lang-chinese texlive-lang-japanese && \
    curl https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb \
    --output cuda-keyring_1.1-1_all.deb && \
        apt-key del A4B469963BF863CC && \
            dpkg -i cuda-keyring_1.1-1_all.deb && \
            rm -rf cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    groupadd --gid ${GID} ${USER} && \
    useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USER} && \
    echo "code ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd && \
    sed -i "s/# ko_KR.UTF-8/ko_KR.UTF-8/" /etc/locale.gen && \
    locale-gen

# Switch to the non-root user and set the working directory
USER ${USER}
WORKDIR /home/${USER}
ENV BASH_ENV="/home/${USER}/.bash_env"
RUN touch "${BASH_ENV}" && echo '. "${BASH_ENV}"' >> ~/.bashrc

# Download and install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | PROFILE="${BASH_ENV}" bash
RUN echo node > .nvmrc
RUN nvm install 20
RUN npm install -g pnpm@latest-10 \
    && npm cache clean --force

ENV PNPM_HOME="~/.pnpm/store"
ENV PATH="$PNPM_HOME:/home/${USER}/.local/bin:$PATH"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv python install 3.12.9 --default --preview && \
    uv tool update-shell && \
    curl -fsSL https://code-server.dev/install.sh | sh && \
    rm -rf /home/${USER}/.cache/code-server

# ─────────────────────────────
# Stage: Builder Stage (Integrates All Components)
# ─────────────────────────────
FROM base AS builder
USER root
# Copy the fix-permissions script and set its execution permission
COPY --chmod=775 fix-permissions /usr/local/bin/fix-permissions

# Additional Python and project environment configuration
USER ${UID}

# Install uv and configure the Python environment
RUN uv init --python 3.12.9 --bare && \
    uv venv --python 3.12.9 --seed

RUN uv add \
         grpcio-status grpcio pandas==2.2.3 pyarrow \
         transformers datasets tokenizers nltk jax jaxlib optax \
         pandas-datareader psycopg2 pymysql pymongo sqlalchemy \
         sentencepiece seqeval wordcloud tweepy gradio \
         dash streamlit tensorflow seaborn \
         line-profiler memory-profiler \
         konlpy dart-fss opendartreader finance-datareader \
         elasticsearch elasticsearch-dsl \
         "nvidia-cudnn-cu12>=9.5.0.50" \
         ipykernel mobilechelonian selenium nbconvert[webpdf] \
         jupyterlab jupyterlab_rise thefuzz ipympl \
         jupyterlab-latex jupyterlab-katex ipydatagrid \
         jupyterlab-language-pack-ko-KR sas_kernel \
         https://github.com/AISFlow/nbconvert.git && \
    mkdir -p /home/code/.config/matplotlib/ && \
    { \
         echo "# Default font family"; \
         echo "font.family: \"Pretendard\""; \
         echo ""; \
         echo "# Sans-serif fonts"; \
         echo "font.sans-serif: \"Pretendard Variable\", Pretendard, \"Pretendard JP Variable\", \"Pretendard JP\", \"Noto Sans KR\", \"Noto Sans JP\", \"IBM Plex Sans KR\", \"IBM Plex Sans\", \"DejaVu Sans\", \"Liberation Sans\", \"Nimbus Sans\", \"Ubuntu\""; \
         echo ""; \
         echo "# Serif fonts"; \
         echo "font.serif: \"Noto Serif KR\", \"Noto Serif JP\", \"IBM Plex Serif\", \"STIXGeneral\", \"Liberation Serif\", \"DejaVu Serif\", \"Nimbus Roman\""; \
         echo ""; \
         echo "# Monospace fonts"; \
         echo "font.monospace: \"D2Coding\", \"Noto Sans Mono\", \"IBM Plex Mono\", \"Noto Sans JP\", \"DejaVu Sans Mono\", \"Liberation Mono\", \"Source Code Pro\", \"Ubuntu Mono\""; \
         echo ""; \
         echo "# Cursive fonts"; \
         echo "font.cursive: \"Nanum Brush Script\", \"Noto Serif KR\", \"Noto Serif JP\", \"IBM Plex Serif\", \"Liberation Serif\", \"Nimbus Roman\", cursive"; \
         echo ""; \
         echo "# Fantasy fonts"; \
         echo "font.fantasy: \"Noto Sans KR\", \"Noto Sans JP\", \"IBM Plex Sans\", \"Nimbus Sans\", fantasy"; \
    } > /home/code/.config/matplotlib/matplotlibrc && \
    mkdir -p /home/code/.local/share/code-server/User/ && \
    echo "{\"workbench.colorTheme\": \"Visual Studio Dark\"}" > /home/code/.local/share/code-server/User/settings.json && \
    uv cache clean && \
    uv sync --compile-bytecode

# Install VS Code extensions with retry logic
RUN set -eux; \
    EXTENSIONS="ms-python.python ms-python.pylint ms-toolsai.jupyter esbenp.prettier-vscode"; \
    for EXT in $EXTENSIONS; do \
      echo "Installing ${EXT}..."; \
      for i in $(seq 1 5); do \
        if code-server --install-extension "${EXT}"; then \
          echo "Successfully installed ${EXT}."; \
          break; \
        else \
          echo "Installation failed for ${EXT} on attempt ${i} of 5. Retrying in 15 seconds..."; \
          sleep 15; \
        fi; \
      done; \
    done

# ─────────────────────────────
# Stage: Runtime Stage
# ─────────────────────────────
FROM base AS runtime
ENV NODE_ENV=production

# Copy files from the builder stage
COPY --link --from=builder /home/code /home/code
COPY --link --from=builder --chmod=775 /usr/local/bin/fix-permissions /usr/local/bin/fix-permissions
COPY --link --from=aisflow/dockerised-mecab-ko:0.1.0 /opt/mecab /opt/mecab
COPY --link --from=aisflow/dockerised-fonts:0.1.0 /fonts /usr/share/fonts/truetype

# Expose the Code‑Server port and define a volume for persistent data
EXPOSE 8080
VOLUME [ "/home/code/" ]
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "."]
