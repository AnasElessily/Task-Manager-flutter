const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');

const app = express();
const PORT = 3000;
const SECRET_KEY = 'your_secret_key'; // In a real app, use environment variables

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Ensure uploads directory exists
if (!fs.existsSync('./uploads')) {
    fs.mkdirSync('./uploads');
}

// Database Setup
const db = new sqlite3.Database('./database.db', (err) => {
    if (err) console.error('Error opening database', err);
    else console.log('Connected to SQLite database');
});

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT,
        email TEXT UNIQUE,
        studentId TEXT,
        gender TEXT,
        level INTEGER,
        password TEXT,
        profileImage TEXT,
        updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        title TEXT,
        description TEXT,
        dueDate TEXT,
        priority TEXT,
        isCompleted INTEGER DEFAULT 0,
        updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        deletedAt DATETIME,
        FOREIGN KEY(userId) REFERENCES users(id)
    )`);
});

// Multer Setup for Image Uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, './uploads/'),
    filename: (req, file, cb) => {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});
const upload = multer({ storage });

// --- Auth Routes ---

app.post('/api/register', (req, res) => {
    const { fullName, email, studentId, gender, level, password } = req.body;
    const hashedPassword = bcrypt.hashSync(password, 8);

    const query = `INSERT INTO users (fullName, email, studentId, gender, level, password) VALUES (?, ?, ?, ?, ?, ?)`;
    db.run(query, [fullName, email, studentId, gender, level, hashedPassword], function(err) {
        if (err) {
            return res.status(400).json({ error: 'Email already exists or invalid data' });
        }
        res.json({ id: this.lastID, message: 'User registered successfully' });
    });
});

app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    const query = `SELECT * FROM users WHERE email = ?`;
    db.get(query, [email], (err, user) => {
        if (err || !user) return res.status(404).json({ error: 'User not found' });

        const passwordIsValid = bcrypt.compareSync(password, user.password);
        if (!passwordIsValid) return res.status(401).json({ error: 'Invalid password' });

        const token = jwt.sign({ id: user.id }, SECRET_KEY, { expiresIn: 86400 });
        res.json({ user, token });
    });
});

// --- User Profile Routes ---

app.put('/api/profile', (req, res) => {
    const { id, fullName, email, studentId, gender, level } = req.body;
    
    const query = `UPDATE users SET fullName = ?, email = ?, studentId = ?, gender = ?, level = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ?`;
    db.run(query, [fullName, email, studentId, gender, level, id], function(err) {
        if (err) return res.status(400).json({ error: err.message });
        res.json({ message: 'Profile updated' });
    });
});

app.post('/api/profile/image', upload.single('image'), (req, res) => {
    const { userId } = req.body;
    const imageUrl = `/uploads/${req.file.filename}`;

    db.run(`UPDATE users SET profileImage = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ?`, [imageUrl, userId], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ imageUrl });
    });
});

// --- Task Routes ---

app.get('/api/tasks/:userId', (req, res) => {
    const { userId } = req.params;
    db.all(`SELECT * FROM tasks WHERE userId = ? AND deletedAt IS NULL`, [userId], (err, tasks) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(tasks);
    });
});

app.post('/api/tasks/sync', (req, res) => {
    const { userId, tasks } = req.body; // tasks is an array of task objects from local DB
    
    // Simple Sync: Add or Update tasks
    const stmt = db.prepare(`INSERT OR REPLACE INTO tasks (id, userId, title, description, dueDate, priority, isCompleted, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`);
    
    db.serialize(() => {
        tasks.forEach(task => {
            stmt.run(task.id, userId, task.title, task.description, task.dueDate, task.priority, task.isCompleted);
        });
        stmt.finalize();
        res.json({ message: 'Synced successfully' });
    });
});

app.delete('/api/tasks/:id', (req, res) => {
    const { id } = req.params;
    db.run(`UPDATE tasks SET deletedAt = CURRENT_TIMESTAMP WHERE id = ?`, [id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Task deleted' });
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${PORT}`);
});
