# Analytics Dashboard

A real-time analytics dashboard for monitoring application metrics,
user activity, and system health. Features interactive charts and alerts.

## Features
- Real-time metric tracking
- Interactive charts (line, bar, pie)
- Custom dashboard layouts
- Alert rules and notifications
- Data export (CSV, JSON)
- Date range filtering
- Multi-tenant support
- Dark and light themes

## Pages
- Main dashboard with overview cards
- Metrics detail page with charts
- Alert configuration page
- Settings page
- Data export page

## API Endpoints
- GET /metrics
- GET /metrics/:name
- GET /metrics/:name/history
- POST /alerts
- GET /alerts
- PUT /alerts/:id
- DELETE /alerts/:id
- GET /dashboard/config
- PUT /dashboard/config
- GET /export/:format
