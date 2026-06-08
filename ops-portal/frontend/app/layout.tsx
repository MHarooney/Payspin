import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import './globals.css';
import { Providers } from './providers';
import { themeNoFlashScript } from '@/lib/theme';

export const metadata: Metadata = {
  title: 'Payspin Ops',
  description: 'Payspin internal operations portal',
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: dark)', color: '#0B0B12' },
    { media: '(prefers-color-scheme: light)', color: '#F9F9F9' },
  ],
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" data-theme="dark" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeNoFlashScript }} />
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
