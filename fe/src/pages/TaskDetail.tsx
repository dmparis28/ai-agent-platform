import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Stack,
  CircularProgress,
  Paper,
  useMediaQuery,
  LinearProgress,
} from '@mui/material'
import { CheckCircle, Error, Pending } from '@mui/icons-material'

interface TaskData {
  taskId: string
  agentType: string
  status: string
  createdAt: string
  completedAt?: string
  cost?: number
  result?: string
}

export default function TaskDetail() {
  const { taskId } = useParams()
  const isFoldClosed = useMediaQuery('(max-width: 280px)')
  const [task, setTask] = useState<TaskData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // TODO: Fetch task details from API
    setTimeout(() => {
      setTask({
        taskId: taskId || '',
        agentType: 'frontend',
        status: 'running',
        createdAt: new Date().toISOString(),
        cost: 1.25,
      })
      setLoading(false)
    }, 1000)
  }, [taskId])

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle color="success" />
      case 'failed':
        return <Error color="error" />
      default:
        return <Pending color="primary" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'success'
      case 'failed': return 'error'
      case 'running': return 'primary'
      default: return 'default'
    }
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="50vh">
        <CircularProgress />
      </Box>
    )
  }

  if (!task) {
    return (
      <Box>
        <Typography variant="h6" color="error">
          Task not found
        </Typography>
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant={isFoldClosed ? "h6" : "h4"} mb={3}>
        Task Details
      </Typography>

      <Stack spacing={3}>
        {/* Status Card */}
        <Card elevation={2}>
          <CardContent>
            <Stack direction="row" spacing={2} alignItems="center" mb={2}>
              {getStatusIcon(task.status)}
              <Box flexGrow={1}>
                <Typography variant="h6">{task.taskId}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {task.agentType} agent
                </Typography>
              </Box>
              <Chip
                label={task.status}
                color={getStatusColor(task.status)}
              />
            </Stack>
            
            {task.status === 'running' && (
              <LinearProgress sx={{ mt: 2 }} />
            )}
          </CardContent>
        </Card>

        {/* Details Card */}
        <Paper elevation={2}>
          <Box p={2}>
            <Typography variant="h6" mb={2}>
              Details
            </Typography>
            <Stack spacing={1.5}>
              <Box>
                <Typography variant="body2" color="text.secondary">
                  Created At
                </Typography>
                <Typography variant="body1">
                  {new Date(task.createdAt).toLocaleString()}
                </Typography>
              </Box>
              
              {task.completedAt && (
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Completed At
                  </Typography>
                  <Typography variant="body1">
                    {new Date(task.completedAt).toLocaleString()}
                  </Typography>
                </Box>
              )}
              
              {task.cost && (
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Cost
                  </Typography>
                  <Typography variant="h6" color="primary">
                    ${task.cost.toFixed(2)}
                  </Typography>
                </Box>
              )}
            </Stack>
          </Box>
        </Paper>

        {/* Result Card */}
        {task.result && (
          <Paper elevation={2}>
            <Box p={2}>
              <Typography variant="h6" mb={2}>
                Result
              </Typography>
              <Box
                component="pre"
                sx={{
                  bgcolor: 'grey.100',
                  p: 2,
                  borderRadius: 1,
                  overflow: 'auto',
                  fontSize: isFoldClosed ? 10 : 12,
                }}
              >
                {task.result}
              </Box>
            </Box>
          </Paper>
        )}
      </Stack>
    </Box>
  )
}
