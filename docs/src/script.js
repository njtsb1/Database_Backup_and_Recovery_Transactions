const strings = {
  "en": {
    title: "Ecommerce Demo",
    subtitle: "A minimal demo for transactions, backup and UI",
    homeTitle: "Welcome",
    homeDesc: "This small demo shows transactions, procedures and backup guidance.",
    quickStart: "Quick Start",
    backups: "Backups",
    schema: "Schema",
    transactions: "Transactions",
    backup: "Backup & Recovery",
    footer: "Accessible • Responsive • Multilingual",
    btnLoadSchema: "Load Schema",
    btnRunSample: "Run Sample",
    btnBackupCommands: "Show Backup Commands"
  },
  "pt-BR": {
    title: "Demonstração Ecommerce",
    subtitle: "Um demo mínimo para transações, backup e UI",
    homeTitle: "Bem-vindo",
    homeDesc: "Este pequeno demo mostra transações, procedimentos e orientações de backup.",
    quickStart: "Início Rápido",
    backups: "Backups",
    schema: "Esquema",
    transactions: "Transações",
    backup: "Backup e Recuperação",
    footer: "Acessível • Responsivo • Multilíngue",
    btnLoadSchema: "Carregar Esquema",
    btnRunSample: "Executar Exemplo",
    btnBackupCommands: "Mostrar Comandos de Backup"
  },
  "es": {
    title: "Demostración Ecommerce",
    subtitle: "Un demo mínimo para transacciones, backup y UI",
    homeTitle: "Bienvenido",
    homeDesc: "Este pequeño demo muestra transacciones, procedimientos y guías de backup.",
    quickStart: "Inicio Rápido",
    backups: "Backups",
    schema: "Esquema",
    transactions: "Transacciones",
    backup: "Backup y Recuperación",
    footer: "Accesible • Responsive • Multilingüe",
    btnLoadSchema: "Cargar Esquema",
    btnRunSample: "Ejecutar Ejemplo",
    btnBackupCommands: "Mostrar Comandos de Backup"
  }
};

/* Persisted settings */
const LS_THEME = 'demo_theme';
const LS_LANG = 'demo_lang';

/* Elements */
const themeToggle = document.getElementById('theme-toggle');
const themeIcon = document.getElementById('theme-icon');
const langSelect = document.getElementById('lang');
const siteTitle = document.getElementById('site-title');
const siteSubtitle = document.getElementById('site-subtitle');
const footerText = document.getElementById('footer-text');
const navButtons = document.querySelectorAll('.nav-btn');
const pages = document.querySelectorAll('.page');
const yearSpan = document.getElementById('year');

const schemaCodeEl = document.getElementById('schema-code');
const transactionsCodeEl = document.getElementById('transactions-code');
const backupCodeEl = document.getElementById('backup-code');

/* Sample content (short excerpts from your provided files) */
const sampleSchema = `-- sample_schema.sql
CREATE TABLE products (...);
CREATE TABLE customers (...);
CREATE TABLE orders (...);
CREATE TABLE order_items (...);
-- Use the provided sample_schema.sql for full content.`;

const sampleTransactions = `-- transactions.sql
SET autocommit = 0;
START TRANSACTION;
-- insert order and items...
COMMIT;`;

const sampleBackup = `# mysqldump examples
mysqldump -u root -p --databases ecommerce > ecommerce_backup.sql
mysqldump -u root -p --routines --events --triggers --databases ecommerce > ecommerce_full_backup.sql
gunzip < ecommerce_full_backup.sql.gz | mysql -u root -p`;

/* Initialize UI */
function applyStrings(lang) {
  const s = strings[lang] || strings['en'];
  siteTitle.textContent = s.title;
  siteSubtitle.textContent = s.subtitle;
  document.getElementById('home-title').textContent = s.homeTitle;
  document.getElementById('home-desc').textContent = s.homeDesc;
  document.getElementById('schema-title').textContent = s.schema;
  document.getElementById('transactions-title').textContent = s.transactions;
  document.getElementById('backup-title').textContent = s.backup;
  footerText.textContent = `© ${new Date().getFullYear()} ${s.title} — ${s.footer}`;
  document.querySelectorAll('.nav-btn')[0].textContent = 'Home';
  document.querySelectorAll('.nav-btn')[1].textContent = s.schema;
  document.querySelectorAll('.nav-btn')[2].textContent = s.transactions;
  document.querySelectorAll('.nav-btn')[3].textContent = s.backup;
  document.getElementById('btn-schema').textContent = s.btnLoadSchema;
  document.getElementById('btn-run-sample').textContent = s.btnRunSample;
  document.getElementById('btn-backup').textContent = s.btnBackupCommands;
}

/* Theme handling */
function setTheme(theme) {
  if (theme === 'light') {
    document.documentElement.classList.add('light');
    themeIcon.innerHTML = sunSVG();
    themeToggle.setAttribute('aria-pressed', 'true');
  } else {
    document.documentElement.classList.remove('light');
    themeIcon.innerHTML = moonSVG();
    themeToggle.setAttribute('aria-pressed', 'false');
  }
  localStorage.setItem(LS_THEME, theme);
}

/* SVG icons */
function moonSVG() {
  return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg">
    <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z" fill="currentColor"/>
  </svg>`;
}
function sunSVG() {
  return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg">
    <path d="M6.76 4.84l-1.8-1.79L3.17 4.84l1.79 1.8 1.8-1.8zM1 13h3v-2H1v2zm10 9h2v-3h-2v3zM17.24 19.16l1.8 1.79 1.79-1.79-1.8-1.8-1.79 1.8zM20 11v2h3v-2h-3zM12 5a7 7 0 100 14 7 7 0 000-14z" fill="currentColor"/>
  </svg>`;
}

/* Navigation */
navButtons.forEach(btn => {
  btn.addEventListener('click', (e) => {
    const target = btn.getAttribute('data-target');
    navigateTo(target);
  });
});

function navigateTo(target) {
  pages.forEach(p => p.classList.remove('active'));
  navButtons.forEach(nb => {
    nb.classList.remove('active');
    nb.setAttribute('aria-pressed', 'false');
  });

  const btn = Array.from(navButtons).find(n => n.dataset.target === target);
  if (btn) {
    btn.classList.add('active');
    btn.setAttribute('aria-pressed', 'true');
  }

  const page = document.getElementById(target);
  if (page) {
    page.classList.add('active');
    page.focus();
  }
}

/* Load persisted settings */
document.addEventListener('DOMContentLoaded', () => {
  // Year
  yearSpan.textContent = new Date().getFullYear();

  // Language
  const savedLang = localStorage.getItem(LS_LANG) || 'en';
  langSelect.value = savedLang;
  applyStrings(savedLang);

  // Theme
  const savedTheme = localStorage.getItem(LS_THEME) || 'dark';
  setTheme(savedTheme);

  // Populate code blocks
  schemaCodeEl.textContent = sampleSchema;
  transactionsCodeEl.textContent = sampleTransactions;
  backupCodeEl.textContent = sampleBackup;

  // Buttons
  document.getElementById('btn-schema').addEventListener('click', () => {
    navigateTo('schema');
  });
  document.getElementById('btn-run-sample').addEventListener('click', () => {
    alert(strings[langSelect.value].btnRunSample + ' — run SQL locally in your DB client.');
  });
  document.getElementById('btn-backup').addEventListener('click', () => {
    navigateTo('backup');
  });
});

/* Theme toggle click */
themeToggle.addEventListener('click', () => {
  const isLight = document.documentElement.classList.contains('light');
  setTheme(isLight ? 'dark' : 'light');
});

/* Language change */
langSelect.addEventListener('change', (e) => {
  const lang = e.target.value;
  localStorage.setItem(LS_LANG, lang);
  applyStrings(lang);
});

/* Keyboard navigation: left/right to switch pages */
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
    const order = ['home','schema','transactions','backup'];
    const activeIndex = order.findIndex(id => document.getElementById(id).classList.contains('active'));
    let next = activeIndex;
    if (e.key === 'ArrowLeft') next = Math.max(0, activeIndex - 1);
    if (e.key === 'ArrowRight') next = Math.min(order.length - 1, activeIndex + 1);
    navigateTo(order[next]);
  }
});
