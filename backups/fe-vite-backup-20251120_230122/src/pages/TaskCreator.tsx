import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Button,
  Card,
  CardContent,
  Grid,
  TextField,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
  Chip,
  useMediaQuery,
  Paper,
} from '@mui/material'
import {
  Code,
  Api,
  Cloud,
  BugReport,
  Science,
  Engineering,
  Description,
  Business,
  Architecture,
  Security,
  RouteOutlined,
} from '@mui/icons-material'

const AGENT_TYPES = [
  { id: 'triage', name: 'Triage', description: 'Route and prioritize', tier: 'cpu', icon: <RouteOutlined /> },
  { id: 'frontend', name: 'Frontend', description: 'React UI development', tier: 'medium-gpu', icon: <Code /> },
  { id: 'backend', name: 'Backend', description: 'API development', tier: 'medium-gpu', icon: <Api /> },
  { id: 'networking', name: 'Networking', description: 'Infrastructure', tier: 'medium-gpu', icon: <Cloud /> },
  { id: 'debugging', name: 'Debugging', description: 'Error analysis', tier: 'medium-gpu', icon: <BugReport /> },
  { id: 'qa', name: 'QA', description: 'Test generation', tier: 'medium-gpu', icon: <Science /> },
  { id: 'sre', name: 'SRE', description: 'Reliability', tier: 'medium-gpu', icon: <Engineering /> },
  { id: 'doc', name: 'Documentation', description: 'Technical writing', tier: 'cpu', icon: <Description /> },
  { id: 'pm', name: 'Product Manager', description: 'Requirements', tier: 'cpu', icon: <Business /> },
  { id: 'architecture', name: 'Architecture', description: 'System design', tier: 'high-gpu', icon: <Architecture /> },
  { id: 'security', name: 'Security', description: 'Security audit', tier: 'high-gpu', icon: <Security /> },
]

export default function TaskCreator() {
  const navigate = useNavigate()
  const isFoldClosed = useMediaQuery('(max-width: 280px)')
  const [selectedAgent, setSelectedAgent] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState('medium')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)

    try {
      // TODO: Submit to API
      const response = await fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          agentType: selectedAgent,
          description,
          priority
        })
      })

      const data = await response.json()
      navigate(`/task/${data.taskId}`)
    } catch (error) {
      console.error('Failed to create task:', error)
    } finally {
      setSubmitting(false)
    }
  }

  const getTierColor = (tier: string) => {
    switch (tier) {
      case 'cpu': return 'default'
      case 'medium-gpu': return 'primary'
      case 'high-gpu': return 'secondary'
      default: return 'default'
    }
  }

  return (
    <Box component="form" onSubmit={handleSubmit}>
      <Typography variant={isFoldClosed ? "h6" : "h4"} mb={3}>
        Create New Task
      </Typography>

      <Stack spacing={3}>
        {/* Agent Selection */}
        <Paper elevation={2}>
          <Box p={2}>
            <Typography variant="h6" mb={2}>
              Select Agent Type
            </Typography>
            <Grid container spacing={isFoldClosed ? 1 : 2}>
              {AGENT_TYPES.map((agent) => (
                <Grid item xs={isFoldClosed ? 12 : 6} md={4} key={agent.id}>
                  <Card
                    variant={selectedAgent === agent.id ? 'elevation' : 'outlined'}
                    sx={{
                      cursor: 'pointer',
                      border: selectedAgent === agent.id ? 2 : 1,
                      borderColor: selectedAgent === agent.id ? 'primary.main' : 'divider',
                      bgcolor: selectedAgent === agent.id ? 'action.selected' : 'background.paper',
                      '&:hover': {
                        bgcolor: 'action.hover',
                      },
                    }}
                    onClick={() => setSelectedAgent(agent.id)}
                  >
                    <CardContent>
                      <Stack direction="row" spacing={1} alignItems="center" mb={1}>
                        {agent.icon}
                        <Typography variant="subtitle1" fontWeight="medium">
                          {agent.name}
                        </Typography>
                      </Stack>
                      <Typography variant="body2" color="text.secondary" mb={1}>
                        {agent.description}
                      </Typography>
                      <Chip
                        label={agent.tier}
                        size="small"
                        color={getTierColor(agent.tier)}
                      />
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        </Paper>

        {/* Task Description */}
        <Paper elevation={2}>
          <Box p={2}>
            <Typography variant="h6" mb={2}>
              Task Description
            </Typography>
            <TextField
              fullWidth
              multiline
              rows={isFoldClosed ? 4 : 6}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe what you want the agent to do..."
              required
            />
          </Box>
        </Paper>

        {/* Priority */}
        <Paper elevation={2}>
          <Box p={2}>
            <Typography variant="h6" mb={2}>
              Priority Level
            </Typography>
            <FormControl fullWidth>
              <InputLabel>Priority</InputLabel>
              <Select
                value={priority}
                label="Priority"
                onChange={(e) => setPriority(e.target.value)}
              >
                <MenuItem value="low">Low</MenuItem>
                <MenuItem value="medium">Medium</MenuItem>
                <MenuItem value="high">High</MenuItem>
                <MenuItem value="extreme">Extreme Power Mode</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </Paper>

        {/* Submit Buttons */}
        <Stack direction="row" spacing={2} justifyContent="flex-end">
          <Button
            variant="outlined"
            onClick={() => navigate('/')}
            size={isFoldClosed ? "small" : "large"}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={!selectedAgent || !description || submitting}
            size={isFoldClosed ? "small" : "large"}
          >
            {submitting ? 'Creating...' : 'Create Task'}
          </Button>
        </Stack>
      </Stack>
    </Box>
  )
}
