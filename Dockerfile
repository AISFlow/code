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
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential g++ pkg-config wget curl \
        unzip tar ffmpeg fonts-dejavu fontconfig \
        libpq-dev libx11-dev libxkbfile-dev \
        libsecret-1-dev libkrb5-dev \
        locales dumb-init procps \
        git git-lfs htop lsb-release \
        zip unzip \
        man-db openssh-client sudo nano \
        vim-tiny zsh jq python-is-python3 \
        texlive-full \
        texlive-xetex texlive-fonts-recommended \
        texlive-plain-generic ko.tex fonts-noto-cjk-extra && \
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
# Stage: MeCab Setup
# ─────────────────────────────
FROM base AS mecab
USER root
# Define the MeCab release version
ENV MECAB_RELEASE=release-0.999
RUN dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
        amd64) mecabArch='x86_64' ;; \
        arm64) mecabArch='aarch64' ;; \
        *) echo >&2 "Unsupported architecture: ${dpkgArch}" && exit 1 ;; \
    esac && \
    mecabKoUrl="https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-linux-${mecabArch}.tar.gz" && \
    mecabKoDicUrl="https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-dic.tar.gz" && \
    wget --quiet "${mecabKoUrl}" -O - | tar -xzvf - -C /opt && \
    wget --quiet "${mecabKoDicUrl}" -O - | tar -xzvf - -C /opt/mecab/share && \
    chmod -R 755 /opt/mecab

# ─────────────────────────────
# Stage: Fonts Setup
# ─────────────────────────────
FROM base AS fonts
USER root
# Define font version arguments
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
        wget --quiet -O "${font_dir}/${font_name}" "https://raw.githubusercontent.com/google/fonts/17216f1645a133dbbeaa506f0f63f701861b6c7b/ofl/${relative_path}/${encoded_font_name}"; \
    }; \
    \
    # Install the D2Coding font
    mkdir -p /usr/share/fonts/truetype/D2Coding && \
        wget --quiet -O /usr/share/fonts/truetype/D2Coding.zip "https://github.com/naver/d2codingfont/releases/download/VER${D2CODING_VERSION}/D2Coding-Ver${D2CODING_VERSION}-${D2CODING_DATE}.zip" && \
        unzip /usr/share/fonts/truetype/D2Coding.zip -d /usr/share/fonts/truetype/ && \
    rm /usr/share/fonts/truetype/D2Coding.zip && \
    \
    # Install the D2Coding Nerd font
    mkdir -p /usr/share/fonts/truetype/D2CodingNerd && \
    wget --quiet -O /usr/share/fonts/truetype/D2CodingNerd/D2CodingNerd.ttf "https://github.com/kelvinks/D2Coding_Nerd/raw/master/D2Coding%20v.${D2CODING_NERD_VERSION}%20Nerd%20Font%20Complete.ttf" && \
    \
    # Install the Pretendard and PretendardJP fonts
    mkdir -p /usr/share/fonts/truetype/Pretendard && \
        wget --quiet -O /usr/share/fonts/truetype/Pretendard.zip "https://github.com/orioncactus/pretendard/releases/download/v${PRETENDARD_VERSION}/Pretendard-${PRETENDARD_VERSION}.zip" && \
        unzip /usr/share/fonts/truetype/Pretendard.zip -d /usr/share/fonts/truetype/Pretendard/ && \
    rm /usr/share/fonts/truetype/Pretendard.zip && \
    mkdir -p /usr/share/fonts/truetype/PretendardJP && \
        wget --quiet -O /usr/share/fonts/truetype/PretendardJP.zip "https://github.com/orioncactus/pretendard/releases/download/v${PRETENDARD_VERSION}/PretendardJP-${PRETENDARD_VERSION}.zip" && \
        unzip /usr/share/fonts/truetype/PretendardJP.zip -d /usr/share/fonts/truetype/PretendardJP/ && \
    rm /usr/share/fonts/truetype/PretendardJP.zip && \
    \
    # Install Noto fonts
        install_google_font "notosans" "NotoSans[wdth,wght].ttf" && \
        install_google_font "notosans" "NotoSans-Italic[wdth,wght].ttf" && \
        install_google_font "notoserif" "NotoSerif[wdth,wght].ttf" && \
        install_google_font "notoserif" "NotoSerif-Italic[wdth,wght].ttf" && \
        install_google_font "notosanskr" "NotoSansKR[wght].ttf" && \
        install_google_font "notoserifkr" "NotoSerifKR[wght].ttf" && \
        install_google_font "notosansjp" "NotoSansJP[wght].ttf" && \
        install_google_font "notoserifjp" "NotoSerifJP[wght].ttf" && \
    \
    # Install Nanum fonts
        install_google_font "nanumbrushscript" "NanumBrushScript-Regular.ttf" && \
        install_google_font "nanumgothic" "NanumGothic-Bold.ttf" && \
        install_google_font "nanumgothic" "NanumGothic-ExtraBold.ttf" && \
        install_google_font "nanumgothic" "NanumGothic-Regular.ttf" && \
        install_google_font "nanumgothiccoding" "NanumGothicCoding-Bold.ttf" && \
        install_google_font "nanumgothiccoding" "NanumGothicCoding-Regular.ttf" && \
        install_google_font "nanummyeongjo" "NanumMyeongjo-Bold.ttf" && \
        install_google_font "nanummyeongjo" "NanumMyeongjo-ExtraBold.ttf" && \
        install_google_font "nanummyeongjo" "NanumMyeongjo-Regular.ttf" && \
    \
    # Install IBM Plex fonts
        install_google_font "ibmplexmono" "IBMPlexMono-Bold.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-BoldItalic.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-ExtraLight.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-ExtraLightItalic.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-Italic.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-Light.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-LightItalic.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-Medium.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-MediumItalic.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-Regular.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-SemiBold.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-SemiBoldItalic.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-Thin.ttf" && \
        install_google_font "ibmplexmono" "IBMPlexMono-ThinItalic.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-Bold.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-ExtraLight.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-Light.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-Medium.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-Regular.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-SemiBold.ttf" && \
        install_google_font "ibmplexsanskr" "IBMPlexSansKR-Thin.ttf" && \
    \
    # Set font permissions and update the cache
    chmod -R 644 /usr/share/fonts/truetype/* && \
    find /usr/share/fonts/truetype/ -type d -exec chmod 755 {} + && \
    fc-cache -f -v

# ─────────────────────────────
# Stage: Builder Stage (Integrates All Components)
# ─────────────────────────────
FROM base AS builder
USER root
# Copy the fix-permissions script and set its execution permission
COPY --chmod=775 fix-permissions /usr/local/bin/fix-permissions

# Copy components from parallel stages
COPY --link --from=mecab /opt/mecab /opt/mecab

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

# Install VS Code extensions
RUN code-server --install-extension ms-python.python && \
    code-server --install-extension ms-python.pylint && \
    code-server --install-extension ms-toolsai.jupyter

# ─────────────────────────────
# Stage: Runtime Stage
# ─────────────────────────────
FROM base AS runtime
ENV NODE_ENV=production
# Copy files from the builder stage
COPY --link --from=builder /opt/mecab /opt/mecab
COPY --link --from=builder /home/code /home/code
COPY --link --from=builder --chmod=775 /usr/local/bin/fix-permissions /usr/local/bin/fix-permissions
COPY --link --from=fonts /usr/share/fonts /usr/share/fonts

# Expose the Code‑Server port and define a volume for persistent data
EXPOSE 8080
VOLUME [ "/home/code/" ]
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "."]
