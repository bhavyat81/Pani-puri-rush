/* ===== Pani Puri Rush – Game Logic ===== */

'use strict';

// ── Constants ──────────────────────────────────────────────────────────────
const FLAVORS = ['spicy', 'sweet', 'tangy', 'mint'];

const FLAVOR_META = {
  spicy: { emoji: '🌶️', label: 'Spicy',  color: '#e64a19' },
  sweet: { emoji: '🍯', label: 'Sweet',  color: '#f9a825' },
  tangy: { emoji: '🍋', label: 'Tangy',  color: '#9e9d24' },
  mint:  { emoji: '🌿', label: 'Mint',   color: '#2e7d32' },
};

const CUSTOMER_EMOJIS = ['👩','👨','👧','👦','👴','👵','🧑','👲','👳','🧕','🙋','🙆'];

const MAX_CUSTOMERS      = 5;
const POINTS_PER_ORDER   = 10;   // multiplied by current level
const ORDERS_PER_LEVEL   = 5;    // correct orders needed to level up
const BASE_SPAWN_MS      = 3200; // ms between spawns (decreases with level)
const MIN_SPAWN_MS       = 900;
const BASE_PATIENCE_RATE = 0.28; // % per 100 ms
const PATIENCE_RATE_INC  = 0.04; // extra per level
const TICK_MS            = 100;

// ── State ──────────────────────────────────────────────────────────────────
let score         = 0;
let lives         = 3;
let level         = 1;
let correctOrders = 0;
let selectedFlavor = null;
let customers     = [];     // active customer objects
let idCounter     = 0;
let gameRunning   = false;
let spawnTimer    = null;
let tickTimer     = null;

// ── DOM refs ───────────────────────────────────────────────────────────────
const scoreEl         = document.getElementById('score');
const livesEl         = document.getElementById('lives');
const levelNumEl      = document.getElementById('level-num');
const selectedDisplay = document.getElementById('selected-display');
const customerArea    = document.getElementById('customer-area');
const startScreen     = document.getElementById('start-screen');
const gameOverScreen  = document.getElementById('game-over-screen');
const finalScoreEl    = document.getElementById('final-score');
const finalLevelEl    = document.getElementById('final-level');
const gameContainer   = document.getElementById('game-container');

// ── Initialisation ─────────────────────────────────────────────────────────
document.getElementById('start-btn').addEventListener('click', startGame);
document.getElementById('restart-btn').addEventListener('click', restartGame);

document.querySelectorAll('.flavor-btn').forEach(btn => {
  btn.addEventListener('click', () => selectFlavor(btn.dataset.flavor));
});

// ── Game Flow ──────────────────────────────────────────────────────────────
function startGame() {
  score          = 0;
  lives          = 3;
  level          = 1;
  correctOrders  = 0;
  selectedFlavor = null;
  customers      = [];
  idCounter      = 0;
  gameRunning    = true;

  customerArea.innerHTML = '';
  selectedDisplay.textContent = 'No flavor selected';
  selectedDisplay.style.color = '';
  document.querySelectorAll('.flavor-btn').forEach(b => b.classList.remove('active'));

  startScreen.classList.add('hidden');
  gameOverScreen.classList.add('hidden');

  refreshHUD();
  spawnCustomer();
  spawnTimer = setInterval(spawnCustomer, spawnInterval());
  tickTimer  = setInterval(tick, TICK_MS);
}

function restartGame() {
  clearInterval(spawnTimer);
  clearInterval(tickTimer);
  customerArea.innerHTML = '';
  startGame();
}

function endGame() {
  gameRunning = false;
  clearInterval(spawnTimer);
  clearInterval(tickTimer);

  finalScoreEl.textContent = score;
  finalLevelEl.textContent = level;
  gameOverScreen.classList.remove('hidden');
}

// ── Helpers ────────────────────────────────────────────────────────────────
function spawnInterval() {
  return Math.max(MIN_SPAWN_MS, BASE_SPAWN_MS - (level - 1) * 300);
}

function patienceRate() {
  return BASE_PATIENCE_RATE + (level - 1) * PATIENCE_RATE_INC;
}

// ── Flavour Selection ──────────────────────────────────────────────────────
function selectFlavor(flavor) {
  selectedFlavor = flavor;
  const meta = FLAVOR_META[flavor];
  selectedDisplay.textContent = `${meta.emoji} ${meta.label} selected`;
  selectedDisplay.style.color = meta.color;

  document.querySelectorAll('.flavor-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.flavor === flavor);
  });
}

// ── Customers ──────────────────────────────────────────────────────────────
function spawnCustomer() {
  if (!gameRunning || customers.length >= MAX_CUSTOMERS) return;

  const flavor  = FLAVORS[Math.floor(Math.random() * FLAVORS.length)];
  const emoji   = CUSTOMER_EMOJIS[Math.floor(Math.random() * CUSTOMER_EMOJIS.length)];
  const id      = ++idCounter;

  const customer = { id, wantsFlavor: flavor, emoji, patience: 100, served: false };
  customers.push(customer);
  renderCustomer(customer);
}

function renderCustomer(customer) {
  const div = document.createElement('div');
  div.className = 'customer';
  div.id = `c-${customer.id}`;

  div.innerHTML = `
    <div class="order-bubble">${FLAVOR_META[customer.wantsFlavor].emoji}</div>
    <div class="customer-emoji" id="emoji-${customer.id}">${customer.emoji}</div>
    <div class="patience-bar-container">
      <div class="patience-bar" id="pb-${customer.id}" style="width:100%;background:#43a047;"></div>
    </div>
  `;

  div.addEventListener('click', () => serveCustomer(customer.id));
  customerArea.appendChild(div);
}

function serveCustomer(id) {
  if (!gameRunning) return;

  if (!selectedFlavor) {
    // Prompt the player to pick a flavor first
    selectedDisplay.classList.add('shake');
    selectedDisplay.textContent = '⚠️ Pick a flavor first!';
    selectedDisplay.style.color = '#c62828';
    setTimeout(() => {
      selectedDisplay.classList.remove('shake');
      selectedDisplay.textContent = 'No flavor selected';
      selectedDisplay.style.color = '';
    }, 900);
    return;
  }

  const customer = customers.find(c => c.id === id && !c.served);
  if (!customer) return;

  customer.served = true;

  const cardEl  = document.getElementById(`c-${id}`);
  const emojiEl = document.getElementById(`emoji-${id}`);

  if (selectedFlavor === customer.wantsFlavor) {
    // ✅ Correct
    const pts = POINTS_PER_ORDER * level;
    score += pts;
    correctOrders++;
    cardEl.classList.add('happy');
    emojiEl.textContent = '😄';
    showFloat(cardEl, `+${pts}`, '#2e7d32');

    refreshScore();

    if (correctOrders % ORDERS_PER_LEVEL === 0) levelUp();
  } else {
    // ❌ Wrong
    lives--;
    cardEl.classList.add('sad');
    emojiEl.textContent = '😤';
    showFloat(cardEl, '❌ -1 ❤️', '#c62828');
    refreshLives();
  }

  setTimeout(() => {
    dismissCustomer(id);
    if (lives <= 0) endGame();
  }, 800);
}

// ── Patience Tick ──────────────────────────────────────────────────────────
function tick() {
  if (!gameRunning) return;

  customers.forEach(customer => {
    if (customer.served) return;

    customer.patience -= patienceRate();
    const pct = Math.max(0, customer.patience);

    const bar = document.getElementById(`pb-${customer.id}`);
    if (bar) {
      bar.style.width      = `${pct}%`;
      bar.style.background = pct > 60 ? '#43a047' : pct > 30 ? '#f9a825' : '#e53935';
    }

    if (customer.patience <= 0) {
      customer.served = true;
      lives--;

      const cardEl  = document.getElementById(`c-${customer.id}`);
      const emojiEl = document.getElementById(`emoji-${customer.id}`);
      if (cardEl)  cardEl.classList.add('sad');
      if (emojiEl) emojiEl.textContent = '😡';
      if (cardEl)  showFloat(cardEl, '⏱️ -1 ❤️', '#c62828');

      refreshLives();

      setTimeout(() => {
        dismissCustomer(customer.id);
        if (lives <= 0) endGame();
      }, 800);
    }
  });
}

function dismissCustomer(id) {
  const el = document.getElementById(`c-${id}`);
  if (el) el.remove();
  customers = customers.filter(c => c.id !== id);
}

// ── Level Up ───────────────────────────────────────────────────────────────
function levelUp() {
  level++;
  refreshLevel();

  // Reset spawn interval at new speed
  clearInterval(spawnTimer);
  spawnTimer = setInterval(spawnCustomer, spawnInterval());

  const notice = document.createElement('div');
  notice.className = 'level-up-notice';
  notice.textContent = `🚀 Level ${level}!`;
  gameContainer.appendChild(notice);
  setTimeout(() => notice.remove(), 2000);
}

// ── HUD Updates ────────────────────────────────────────────────────────────
function refreshHUD() {
  refreshScore();
  refreshLives();
  refreshLevel();
}

function refreshScore() {
  scoreEl.textContent = score;
}

function refreshLives() {
  livesEl.textContent = lives > 0 ? '❤️'.repeat(lives) : '💔';
}

function refreshLevel() {
  levelNumEl.textContent = level;
}

// ── Floating Text ──────────────────────────────────────────────────────────
function showFloat(parentEl, text, color) {
  const el = document.createElement('div');
  el.className   = 'floating-text';
  el.textContent = text;
  el.style.color = color;
  parentEl.appendChild(el);
  setTimeout(() => el.remove(), 1100);
}
