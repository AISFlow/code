# code-server + ML Dev Custom Docker Image

본 이미지는 CUDA 기반 ML/데이터 사이언스 실험을 위한 **커스텀 개발 환경**입니다.

- 최신 code-server, 다양한 Python 생태계, 한국어 Mecab, CJK 프로그래밍 폰트 포함
- Python 환경은 **uv**로 통합 관리, venv 자동 활성화, 권한 문제 최소화, 시각화 폰트 깨짐 방지 등 개발 편의성 극대화

## 주요 기능 및 구성

|    영역     | 주요 내용                                                                                         |
| :---------: | :------------------------------------------------------------------------------------------------ |
|    Base     | `nvidia/cuda:12.x-cudnn-runtime-ubuntu24.04` + 시스템 Python 제거, 필수 툴만 설치                 |
|   Python    | [astral.sh/uv](https://astral.sh/uv) 기반 Python 관리, venv 기본, `.bash_env`로 자동 활성화       |
| code-server | 최신 버전 Shell Script 설치, 확장 자동 설치, 사용자 홈 환경 분리                                  |
|    Mecab    | 별도 빌드된 mecab-ko + mecab-ko-dic을 `/opt/mecab`에 배치, 필요시 `PATH`/`LD_LIBRARY_PATH`에 추가 |
|    Fonts    | Pretendard, Noto, D2Coding, Nanum, IBM Plex 등 CJK/코딩 폰트 직접 설치, `fc-cache`로 반영         |
|   시각화    | `matplotlibrc` 사전 지정, 한글/다국어 폰트 깨짐 방지                                              |
|    권한     | code 유저(UID/GID 1001) 기본, gosu/tini로 안전하게 시작, 볼륨 마운트 시 fix-permissions 지원      |
| Jupyter/ML  | 주요 ML/DL/Data Science 패키지(Transformers, PyTorch, JAX 등) 사전 설치                           |

## Mecab 심볼릭 링크 관련 안내

- `python-mecab-ko` 등 일부 Python 라이브러리는 `/usr/local/lib` 또는 `/usr/lib` 등 시스템 경로에 Mecab 바이너리/라이브러리 심볼릭 링크를 요구할 수 있습니다.
- 본 컨테이너는 `/opt/mecab`에 Mecab이 설치되어 있으므로,
  해당 라이브러리의 설치 스크립트나 공식 문서를 참고해 심볼릭 링크를 적절히 생성해주셔야 합니다.

예시:

```bash
sudo ln -sf /opt/mecab/bin/mecab /usr/local/bin/mecab
```

## 설치 및 실행 방법

### 1. Docker 이미지 빌드

```bash
docker build -t aisflow/code:latest .
```

### 2. 컨테이너 실행

```bash
docker run -d \
  --name code-server \
  -p 8080:8080 \
  -v "$(pwd)":/home/code/project \
  aisflow/code:latest
```

- `-p 8080:8080` : code-server 접속 포트
- `-v` : 프로젝트 폴더 마운트(권장)

### 3. code-server 접속

- 브라우저에서 `http://<docker_host_ip>:8080` 접속
- 최초 비밀번호: `/home/code/.config/code-server/config.yaml` 확인 또는 환경변수로 별도 지정 가능

## Python/venv 사용법

- 모든 터미널/VS Code 터미널에서 **자동**으로 `/home/code/.venv`가 활성화됩니다. (별도 activate 필요 없음)
- VS Code 확장도 `/home/code/.venv/bin/python`을 기본 인터프리터로 사용하도록 사전 설정

## 폰트 및 시각화 환경

- 다양한 한글/일어/중국어/코딩 폰트가 `/usr/share/fonts/truetype`에 설치
- `matplotlib` 시각화 시 한글, 일본어 등 문자 깨짐 없음
- 추가 폰트 설치 시:

  1. `/usr/share/fonts/truetype/`에 복사
  2. `fc-cache -f -v` 실행
  3. 필요시 `~/.config/matplotlib/matplotlibrc` 수정

## Mecab 사용

- `mecab-ko`, `mecab-ko-dic`이 `/opt/mecab`에 설치됨
- PATH, LD_LIBRARY_PATH 설정 필요 시:

  ```sh
  export PATH="/opt/mecab/bin:$PATH"
  export LD_LIBRARY_PATH="/opt/mecab/lib:$LD_LIBRARY_PATH"
  ```

- Python에서 mecab 연동은 별도 라이브러리 필요 (`mecab-python3` 등)

## 설치된 주요 Python 라이브러리

- **데이터 분석/ML**: `pandas==2.2.3`, `pyarrow`, `torch`, `jax`, `transformers`, `datasets`, `seqeval` 등
- **웹/대화형**: `gradio`, `dash`, `streamlit`
- **DB 연동**: `psycopg2`, `pymysql`, `pymongo`, `sqlalchemy`, `elasticsearch-dsl` 등
- **한국어**: `konlpy`, `dart-fss`, `opendartreader`
- **Jupyter/노트북**: `jupyterlab`, `ipympl`, `jupyterlab-latex`, `ipydatagrid`, `jupyterlab-language-pack-ko-KR`
- **프로파일링**: `line-profiler`, `memory-profiler`

## 기타 참고

- code-server 확장은 Dockerfile 내 `EXTENSIONS` 리스트에서 관리 가능
- user/group/fix-permissions 등 권한 관련 요구는 ENTRYPOINT/시작스크립트에서 지원
