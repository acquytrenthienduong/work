const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// In-memory storage for simplicity
let visitors = [];
let pageViews = 0;

// Routes
app.get('/', (req, res) => {
  pageViews++;
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  });
});

app.get('/api/stats', (req, res) => {
  res.json({
    pageViews,
    totalVisitors: visitors.length,
    memoryUsage: process.memoryUsage(),
    platform: process.platform,
    nodeVersion: process.version
  });
});

app.post('/api/visitors', (req, res) => {
  const visitor = {
    id: visitors.length + 1,
    name: req.body.name || 'Anonymous',
    timestamp: new Date().toISOString(),
    userAgent: req.headers['user-agent'] || 'Unknown'
  };
  
  visitors.push(visitor);
  res.status(201).json(visitor);
});

app.get('/api/visitors', (req, res) => {
  res.json(visitors);
});

// File operations để test volume mounting
app.get('/api/files', (req, res) => {
  try {
    const files = fs.readdirSync(__dirname);
    res.json(files);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/write-file', (req, res) => {
  try {
    const { filename, content } = req.body;
    const filePath = path.join(__dirname, 'data', filename);
    
    // Ensure data directory exists
    if (!fs.existsSync(path.join(__dirname, 'data'))) {
      fs.mkdirSync(path.join(__dirname, 'data'));
    }
    
    fs.writeFileSync(filePath, content);
    res.json({ message: 'File written successfully', filename });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
}); 