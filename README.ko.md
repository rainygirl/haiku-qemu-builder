# Haiku용 QEMU 빌더

이 프로젝트는 HaikuOS R1/beta6 x86_gcc2에서 QEMU 8.2.2를 소스 코드로
빌드하고 HPKG 패키지로 설치하기 위한 스크립트 모음입니다.

WebPositive 또는 HaikuWebKit을 제거하지 않고 호환 가능한 GLib을 함께
빌드하며, HaikuOS에서 발생하는 QEMU의 설정 파일 및 condition timeout 문제를
수정합니다.

개발 및 디버깅 과정에서 Claude Sonnet 모델을 사용했습니다.

## 요구 사항

- HaikuOS R1/beta6 x86_gcc2
- 인터넷 연결
- 최소 5GB의 여유 디스크 공간
- 구형 하드웨어에서는 수 시간이 걸릴 수 있음

## 빌드 및 설치

```sh
chmod +x build.sh install.sh
./build.sh
./install.sh
```

이미 빌드된 작업 디렉터리를 사용하면 Ninja 결과물을 보존한 채 다시
실행할 수 있습니다. 기본 작업 디렉터리는 다음과 같습니다.

```text
/boot/home/qemu-haiku-build
```

다른 위치를 사용하려면:

```sh
QEMU_HAIKU_ROOT=/boot/home/my-qemu-build ./build.sh
```

기본 빌드 작업 수는 1개입니다. 메모리가 충분한 시스템에서는 늘릴 수
있습니다.

```sh
BUILD_JOBS=2 ./build.sh
```

## GLib 처리

QEMU는 `glib2_x86`과 `glib2_x86_devel`이 **같은 버전**이어야 합니다.
R1/beta6 x86_gcc2는 `glib2_x86` 2.57.1을 devel 패키지 없이 제공하는데,
HaikuPorts의 `glib2_x86`이 2.88.1로 올라가면서 저장소에서 2.57.1에 맞는
devel을 더 이상 받을 수 없게 됐습니다. 이 상태에서 QEMU 레시피의 버전 제한
없는 `devel:libglib_2.0_x86`은 haikuporter가 가장 최신으로 판단한 쪽으로
해석되고, 버전이 어긋나 빌드가 실패합니다.

그래서 `build.sh`가 GLib 출처를 먼저 정하고 QEMU 레시피를 그 버전으로
고정합니다.

- `installed` - 짝이 맞는 `glib2_x86` / `glib2_x86_devel`이 이미 설치됨.
  빌드도 다운로드도 하지 않습니다.
- `repository` - 저장소의 `glib2_x86_devel`이 설치된 `glib2_x86`과 버전이
  맞음(또는 아무것도 설치돼 있지 않음). 저장소에서 둘 다 설치합니다.
- `local` - 위 두 경우가 아니면 `ports/`의 GLib 2.57.1을 빌드합니다. 기본
  beta6 설치는 이 경로를 탑니다.

앞의 두 경우에는 번들 레시피를 작업 트리에서 제거합니다. 레시피 리비전이
설치본보다 높다는 이유만으로 haikuporter가 GLib을 다시 빌드하는 것을
막기 위해서입니다.

`GLIB_SOURCE`로 직접 지정할 수 있습니다.

```sh
GLIB_SOURCE=installed ./build.sh
GLIB_SOURCE=repository ./build.sh
GLIB_SOURCE=local ./build.sh
```

`install.sh`는 이미 `glib2_x86`이 설치되어 있으면 로컬 GLib 패키지를 덮어쓰지
않습니다. QEMU는 GLib에 대해 상위 호환으로 링크되고, `glib2_x86`을
다운그레이드하면 WebPositive와 HaikuWebKit이 쓰는 GLib이 깨집니다.

빌드 사전 요구 패키지에 `gcc_x86_syslibs_devel`이 추가됐습니다. 이게 없으면
번들 GLib 레시피의 `devel:libgcc_x86` 요구가 해석되지 않아 아무것도 컴파일
하기 전에 `build.sh`가 중단됩니다.

## 설치 대상 선택

기본적으로 x86 QEMU를 설치합니다. PPC QEMU를 설치하려면:

```sh
./install.sh ppc
```

빌드된 HPKG 파일은 다음 위치에 생성됩니다.

```text
/boot/home/qemu-haiku-build/packages/
```

설치 스크립트는 WebPositive와 HaikuWebKit이 계속 설치되어 있는지도
확인합니다.

## Mac OS 9 실행

```sh
./install.sh ppc
./run-macos9.sh /path/to/macos9.iso
```

스크립트는 처음 실행할 때 4GB QCOW2 디스크를 만들고 `mac99` Power Mac을
실행합니다. 사용 권한이 있는 Mac OS 9 미디어만 사용해야 합니다.

일부 Mac OS 9 설치 ISO는 OpenBIOS의 `Trying cd:,\\:tbxi` 단계에서 멈출 수
있습니다. 이는 HaikuOS 패키지 문제가 아니라 QEMU OpenBIOS와 설치 미디어의
호환성 문제입니다. 이 경우 사전 설치된 부팅 가능한 HFS 디스크 이미지가
필요할 수 있습니다.

## 라이선스

스크립트와 프로젝트 자체의 패치는 MIT 라이선스로 배포합니다. QEMU,
GLib, HaikuPorts 레시피 및 다운로드되는 소스 코드는 각각의 원래
라이선스를 따릅니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.
