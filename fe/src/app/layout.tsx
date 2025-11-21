import './globals.css'
import type { Metadata } from 'next'
import { Providers } from './providers'

export const metadata: Metadata = {
  title: 'AI Agent Platform',
  description: 'Production-grade multi-agent AI development platform',
  viewport: 'width=device-width, initial-scale=1',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
