# SWORDCOMM for Android

An unfinished messaging project based on Molly, a fork of Signal. SWORDCOMM explores additional cryptography, device-security monitoring and input protection around that messaging foundation.

[Build guide](DOCKER_BUILD.md) · [Technical documentation](docs/) · [iOS project](https://github.com/SWORDOps/Swordcomm-IOS) · [Issues](https://github.com/SWORDOps/SWORDCOMM/issues)

## Project status: Unfinished

This project is unfinished. I could not find a way to securely communicate between Android Keystore and its iOS equivalent, and other projects have taken priority.

The components below describe the repository's scope, not a finished or independently verified secure product. Cross-platform key handling remains unresolved. Existing implementation reports and build guides should be read in that context.

## Contents

- [Messaging and project features](#messaging-and-project-features)
- [Security and privacy limitations](#security-and-privacy-limitations)
- [Platform and development setup](#platform-and-development-setup)
- [Build and install](#build-and-install)
- [Translation](#translation)
- [Repository layout](#repository-layout)
- [Testing and troubleshooting](#testing-and-troubleshooting)
- [Documentation](#documentation)
- [Contributing and support](#contributing-and-support)
- [License and acknowledgments](#license-and-acknowledgments)

## Messaging and project features

### Messaging foundation

The Android app builds on the Molly/Signal codebase, including its messaging, conversation and calling infrastructure. The app and Signal service code live in [app/](app/) and [libsignal-service/](libsignal-service/).

SWORDCOMM-specific additions are experimental. The upstream foundation does not establish the security or compatibility of this fork's changes.

### Cryptography and key handling

The [security library](security-lib/) contains ML-KEM-1024 and ML-DSA-87 integration paths using liboqs, alongside test implementations. Its CMake configuration selects between them through `PRODUCTION_CRYPTO`.

**Test cryptography is not suitable for real communication.** The name “production” identifies a build mode, not a security certification or a statement that the project is ready to deploy. See the [crypto build guide](BUILD_GUIDE.md) and [crypto upgrade notes](CRYPTO_UPGRADE.md).

Secure communication and key handling across the Android and iOS versions remain unfinished, as described above.

### Device-security experiments

Native components explore hypervisor-related signals, performance counters, cache behavior, memory scrambling and timing obfuscation. Other components generate decoy activity and noise.

These are research components, not a guarantee of detecting or defeating a compromised operating system or hypervisor. Their presence in the repository does not demonstrate protection against a particular attacker.

### Input protection

The project includes work on an input-security wrapper for FlorisBoard and FUTO Voice Input, with timing randomization and threat-response integration. Treat this as part of the unfinished integration work, rather than a drop-in assurance that keyboard or voice input is protected.

Translation is a secondary feature and is described [below](#translation).

## Security and privacy limitations

- **Do not rely on this unfinished project for sensitive communications.** Cross-platform key handling, integration and security validation still need work.
- Experimental countermeasures can increase CPU use, battery drain, device heat and network traffic. More aggressive settings should not be interpreted as proven stronger protection.
- The security experiments do not make a compromised device trustworthy.
- Noise-generation code includes screen-coordinate tracking and keyword embedding. Review these behaviors before enabling them; noise generation is not a substitute for encryption or access control.
- Test crypto and placeholder implementations must not be confused with functioning security features.
- A successful build or passing test is not a security audit. The [security audit checklist](docs/SECURITY_AUDIT_CHECKLIST.md) and [hardening plan](docs/PRODUCTION_HARDENING_PLAN.md) describe further review work.

## Platform and development setup

The native security module currently targets **ARM64 (`arm64-v8a`)**. Earlier project work focused on Pixel 6A and Pixel 8A devices; this is not a compatibility guarantee for those or other devices.

For local builds, consult the actual [Gradle constants](constants.gradle.kts) and [security-module configuration](security-lib/build.gradle.kts), which take precedence over older setup notes. The checked-in configuration specifies Java 17, NDK 28.0.13004108 and CMake 3.22.1 for the security module.

Build and signing guides:

| Route | Start here |
| --- | --- |
| Docker-based build | [Docker build guide](DOCKER_BUILD.md) |
| Local Android toolchain | [Android build setup](ANDROID_BUILD_SETUP.md) |
| Signing and upstream build background | [Building and self-signing](BUILDING.md) |

Some files still use the names Molly or EMMA. They refer to the upstream base or earlier project naming.

## Build and install

These commands are development entry points, not a tested release procedure.

### Get the source

```bash
git clone https://github.com/SWORDOps/SWORDCOMM.git
cd SWORDCOMM
```

### Docker build

Install Docker and Docker Compose, then use the checked-in wrapper:

```bash
./build.sh debug
./build.sh test
```

The wrapper also exposes a release build using the liboqs configuration:

```bash
./build.sh release --production
```

See [DOCKER_BUILD.md](DOCKER_BUILD.md) for build variants, environment variables and output locations. APK outputs are under `app/build/outputs/apk/`.

### Local build and device installation

Set up the Android SDK, NDK and Java toolchain using [ANDROID_BUILD_SETUP.md](ANDROID_BUILD_SETUP.md). Then inspect the available tasks and build the desired variant:

```bash
./gradlew tasks
./gradlew assembleDebug
```

Use a test device with USB debugging enabled. Install the APK produced for your selected variant, replacing the path below:

```bash
adb install path/to/your-built.apk
```

Release APKs require signing; see [BUILDING.md](BUILDING.md). Protect signing keys and do not commit them. Installing a self-signed fork can affect update compatibility with upstream apps.

## Translation

Danish-to-English translation is an additional project area, not the primary purpose of SWORDCOMM.

The design includes MarianMT/OPUS models, local inference, caching and an optional Linux translation server. **The checked-in native [translation engine](translation-lib/src/main/cpp/translation_engine.cpp) currently uses a stub that prefixes text with `[DA->EN]`; it does not perform the documented model inference.** Do not treat that output as a translation.

The documented configuration distinguishes network-first, on-device-first and on-device-only strategies. Those describe the intended routing behavior, not evidence that every path is complete.

The [server directory](server/) and Docker wrapper provide the server-side starting point:

```bash
./build.sh server
./build.sh server-test
./build.sh server-stop
```

Network translation involves sending text to a server. Review the implementation and configuration before using it with private content. Offline translation, where implemented, is separate from messaging connectivity.

## Repository layout

| Path | Purpose |
| --- | --- |
| [app/](app/) | Android application and integration |
| [libsignal-service/](libsignal-service/) | Signal service layer |
| [security-lib/](security-lib/) | Native security experiments, cryptography and Android bindings |
| [translation-lib/](translation-lib/) | Translation interfaces and native engine |
| [server/](server/) | Translation server |
| [scripts/](scripts/) | Build and supporting scripts |
| [docs/](docs/) | Implementation notes, plans and review checklists |
| [build.sh](build.sh) | Docker build and server commands |

## Testing and troubleshooting

For unit tests through Docker, use `./build.sh test`. For local Gradle tests, select the tasks appropriate to your build variant; device tests require a connected Android device.

When reporting a build problem, include the commit, build command, toolchain versions and relevant error output. Redact credentials, signing information and private message content.

- **Build or liboqs failures:** check [DOCKER_BUILD.md](DOCKER_BUILD.md) and [BUILD_GUIDE.md](BUILD_GUIDE.md), and confirm which crypto implementation the build selected.
- **Heat or battery drain:** stop the experiment or disable the optional countermeasures; do not assume resource use demonstrates protection.
- **Translation output unchanged except for a prefix:** this is the native stub behavior described above, not a model-download issue.
- **Installation or update conflicts:** check the application ID, build variant and signing key against the installed app.

## Documentation

| Guide | Scope |
| --- | --- |
| [Docker build guide](DOCKER_BUILD.md) | Container builds, variants and server commands |
| [Android build setup](ANDROID_BUILD_SETUP.md) | Local toolchain setup |
| [Building and self-signing](BUILDING.md) | Signing and upstream build background |
| [Crypto build guide](BUILD_GUIDE.md) | liboqs and test-mode configuration |
| [CI/CD documentation](CI_CD.md) | Existing workflow documentation |
| [Implementation report](docs/FINAL_IMPLEMENTATION_REPORT.md) | Historical implementation notes |
| [Implementation status](docs/IMPLEMENTATION_STATUS.md) | Historical tracking |
| [Hardening plan](docs/PRODUCTION_HARDENING_PLAN.md) | Further security work |
| [Security audit checklist](docs/SECURITY_AUDIT_CHECKLIST.md) | Review checklist |
| [iOS port roadmap](docs/IOS_PORT_ROADMAP.md) | Historical porting plans |
| [iOS repository](https://github.com/SWORDOps/Swordcomm-IOS) | Separate iOS implementation |

Historical reports may describe goals or completion claims that do not reflect the unfinished status or current code. Check the implementation before relying on them.

## Contributing and support

Use [this repository's issues](https://github.com/SWORDOps/SWORDCOMM/issues) for non-sensitive bugs and feature discussions. Include reproducible steps and distinguish upstream Molly/Signal behavior from SWORDCOMM-specific changes.

Useful areas for review include cross-platform key handling, integration tests, the security experiments, build reproducibility and unfinished translation paths. This is not a commitment to a release schedule.

Do not post private keys, credentials, private messages or sensitive vulnerability details in public issues.

## License and acknowledgments

This project is licensed under the **GNU AGPLv3**. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for the applicable terms and notices.

This software is provided for educational and research purposes, without warranty. It contains cryptographic components; users are responsible for complying with applicable laws and export restrictions.

SWORDCOMM builds on work by Signal and Molly contributors, with cryptography integration using Open Quantum Safe/liboqs and translation work based on Helsinki-NLP/OPUS-MT and MarianMT.

- [Molly upstream](https://github.com/mollyim/mollyim-android)
- [Signal Android upstream](https://github.com/signalapp/Signal-Android)
- [SWORDCOMM for iOS](https://github.com/SWORDOps/Swordcomm-IOS)
