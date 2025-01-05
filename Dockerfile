FROM ghcr.io/coder/code-server:4.96.2-bookworm

USER root

ENV TZ='Asia/Seoul'

COPY fix-permissions /usr/local/bin/fix-permissions

RUN apt-get update --yes \
    && apt-get install --yes --no-install-recommends \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        fonts-dejavu gfortran \
        g++ gcc jq libpq-dev locales fontconfig \
        unzip build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /home/coder/venv \
    && chown -R 1000:1000 /home/coder/venv

RUN set -eux; \
        install_google_font() { \
            RELATIVE_PATH=$1; FONT_NAME=$2; \
            FONT_DIR="/usr/share/fonts/truetype/${RELATIVE_PATH}"; \
            mkdir -p "${FONT_DIR}" && \
            ENCODED_FONT_NAME=$(printf "%s" "${FONT_NAME}" | jq -sRr @uri) && \
            wget --quiet -O "${FONT_DIR}/${FONT_NAME}" "https://raw.githubusercontent.com/google/fonts/17216f1645a133dbbeaa506f0f63f701861b6c7b/ofl/${RELATIVE_PATH}/${ENCODED_FONT_NAME}"; \
        } && \
        # Install D2Coding font
            mkdir -p /usr/share/fonts/truetype/D2Coding && \
                wget --quiet -O /usr/share/fonts/truetype/D2Coding.zip https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip && \
                unzip /usr/share/fonts/truetype/D2Coding.zip -d /usr/share/fonts/truetype/ && \
            rm /usr/share/fonts/truetype/D2Coding.zip && \
        # Install D2Coding Nerd font
            mkdir -p /usr/share/fonts/truetype/D2CodingNerd && \
                wget --quiet -O /usr/share/fonts/truetype/D2CodingNerd/D2CodingNerd.ttf https://github.com/kelvinks/D2Coding_Nerd/raw/master/D2Coding%20v.1.3.2%20Nerd%20Font%20Complete.ttf && \
        # Install Pretendard font
            mkdir -p /usr/share/fonts/truetype/Pretendard && \
                wget --quiet -O /usr/share/fonts/truetype/Pretendard.zip https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip && \
                unzip /usr/share/fonts/truetype/Pretendard.zip -d /usr/share/fonts/truetype/Pretendard/ && \
            rm /usr/share/fonts/truetype/Pretendard.zip && \
        # Install PretendardJP font
            mkdir -p /usr/share/fonts/truetype/PretendardJP && \
                wget --quiet -O /usr/share/fonts/truetype/PretendardJP.zip https://github.com/orioncactus/pretendard/releases/download/v1.3.9/PretendardJP-1.3.9.zip && \
                unzip /usr/share/fonts/truetype/PretendardJP.zip -d /usr/share/fonts/truetype/PretendardJP/ && \
            rm /usr/share/fonts/truetype/PretendardJP.zip && \
        # Noto Fonts
            install_google_font "notosans" "NotoSans[wdth,wght].ttf" && \
            install_google_font "notosans" "NotoSans-Italic[wdth,wght].ttf" && \
            install_google_font "notoserif" "NotoSerif[wdth,wght].ttf" && \
            install_google_font "notoserif" "NotoSerif-Italic[wdth,wght].ttf" && \
            install_google_font "notosanskr" "NotoSansKR[wght].ttf" && \
            install_google_font "notoserifkr" "NotoSerifKR[wght].ttf" && \
            install_google_font "notosansjp" "NotoSansJP[wght].ttf" && \
            install_google_font "notoserifjp" "NotoSerifJP[wght].ttf" && \
        # Nanum Fonts
            install_google_font "nanumbrushscript" "NanumBrushScript-Regular.ttf" && \
            install_google_font "nanumgothic" "NanumGothic-Bold.ttf" && \
            install_google_font "nanumgothic" "NanumGothic-ExtraBold.ttf" && \
            install_google_font "nanumgothic" "NanumGothic-Regular.ttf" && \
            install_google_font "nanumgothiccoding" "NanumGothicCoding-Bold.ttf" && \
            install_google_font "nanumgothiccoding" "NanumGothicCoding-Regular.ttf" && \
            install_google_font "nanummyeongjo" "NanumMyeongjo-Bold.ttf" && \
            install_google_font "nanummyeongjo" "NanumMyeongjo-ExtraBold.ttf" && \
            install_google_font "nanummyeongjo" "NanumMyeongjo-Regular.ttf" && \
        # IBM Plex Fonts
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
        # Set permissions
        chmod -R 644 /usr/share/fonts/truetype/* && \
            find /usr/share/fonts/truetype/ -type d -exec chmod 755 {} + && \
        # Update font cache
        fc-cache -f -v && \
        dpkgArch="$(dpkg --print-architecture)"; \
            case "${dpkgArch##*-}" in \
                amd64) mecabArch='x86_64';; \
                arm64) mecabArch='aarch64';; \
                *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
            esac; \
        mecabKoUrl="https://github.com/Pusnow/mecab-ko-msvc/releases/download/release-0.999/mecab-ko-linux-${mecabArch}.tar.gz"; \
        mecabKoDicUrl="https://github.com/Pusnow/mecab-ko-msvc/releases/download/release-0.999/mecab-ko-dic.tar.gz"; \
                wget --quiet "${mecabKoUrl}" -O - | tar -xzvf - -C /opt; \
                wget --quiet "${mecabKoDicUrl}" -O - | tar -xzvf - -C /opt/mecab/share && \
    fix-permissions "/opt/mecab"

USER 1000

RUN . /home/coder/venv/bin/activate \
    && pip install --upgrade pip \
    && pip install --no-cache-dir \
            'grpcio-status' 'grpcio' 'pandas==2.2.3' 'pyarrow' \
            'transformers' 'datasets' 'tokenizers' 'nltk' 'jax' 'jaxlib' 'optax' \
            'pandas-datareader' 'psycopg2' 'pymysql' 'pymongo' 'sqlalchemy' \
            'sentencepiece' 'seqeval' 'wordcloud' 'tweepy' 'gradio' \
            'dash' 'streamlit' 'tensorflow' \
            'line-profiler' 'memory-profiler' \
            'konlpy' 'dart-fss' 'opendartreader' 'finance-datareader' \
            'elasticsearch' 'elasticsearch-dsl' 'sentence-transformers' \
    && pip install --no-cache-dir --index-url 'https://download.pytorch.org/whl/cpu' \
            'torch' 'torchaudio' 'torchvision' \
    && pip install --no-cache-dir \
            'jupyterlab' 'jupyterlab_rise' 'thefuzz' 'ipympl' \
            'jupyterlab-latex' 'jupyterlab-katex' 'ipydatagrid' \
            'jupyterlab-language-pack-ko-KR' 'sas_kernel' \
    && mkdir -p /home/${USER}/.config/matplotlib/ \
    && { \
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
        } > /home/${USER}/.config/matplotlib/matplotlibrc

RUN code-server --install-extension ms-python.python \
    && code-server --install-extension ms-toolsai.jupyter
