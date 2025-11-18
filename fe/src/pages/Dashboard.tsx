import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Box,
  Chip,
  useMediaQuery,
  useTheme,
  Paper,
  Stack,
} from '@mui/material'
import {
  PlayArrow,
  AttachMoney,
  TrendingUp,
  Storage,
  Add,
} from '@mui/icons-material'

interface Task {
  taskId: string
  agentType: string
  status: string
  createdAt: string
  cost?: number
}

interface Stats {
  activeTasks: number
  todayCost: number
  monthCost: number
  activeNodes: number
}

export default function Dashboard() {
  const theme = useTheme()
  const isFoldClosed = useMediaQuery('(max-width: 280px)')
  const isFoldOpen = useMediaQuery('(min-width: 654px)')
  
  const [tasks, setTasks] = useState<Task[]>([])
  const [stats, setStats] = useState<Stats>({
    activeTasks: 0,
    todayCost: 0,
    monthCost: 0,
    activeNodes: 0
  })

  useEffect(() => {
    // TODO: Fetch from API
    setTasks([
      {
        taskId: 'task-001',
        agentType: 'frontend',
        status: 'running',
        createdAt: new Date().toISOString(),
        cost: 1.25
      },
      {
        taskId: 'task-002',
        agentType: 'backend',
        status: 'completed',
        createdAt: new Date().toISOString(),
        cost: 2.50
      }
    ])

    setStats({
      activeTasks: 3,
      todayCost: 12.50,
      monthCost: 245.80,
      activeNodes: 2
    })
  }, [])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running': return 'primary'
      case 'completed': return 'success'
      case 'failed': return 'error'
      default: return 'default'
    }
  }

  return (
    <Box>
      <Stack 
        direction="row" 
        justifyContent="space-between" 
        alignItems="center" 
        mb={3}
        flexWrap="wrap"
        gap={2}
      >
        <Typography variant={isFoldClosed ? "h6" : "h4"} component="h1">
          Dashboard
        </Typography>
        <Button
          component={Link}
          to="/create"
          variant="contained"
          startIcon={<Add />}
          size={isFoldClosed ? "small" : "large"}
        >
          {isFoldClosed ? 'New' : 'Create Task'}
        </Button>
      </Stack>

      {/* Stats Grid */}
      <Grid container spacing={isFoldClosed ? 1 : 2} mb={3}>
        <Grid item xs={isFoldClosed ? 12 : 6} md={3}>
          <Card elevation={2}>
            <CardContent>
              <Stack direction="row" spacing={2} alignItems="center">
                <PlayArrow color="primary" fontSize={isFoldClosed ? "medium" : "large"} />
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Active Tasks
                  </Typography>
                  <Typography variant={isFoldClosed ? "h6" : "h4"}>
                    {stats.activeTasks}
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={isFoldClosed ? 12 : 6} md={3}>
          <Card elevation={2}>
            <CardContent>
              <Stack direction="row" spacing={2} alignItems="center">
                <AttachMoney color="success" fontSize={isFoldClosed ? "medium" : "large"} />
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Today's Cost
                  </Typography>
                  <Typography variant={isFoldClosed ? "h6" : "h4"}>
                    ${stats.todayCost.toFixed(2)}
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={isFoldClosed ? 12 : 6} md={3}>
          <Card elevation={2}>
            <CardContent>
              <Stack direction="row" spacing={2} alignItems="center">
                <TrendingUp color="warning" fontSize={isFoldClosed ? "medium" : "large"} />
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Month Cost
                  </Typography>
                  <Typography variant={isFoldClosed ? "h6" : "h4"}>
                    ${stats.monthCost.toFixed(2)}
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={isFoldClosed ? 12 : 6} md={3}>
          <Card elevation={2}>
            <CardContent>
              <Stack direction="row" spacing={2} alignItems="center">
                <Storage color="secondary" fontSize={isFoldClosed ? "medium" : "large"} />
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Active Nodes
                  </Typography>
                  <Typography variant={isFoldClosed ? "h6" : "h4"}>
                    {stats.activeNodes}
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Tasks */}
      <Paper elevation={2}>
        <Box p={2}>
          <Typography variant="h6" mb={2}>
            Recent Tasks
          </Typography>
          <Stack spacing={1}>
            {tasks.map((task) => (
              <Card
                key={task.taskId}
                variant="outlined"
                component={Link}
                to={`/task/${task.taskId}`}
                sx={{
                  textDecoration: 'none',
                  '&:hover': {
                    bgcolor: 'action.hover',
                  },
                }}
              >
                <CardContent>
                  <Stack
                    direction={isFoldClosed ? "column" : "row"}
                    justifyContent="space-between"
                    alignItems={isFoldClosed ? "flex-start" : "center"}
                    spacing={1}
                  >
                    <Box>
                      <Typography variant="subtitle1" fontWeight="medium">
                        {task.taskId}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {task.agentType}
                      </Typography>
                    </Box>
                    <Stack direction="row" spacing={1} alignItems="center">
                      <Chip
                        label={task.status}
                        color={getStatusColor(task.status)}
                        size="small"
                      />
                      {task.cost && (
                        <Typography variant="body2" color="text.secondary">
                          ${task.cost.toFixed(2)}
                        </Typography>
                      )}
                    </Stack>
                  </Stack>
                </CardContent>
              </Card>
            ))}
          </Stack>
        </Box>
      </Paper>
    </Box>
  )
}
