# code-server Custom Docker Image

이 이미지는 [coder/code-server](https://github.com/coder/code-server) 기반으로, Python 및 Data Science 관련 의존성, 다양한 폰트, Mecab 등을 추가하여 개발 환경을 간편하게 구축할 수 있도록 커스터마이징한 Docker 이미지입니다.

## 주요 기능/구성

1. **Base Image**

   - [ghcr.io/coder/code-server:4.96.2-bookworm](https://github.com/coder/code-server)
   - code-server를 이용해 브라우저에서 VS Code 환경을 사용할 수 있도록 설정.

2. **Python & Tools**

   - Python 3.11(이미지 기본 또는 Bookworm 디폴트 버전) + `python3-venv`, `python3-dev` 등 설치
   - `pip`를 이용해 Data Science, NLP, Web Framework, DB 연동 등에 필요한 라이브러리 설치
   - PyTorch(CPU 버전(ARM64), CUDA(AMD64), JAX, Transformers 등 포함

3. **Mecab**

   - `mecab-ko-msvc` 리포지토리에서 mecab-ko + mecab-ko-dic 설치
   - 한국어 형태소 분석 가능

4. **Various Fonts**

   - Google Fonts, Noto Fonts, D2Coding, Pretendard, IBM Plex 등 한글, 일본어, 다국어 폰트 설치
   - Matplotlib 폰트 설정을 통해 시각화 시 한글 폰트 깨짐 방지

5. **VS Code Extensions**
   - `ms-python.python`, `ms-toolsai.jupyter` 확장 설치

---

## 설치 및 실행 방법

### 1. Dockerfile 빌드

```bash
# 현재 디렉터리에 있는 Dockerfile을 이용해 이미지 빌드
docker build -t aisflow/code:latest .
```

### 2. 컨테이너 실행

```bash
docker run -d \
  --name code-server \
  -p 8080:8080 \
  -v "$(pwd)":/home/coder/project \
  aisflow/code:latest
```

- `-p 8080:8080` : code-server의 기본 포트(8080)를 호스트와 연결
- `-v "$(pwd)":/home/coder/project` : 현재 디렉터리를 컨테이너 내부로 마운트

### 3. code-server 접속

- 브라우저에서 `http://<docker_host_ip>:8080` 접속
- 처음 접속 시 나오는 패스워드는 컨테이너 내부에서 `/home/coder/.config/code-server/config.yaml` 파일 등을 참고하거나, 환경 변수로 설정할 수 있습니다. (기본값은 `password`)

---

## 폰트 설정

- Noto Sans, IBM Plex, Pretendard 등 다양한 폰트가 설치되어 있으며, `matplotlibrc` 기본 설정에 의해 시각화 시 한글 깨짐 없이 사용할 수 있습니다.
- 추가로 폰트를 설치하거나, 폰트 설정을 변경하려면 `matplotlibrc` 파일( `/home/coder/.config/matplotlib/matplotlibrc` )을 수정하거나, `/usr/share/fonts/truetype/` 경로에 폰트를 수동으로 넣은 후 `fc-cache -f -v` 명령어를 실행하시면 됩니다.

---

## Mecab 사용

- `mecab-ko`, `mecab-ko-dic` 이 `/opt/mecab` 에 설치되어 있습니다.

---

## 설치된 주요 Python 라이브러리

- **데이터 분석/머신러닝**: `pandas==2.2.3`, `pyarrow`, `torch`, `torchaudio`, `torchvision`, `jax`, `jaxlib`, `optax`, `transformers`, `datasets`, `tokenizers`, `seqeval` 등
- **웹/어플리케이션**: `gradio`, `dash`, `streamlit`
- **DB 연동**: `pandas-datareader`, `psycopg2`, `pymysql`, `pymongo`, `sqlalchemy`, `elasticsearch`, `elasticsearch-dsl`
- **한국어 처리**: `konlpy`, `dart-fss`, `opendartreader`, `finance-datareader` 등
- **Jupyter 관련**: `jupyterlab`, `jupyterlab_rise`, `jupyterlab-latex`, `jupyterlab-katex`, `ipympl`, `ipydatagrid`, `jupyterlab-language-pack-ko-KR`
- **프로파일링**: `line-profiler`, `memory-profiler`
