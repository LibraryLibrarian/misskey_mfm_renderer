import {themes as prismThemes} from 'prism-react-renderer';
import type {Config, ThemeConfig} from '@docusaurus/types';
import type {Options as DocsOptions} from '@docusaurus/plugin-content-docs';
import type {Options as ThemeOptions} from '@docusaurus/theme-classic';
import type {UserThemeConfig} from '@docusaurus/theme-common';
import i18n from './locales.json';

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
  i18n,
  themes: [
    ['@docusaurus/theme-classic', {customCss: './src/css/custom.css'} satisfies ThemeOptions],
  ],
  plugins: [
    [
      '@docusaurus/plugin-content-docs',
      {sidebarPath: './sidebars.ts', routeBasePath: '/'} satisfies DocsOptions,
    ],
    '@docusaurus/plugin-content-pages',
    ...(process.env.NODE_ENV === 'production'
      ? ['@docusaurus/plugin-sitemap']
      : ['@docusaurus/plugin-debug']),
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
  } satisfies ThemeConfig & UserThemeConfig,
};

export default config;
