require('dotenv').config();

const express = require('express');
const cors = require('cors');

const admin = require('firebase-admin');
const serviceAccount = require('./config/firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const authRoutes = require('./routes/auth.routes');
const groupRoutes = require('./routes/groups.routes');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/groups', groupRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', app: 'StudySync API', timestamp: new Date() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`StudySync API running on port ${PORT}`);
});
