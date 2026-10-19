import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'misskey_mfm_renderer',
  url: 'https://librarylibrarian.github.io',
  baseUrl: '/misskey_mfm_renderer/',
  trailingSlash: true,
  organizationName: 'LibraryLibrarian',
  projectName: 'misskey_mfm_renderer',
  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'ja'],
    localeConfigs: {
      en: {label: 'English'},
      ja: {label: '日本語'},
    },
  },
  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],
  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'misskey_mfm_renderer',
      items: [
        {type: 'docSidebar', sidebarId: 'docsSidebar', label: 'Docs', position: 'left'},
        {type: 'localeDropdown', position: 'right'},
        {
          href: 'https://github.com/LibraryLibrarian/misskey_mfm_renderer/tree/develop',
          label: 'GitHub',
          position: 'right',
        },
        {
          href: 'https://pub.dev/packages/misskey_mfm_renderer',
          label: 'pub.dev',
          position: 'right',
        },
        {
          href: 'https://pub.dev/documentation/misskey_mfm_renderer/latest/',
          label: 'API reference',
          position: 'right',
        },
      ],
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'yaml', 'bash'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
