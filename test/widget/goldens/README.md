# Emoji fallback golden

`emoji_fallback.png` is generated and compared with Flutter **3.38.7** on
**Linux amd64 / Ubuntu 24.04**, using the same container digest as the `golden`
CI job. Do not update it using a macOS, Windows, ARM64, or different SDK render.

The fixture uses the test font **Ahem**, a white background, a 20px base style,
and missing-emoji resolvers that complete with `null`; no emoji server or image
network request is involved. Rows from top to bottom:

1. Literal shortcode without an emoji builder (natural text reference)
2. Standard helper, normal MFM
3. Standard helper, `plain: true`
4. Standard helper, fixed image size 72px (fallback remains 20px)
5. `x2`
6. `small`
7. Semi-transparent explicit foreground inside `small`
8. Bold, italic and strike-through
9. `small` inside a quote

The golden covers composed size, baseline and opacity. Unit/widget tests also
assert the individual style values and baseline geometry, including image,
loading and error branches; the image is not a substitute for those assertions.

## Generate or compare

From the repository root (Docker required):

```sh
docker run --rm --platform linux/amd64 \
  --entrypoint /bin/bash \
  -v "$PWD:/workspace" -w /workspace \
  ghcr.io/cirruslabs/flutter@sha256:0e6b31fba1e9849cf54939ad76cbbff3e10ad8a1ca3d5b34ea274921343a5eae \
  -lc 'flutter pub get && flutter test --tags golden --concurrency=1 --update-goldens'
```

Omit `--update-goldens` to compare. The image digest is the amd64 manifest of
`ghcr.io/cirruslabs/flutter:3.38.7`. Update the CI image and these instructions
together if the baseline environment is deliberately changed.

The mounted checkout's `.dart_tool` is updated for Linux. Prefer a temporary
checkout when generating, or rerun `fvm flutter pub get` before testing on the
host. Non-golden tests run with `fvm flutter test --exclude-tags golden` and
remain covered by the existing minimum/stable SDK matrix. The `golden` job is a
required dependency of `all checks passed`; failures and cancellations fail
that gate.
