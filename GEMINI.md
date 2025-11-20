# Project Overview

This project is a security-hardened fork of the Signal Android app, named Molly. It's designed to provide secure messaging with an emphasis on defending against sophisticated, nation-state level surveillance. A key feature is the real-time, on-device translation from Danish to English.

The application is built for Android (10+) and is optimized for Google Pixel devices (6A and 8A). It includes advanced security features like EL2 hypervisor detection, memory protection, and post-quantum encryption.

The project is a multi-module Android application built with Gradle and Kotlin. It has a significant native component written in C/C++ for performance-critical security and translation features. Docker is used for creating a reproducible build environment.

# Building and Running

## Prerequisites

*   Android Studio
*   Android NDK
*   Java 17+
*   Docker (recommended)

## Build Commands

The recommended way to build the project is by using the provided Docker build scripts.

*   **Build debug APK:**
    ```bash
    ./build.sh debug
    ```

*   **Build production release:**
    ```bash
    ./build.sh release --production
    ```

*   **Run the translation server:**
    ```bash
    ./build.sh server
    ```

*   **Run tests:**
    ```bash
    ./gradlew test
    ./gradlew connectedAndroidTest
    ```

## Deployment

The `deploy.sh` script is used for installation and to manage the application on a device.

*   **Full deployment:**
    ```bash
    ./deploy.sh full
    ```

*   **Simulate a threat level:**
    ```bash
    ./deploy.sh threat 50
    ```

# Development Conventions

*   The project follows standard Android development conventions.
*   Code is organized into multiple Gradle modules, separating features and libraries.
*   Native code (C/C++) is used for security and performance-critical components.
*   The project uses GitHub Actions for CI/CD, including building, testing, and security scanning.
*   Dependency management is handled through Gradle's version catalogs.
