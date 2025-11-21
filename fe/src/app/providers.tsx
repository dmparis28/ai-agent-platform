'use client'

import { ThemeProvider, createTheme, CssBaseline } from '@mui/material'
import { Authenticator } from '@aws-amplify/ui-react'
import '@aws-amplify/ui-react/styles.css'
import { Amplify } from 'aws-amplify'
import { ReactNode } from 'react'

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID || '',
      userPoolClientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID || '',
      identityPoolId: process.env.NEXT_PUBLIC_COGNITO_IDENTITY_POOL_ID || '',
    }
  }
})

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
  },
})

export function Providers({ children }: { children: ReactNode }) {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Authenticator>
        {children}
      </Authenticator>
    </ThemeProvider>
  )
}
