import { useEffect, useState } from 'react'
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  Paper,
  Stack,
  Chip,
  useMediaQuery,
} from '@mui/material'
import { LineChart } from '@mui/x-charts/LineChart'
import { TrendingUp, TrendingDown } from '@mui/icons-material'

interface CostData {
  date: string
  cost: number
}

export default function CostDashboard() {
  const isFoldClosed = useMediaQuery('(max-width: 280px)')
  const [costData, setCostData] = useState<CostData[]>([])

  useEffect(() => {
    // TODO: Fetch from API
    setCostData([
      { date: '11/10', cost: 12.5 },
      { date: '11/11', cost: 15.2 },
      { date: '11/12', cost: 18.7 },
      { date: '11/13', cost: 14.3 },
      { date: '11/14', cost: 22.1 },
      { date: '11/15', cost: 19.8 },
      { date: '11/16', cost: 16.5 },
    ])
  }, [])

  const todayCost = 16.50
  const weekCost = 119.10
  const monthCost = 245.80
  const dailyBudget = 25
  const monthlyBudget = 400

  return (
    <Box>
      <Typography variant={isFoldClosed ? "h6" : "h4"} mb={3}>
        Cost Dashboard
      </Typography>

      {/* Cost Chart */}
      <Paper elevation={2} sx={{ mb: 3, p: 2 }}>
        <Typography variant="h6" mb={2}>
          Daily Cost Trend
        </Typography>
        <Box sx={{ width: '100%', height: isFoldClosed ? 200 : 300 }}>
          <LineChart
            xAxis={[{ 
              scaleType: 'point', 
              data: costData.map(d => d.date),
              tickLabelStyle: { fontSize: isFoldClosed ? 10 : 12 }
            }]}
            series={[
              {
                data: costData.map(d => d.cost),
                label: 'Cost ($)',
                color: '#2196f3',
                curve: 'linear',
              },
            ]}
            height={isFoldClosed ? 200 : 300}
          />
        </Box>
      </Paper>

      {/* Cost Summary Cards */}
      <Grid container spacing={isFoldClosed ? 1 : 2}>
        <Grid item xs={12} md={4}>
          <Card elevation={2}>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Today
              </Typography>
              <Typography variant={isFoldClosed ? "h5" : "h3"} gutterBottom>
                ${todayCost.toFixed(2)}
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <Chip
                  icon={<TrendingDown fontSize="small" />}
                  label="Within budget"
                  color="success"
                  size="small"
                />
                <Typography variant="caption" color="text.secondary">
                  ${(dailyBudget - todayCost).toFixed(2)} remaining
                </Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card elevation={2}>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                This Week
              </Typography>
              <Typography variant={isFoldClosed ? "h5" : "h3"} gutterBottom>
                ${weekCost.toFixed(2)}
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <Chip
                  icon={<TrendingUp fontSize="small" />}
                  label="On track"
                  color="success"
                  size="small"
                />
                <Typography variant="caption" color="text.secondary">
                  Average ${(weekCost / 7).toFixed(2)}/day
                </Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card elevation={2}>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                This Month
              </Typography>
              <Typography variant={isFoldClosed ? "h5" : "h3"} gutterBottom>
                ${monthCost.toFixed(2)}
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <Chip
                  label={`${((monthCost / monthlyBudget) * 100).toFixed(0)}% of budget`}
                  color="warning"
                  size="small"
                />
                <Typography variant="caption" color="text.secondary">
                  ${(monthlyBudget - monthCost).toFixed(2)} left
                </Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}
