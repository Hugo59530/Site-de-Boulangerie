const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcryptjs');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = process.env.PORT || 3000;
const DB_PATH = path.join(__dirname, 'data', 'app.db');

const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('DB connection error:', err.message);
  } else {
    console.log('Connected to SQLite database');
  }
});

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) return reject(err);
      resolve(this);
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) return reject(err);
      resolve(row);
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'la-rhonelle-dev-secret',
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 1000 * 60 * 60 * 24 * 7 }
  })
);
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  next();
});

function requireAuth(req, res, next) {
  if (!req.session.user) {
    return res.redirect('/login');
  }
  next();
}

function requireRole(role) {
  return (req, res, next) => {
    if (!req.session.user || req.session.user.role !== role) {
      return res.redirect('/login');
    }
    next();
  };
}

async function initDatabase() {
  await run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'client'
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      message TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      manager_reply TEXT,
      replied_by TEXT,
      replied_at TEXT
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      notes TEXT,
      status TEXT NOT NULL DEFAULT 'en_cours',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);

  const existingManager = await get('SELECT * FROM users WHERE username = ?', ['manager']);
  if (!existingManager) {
    const hash = await bcrypt.hash('admin123', 10);
    await run('INSERT INTO users (username, password, role) VALUES (?, ?, ?)', ['manager', hash, 'manager']);
  }
}

app.get('/', (req, res) => res.render('pages/index', { user: req.session.user || null }));
app.get('/about', (req, res) => res.render('pages/about', { user: req.session.user || null }));
app.get('/gallery', (req, res) => res.render('pages/gallery', { user: req.session.user || null }));

app.get('/contact', (req, res) => {
  res.render('pages/contact', { user: req.session.user || null });
});

app.get('/dashboard', requireAuth, async (req, res) => {
  const user = req.session.user;

  if (user.role === 'manager') {
    const messages = await all('SELECT * FROM messages ORDER BY created_at DESC');
    res.render('pages/manager-dashboard', { user, messages });
    return;
  }

  const orders = await all('SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC', [user.id]);
  res.render('pages/customer-dashboard', { user, orders });
});

app.post('/orders', requireAuth, async (req, res) => {
  if (req.session.user.role !== 'client') {
    return res.redirect('/dashboard');
  }

  const productName = String(req.body.product_name || '').trim();
  const quantity = Number(req.body.quantity || 0);
  const notes = String(req.body.notes || '').trim();

  if (!productName || quantity <= 0) {
    return res.status(400).send('Produit et quantité requis.');
  }

  try {
    await run('INSERT INTO orders (user_id, product_name, quantity, notes) VALUES (?, ?, ?, ?)', [req.session.user.id, productName, quantity, notes]);
    res.redirect('/dashboard');
  } catch (error) {
    console.error('Order error:', error);
    res.status(500).send('Erreur lors de la commande.');
  }
});

app.post('/messages/:id/reply', requireRole('manager'), async (req, res) => {
  const id = Number(req.params.id);
  const reply = String(req.body.reply || '').trim();

  if (!reply) {
    return res.status(400).send('La réponse est vide.');
  }

  try {
    await run(
      'UPDATE messages SET manager_reply = ?, replied_by = ?, replied_at = CURRENT_TIMESTAMP WHERE id = ?',
      [reply, req.session.user.username, id]
    );
    res.redirect('/dashboard');
  } catch (error) {
    console.error('Reply error:', error);
    res.status(500).send('Erreur lors de l’envoi de la réponse.');
  }
});

app.listen(PORT, async () => {
  await initDatabase();
  console.log(`Server running on http://localhost:${PORT}`);
});

