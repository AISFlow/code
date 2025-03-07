# syntax=docker/dockerfile:1

###############################
# Build Base Image
###############################
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04

###############################
# Root Settings & Initial Setup
###############################
USER root
ENV CODE_SERVER_VERSION=4.97.2 \
    TZ="Asia/Seoul" \
    DEBIAN_FRONTEND=noninteractive \
    PNPM_HOME="/pnpm" \
    PATH="$PNPM_HOME:$PATH" \
    USER=code \
    UID=1001 \
    GID=1001

# Copy custom permission fix script and set execution permission
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod +x /usr/local/bin/fix-permissions

# Create group and user
RUN groupadd --gid ${GID} ${USER} \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USER}

###############################
# Install System Dependencies
###############################
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
         ffmpeg \
         fonts-dejavu \
         gfortran \
         g++ \
         gcc \
         jq \
         libpq-dev \
         locales \
         fontconfig \
         unzip \
         build-essential \
         wget \
         tar \
         curl && \
    rm -rf /var/lib/apt/lists/*

###############################
# Additional Build Arguments
###############################
ARG D2CODING_VERSION=1.3.2
ARG D2CODING_NERD_VERSION=1.3.2
ARG D2CODING_DATE=20180524
ARG PRETENDARD_VERSION=1.3.9
ARG MECAB_RELEASE=release-0.999

###############################
# Install Code-Server
###############################
RUN dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch}" in \
        amd64) codeServerUrl="https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" ;; \
        arm64) codeServerUrl="https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-arm64.tar.gz" ;; \
        *) echo >&2 "Unsupported architecture: ${dpkgArch}" && exit 1 ;; \
    esac && \
    mkdir -p /usr/lib/code-server && \
    wget --quiet "${codeServerUrl}" -O - | tar -xzvf - -C /usr/lib/code-server --strip-components=1 && \
    ln -sf /usr/lib/code-server/bin/code-server /usr/bin/code-server && \
    chmod +x /usr/bin/code-server

###############################
# Install Fonts & MeCab Korean Support
###############################
RUN set -eux; \
    install_google_font() { \
        local relative_path="$1"; local font_name="$2"; \
        local font_dir="/usr/share/fonts/truetype/${relative_path}"; \
        mkdir -p "${font_dir}" && \
        local encoded_font_name=$(printf "%s" "${font_name}" | jq -sRr @uri); \
        wget --quiet -O "${font_dir}/${font_name}" "https://raw.githubusercontent.com/google/fonts/17216f1645a133dbbeaa506f0f63f701861b6c7b/ofl/${relative_path}/${encoded_font_name}"; \
    }; \
    \
    # Install D2Coding font
    mkdir -p /usr/share/fonts/truetype/D2Coding && \
    wget --quiet -O /usr/share/fonts/truetype/D2Coding.zip "https://github.com/naver/d2codingfont/releases/download/VER${D2CODING_VERSION}/D2Coding-Ver${D2CODING_VERSION}-${D2CODING_DATE}.zip" && \
    unzip /usr/share/fonts/truetype/D2Coding.zip -d /usr/share/fonts/truetype/ && \
    rm /usr/share/fonts/truetype/D2Coding.zip && \
    \
    # Install D2Coding Nerd font
    mkdir -p /usr/share/fonts/truetype/D2CodingNerd && \
    wget --quiet -O /usr/share/fonts/truetype/D2CodingNerd/D2CodingNerd.ttf "https://github.com/kelvinks/D2Coding_Nerd/raw/master/D2Coding%20v.${D2CODING_NERD_VERSION}%20Nerd%20Font%20Complete.ttf" && \
    \
    # Install Pretendard & PretendardJP fonts
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
    # Set font permissions and update cache
    chmod -R 644 /usr/share/fonts/truetype/* && \
    find /usr/share/fonts/truetype/ -type d -exec chmod 755 {} + && \
    fc-cache -f -v && \
    \
    # Install MeCab Korean support
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) mecabArch='x86_64' ;; \
        arm64) mecabArch='aarch64' ;; \
        *) echo >&2 "Unsupported architecture: ${dpkgArch}" && exit 1 ;; \
    esac; \
    mecabKoUrl="https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-linux-${mecabArch}.tar.gz"; \
    mecabKoDicUrl="https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-dic.tar.gz"; \
    wget --quiet "${mecabKoUrl}" -O - | tar -xzvf - -C /opt; \
    wget --quiet "${mecabKoDicUrl}" -O - | tar -xzvf - -C /opt/mecab/share; \
    fix-permissions "/opt/mecab"

###############################
# Switch to Non-root User & Python Setup
###############################
SHELL ["/bin/bash", "-c"]
USER ${UID}
ENV PATH="/home/code/.local/bin:$PATH"

WORKDIR /home/code/
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv python install 3.12.9 --default --preview && \
    uv tool update-shell && \
    uv init project --python 3.12.9 --bare && \
    uv venv --python 3.12.9

WORKDIR /home/code/project/
RUN uv add \
         grpcio-status grpcio pandas==2.2.3 pyarrow \
         transformers datasets tokenizers nltk jax jaxlib optax \
         pandas-datareader psycopg2 pymysql pymongo sqlalchemy \
         sentencepiece seqeval wordcloud tweepy gradio \
         dash streamlit tensorflow \
         line-profiler memory-profiler \
         konlpy dart-fss opendartreader finance-datareader \
         elasticsearch elasticsearch-dsl \
         "nvidia-cudnn-cu12>=9.5.0.50" \
         ipykernel \
         jupyterlab jupyterlab_rise thefuzz ipympl \
         jupyterlab-latex jupyterlab-katex ipydatagrid \
         jupyterlab-language-pack-ko-KR sas_kernel && \
    mkdir -p /home/code/project/.config/matplotlib/ && \
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
    } > /home/code/project/.config/matplotlib/matplotlibrc && \
    mkdir -p /home/code/.local/share/code-server/User/ && \
    { \
       echo "{\"workbench.colorTheme\": \"Visual Studio Dark\"}"; \
    } > /home/code/.local/share/code-server/User/settings.json && \
    uv cache clean

###############################
# Install VS Code Extensions & Final Settings
###############################
RUN code-server --install-extension ms-python.python && \
    code-server --install-extension ms-toolsai.jupyter

VOLUME [ "/home/code/" ]
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "."]
