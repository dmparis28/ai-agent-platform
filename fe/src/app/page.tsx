'use client'

import { useAuthenticator } from '@aws-amplify/ui-react'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export default function Home() {
  const { user } = useAuthenticator()
  const router = useRouter()

  useEffect(() => {
    if (user) {
      router.push('/dashboard')
    }
  }, [user, router])

  return <div>Loading...</div>
}
