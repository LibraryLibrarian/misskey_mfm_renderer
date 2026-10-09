# Renderer goldens

`emoji_fallback.png` and `mentions.png` are generated and compared with Flutter **3.38.7** on
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

## Mention presentation

`mentions.png` uses Ahem at 20px, a white background, fixed role colors,
disabled animation and a deterministic blue/teal memory image. Rows:

1. Local mention with hidden host
2. Remote mention with translucent host
3. Viewer mention with the self role color
4. Hostless mention resolved against its remote author
5. Offline placeholder with no avatar provider
6. Inline text presentation
7. `small`
8. `small` inside a quote
9. Explicit foreground that does not replace the mention role color
10. Long account constrained to 180px
11. Ambient text scaling of 2 (including the avatar)
12. Bold mention with an italic base style

These images verify this renderer's composition, not pixel equality with an
official Misskey browser. Identity/port rules, actual taps, semantics, provider
precedence, loading/error geometry and paragraph lifecycle are also covered by
unit/widget tests.

## Labelled links

`labelled_links.png` uses Ahem at 20px and explicitly loads the fixed Flutter
SDK's MaterialIcons font through the pub-generated package configuration.
Run the test from the package root; the icon baseline must contain real
external-link glyphs, not missing-font boxes. Rows:

1. External labelled link
2. Self-host labelled link without an icon
3. Silent external labelled link
4. Small external labelled link
5. Bold and strike-through label
6. Local foreground color followed by normal link text
7. Ruby label
8. Static rainbow surrounding an explicitly colored link
9. Border surrounding a labelled link
10. Long label constrained to 220px

The fixture checks nine icons. Actual pointer callbacks, child actions and
semantics are covered by separate widget tests, not this image.

## Editable search

`search.png` uses Ahem at 18px with a 1.2 line height and explicitly loads the
fixed Flutter SDK's MaterialIcons font through the pub-generated package
configuration. Run the test from the package root. All nine fields are unfocused
and animation is disabled, so cursor blinking and an OS keyboard do not affect
the baseline. Rows:

1. Standard search at 400px
2. Custom button label
3. Long query constrained to 240px
4. Long button label constrained to 160px
5. Width 100px with text scaling of 2
6. Large 26px typography
7. Disabled submission
8. Dark palette
9. Custom divider color

Ahem deliberately renders text as blocks; the nine search icons must be real
glyphs. Narrow controls may wrap the icon and label into separate runs, ellipsize
the label or scroll the input. This image checks the unfocused composition, not
editing or submission. Actual scrolling, input values, callbacks, focus,
localization and semantics are covered by separate widget tests.

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
