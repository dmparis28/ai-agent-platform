import { Authenticator } from '@aws-amplify/ui-react'
import '@aws-amplify/ui-react/styles.css'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { ThemeProvider, createTheme, CssBaseline, useMediaQuery } from '@mui/material'
import { useMemo } from 'react'
import AppLayout from './components/AppLayout'
import Dashboard from './pages/Dashboard'
import TaskCreator from './pages/TaskCreator'
import TaskDetail from './pages/TaskDetail'
import CostDashboard from './pages/CostDashboard'

function App() {
  // Samsung Fold detection and responsive theme
  const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)')
  const isFoldClosed = useMediaQuery('(max-width: 280px)')
  const isFoldOpen = useMediaQuery('(min-width: 654px)')

  const theme = useMemo(
    () =>
      createTheme({
        palette: {
          mode: prefersDarkMode ? 'dark' : 'light',
          primary: {
            main: '#2196f3',
          },
          secondary: {
            main: '#f50057',
          },
        },
        breakpoints: {
          values: {
            xs: 0,
            sm: 280,  // Fold closed
            md: 654,  // Fold open
            lg: 768,  // Tablet
            xl: 1024, // Desktop
          },
        },
        components: {
          MuiButton: {
            styleOverrides: {
              root: {
                minHeight: 48, // Touch-friendly
                textTransform: 'none',
              },
            },
          },
          MuiCard: {
            styleOverrides: {
              root: {
                borderRadius: isFoldOpen ? 16 : 12,
              },
            },
          },
        },
        typography: {
          // Scale down for fold closed
          fontSize: isFoldClosed ? 12 : 14,
        },
      }),
    [prefersDarkMode, isFoldClosed, isFoldOpen]
  )

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Authenticator>
        {({ signOut, user }) => (
          <BrowserRouter>
            <AppLayout user={user} signOut={signOut}>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/create" element={<TaskCreator />} />
                <Route path="/task/:taskId" element={<TaskDetail />} />
                <Route path="/costs" element={<CostDashboard />} />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </AppLayout>
          </BrowserRouter>
        )}
      </Authenticator>
    </ThemeProvider>
  )
}

export default App
