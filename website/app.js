/**
 * FloatingKeyboard — Official Website Interactive Engine
 * • Dynamic Live Canvas Theme Animations (Fire embers, Thunder lightning & rain, Neon scanlines, Manolo gold shockwaves, Glass specular sweep)
 * • Zero-Latency Mechanical Switch Sound Engine (Real audio samples + Web Audio synthesizer fallback)
 * • Auto-cycling Theme Showcase with Interactive Tabs & Hover-Pause
 * • System-wide Interactive Sound Feedback on Keys and UI Controls
 */

// ═══════════════════════════════════════════════════════════════════════════
// 1. Theme Configuration & Data
// ═══════════════════════════════════════════════════════════════════════════

const THEMES = {
  glass: {
    name: 'Glass',
    image: 'assets/screenshots/keyboard-desktop-glass.png',
    desc: 'Classic frosted ultra-thin translucent glass with subtle refraction and dark system keycaps.',
    accent: '#0A84FF'
  },
  neon: {
    name: 'Cyber Neon',
    image: 'assets/screenshots/keyboard-desktop-neon.png',
    desc: 'Deep pitch obsidian chassis with glowing electric cyan typography and neon reactive accents.',
    accent: '#00F0FF'
  },
  fire: {
    name: 'Blazing Fire',
    image: 'assets/screenshots/keyboard-desktop-fire.png',
    desc: 'Crimson-amber volcanic gradient with warm golden key typography and amber lock badge.',
    accent: '#FF4500'
  },
  thunder: {
    name: 'Thunder Storm',
    image: 'assets/screenshots/keyboard-desktop-thunder.png',
    desc: 'Atmospheric midnight indigo storm aesthetic with electric blue rainfall and lightning ambiance.',
    accent: '#5E5CE6'
  },
  dark: {
    name: 'Dark Obsidian',
    image: 'assets/screenshots/keyboard-desktop-dark.png',
    desc: 'Minimalist stealth dark mode engineered for maximum contrast in low-light coding environments.',
    accent: '#8E8E93'
  },
  light: {
    name: 'Pure Light',
    image: 'assets/screenshots/keyboard-desktop-light.png',
    desc: 'Clean, high-visibility daylight aesthetic with crisp tactile contrast and black typography.',
    accent: '#007AFF'
  },
  manolo: {
    name: 'Manolo Signature',
    image: 'assets/screenshots/keyboard-desktop-manolo.png',
    desc: 'Exclusive bespoke theme with golden perimeter framing and dynamic shockwave particle effects.',
    accent: '#FFD700'
  }
};

const SOUND_ASSETS = {
  thocky: [
    'assets/sounds/thock_0.mp3',
    'assets/sounds/thock_1.mp3',
    'assets/sounds/thock_2.mp3',
    'assets/sounds/thock_3.mp3',
    'assets/sounds/thock_4.mp3',
    'assets/sounds/thock_space.mp3'
  ],
  clicky: [
    'assets/sounds/clicky_0.mp3',
    'assets/sounds/clicky_1.mp3',
    'assets/sounds/clicky_2.mp3',
    'assets/sounds/clicky_3.mp3',
    'assets/sounds/clicky_4.mp3',
    'assets/sounds/clicky.wav'
  ],
  tactile: [
    'assets/sounds/tactile_0.mp3',
    'assets/sounds/tactile_1.mp3',
    'assets/sounds/tactile_2.mp3',
    'assets/sounds/tactile_3.mp3',
    'assets/sounds/tactile_4.mp3',
    'assets/sounds/tactile_enter.mp3',
    'assets/sounds/tactile_backspace.mp3'
  ],
  futuristic: [
    'assets/sounds/futuristic.wav'
  ]
};

// ═══════════════════════════════════════════════════════════════════════════
// 2. Live Theme Canvas Particle Engine
// ═══════════════════════════════════════════════════════════════════════════

class ThemeCanvasAnimator {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');
    this.currentTheme = 'glass';
    this.particles = [];
    this.lightningBranches = [];
    this.lightningIntensity = 0;
    this.nextLightningTime = Date.now() + 2500;
    this.sweepProgress = 0;
    this.shockwaves = [];
    this.animId = null;

    this.resize();
    window.addEventListener('resize', () => this.resize());
    this.initParticles();
    this.start();
  }

  resize() {
    const rect = this.canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    this.width = rect.width;
    this.height = rect.height;
    this.canvas.width = Math.floor(rect.width * dpr);
    this.canvas.height = Math.floor(rect.height * dpr);
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  setTheme(themeKey) {
    if (this.currentTheme === themeKey) return;
    this.currentTheme = themeKey;
    this.particles = [];
    this.shockwaves = [];
    this.lightningIntensity = 0;
    this.initParticles();
  }

  initParticles() {
    const w = this.width || 800;
    const h = this.height || 260;

    if (this.currentTheme === 'fire') {
      for (let i = 0; i < 65; i++) {
        this.particles.push({
          x: Math.random() * w,
          y: h - Math.random() * 40,
          vx: (Math.random() - 0.5) * 1.2,
          vy: -(Math.random() * 1.8 + 0.8),
          size: Math.random() * 3 + 1.2,
          alpha: Math.random() * 0.9 + 0.1,
          decay: Math.random() * 0.012 + 0.005,
          hue: Math.random() * 35 + 15 // 15 = crimson/amber, 45 = gold
        });
      }
    } else if (this.currentTheme === 'thunder') {
      for (let i = 0; i < 70; i++) {
        this.particles.push({
          x: Math.random() * (w + 100),
          y: Math.random() * h,
          vx: -1.2 - Math.random() * 0.8,
          vy: Math.random() * 12 + 10,
          length: Math.random() * 18 + 12,
          alpha: Math.random() * 0.4 + 0.2
        });
      }
    } else if (this.currentTheme === 'neon') {
      for (let i = 0; i < 35; i++) {
        this.particles.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.6,
          vy: (Math.random() - 0.5) * 0.6,
          size: Math.random() * 2.5 + 1,
          color: Math.random() > 0.4 ? 'rgba(0, 240, 255,' : 'rgba(255, 0, 180,',
          alpha: Math.random() * 0.7 + 0.2
        });
      }
    } else if (this.currentTheme === 'manolo') {
      for (let i = 0; i < 45; i++) {
        this.particles.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.8,
          vy: -(Math.random() * 0.8 + 0.2),
          size: Math.random() * 3 + 1,
          alpha: Math.random() * 0.8 + 0.2,
          decay: Math.random() * 0.008 + 0.004,
          spin: Math.random() * Math.PI * 2
        });
      }
      this.shockwaves.push({ x: w / 2, y: h / 2, r: 10, alpha: 0.9 });
    } else if (this.currentTheme === 'glass') {
      for (let i = 0; i < 20; i++) {
        this.particles.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.4,
          vy: -(Math.random() * 0.3 + 0.1),
          r: Math.random() * 16 + 6,
          alpha: Math.random() * 0.18 + 0.06
        });
      }
    }
  }

  triggerSpark(x, y) {
    for (let i = 0; i < 12; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 4 + 1.5;
      this.particles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        size: Math.random() * 2.5 + 1.5,
        alpha: 1.0,
        decay: 0.035,
        hue: this.currentTheme === 'neon' ? 190 : 38
      });
    }
  }

  generateLightningBolt(w, h) {
    const startX = Math.random() * w * 0.7 + w * 0.15;
    const branches = [];
    let curX = startX;
    let curY = 0;

    while (curY < h * 0.85) {
      const nextX = curX + (Math.random() - 0.5) * 45;
      const nextY = curY + Math.random() * 25 + 15;
      branches.push({ x1: curX, y1: curY, x2: nextX, y2: nextY });

      // Occasional sub-branch
      if (Math.random() > 0.65) {
        const subX = nextX + (Math.random() - 0.5) * 35;
        const subY = nextY + Math.random() * 20 + 10;
        branches.push({ x1: nextX, y1: nextY, x2: subX, y2: subY });
      }

      curX = nextX;
      curY = nextY;
    }
    return branches;
  }

  start() {
    const loop = () => {
      this.render();
      this.animId = requestAnimationFrame(loop);
    };
    this.animId = requestAnimationFrame(loop);
  }

  render() {
    const ctx = this.ctx;
    const w = this.width;
    const h = this.height;
    if (!ctx || !w || !h) return;

    ctx.clearRect(0, 0, w, h);

    switch (this.currentTheme) {
      case 'fire':
        this.renderFire(ctx, w, h);
        break;
      case 'thunder':
        this.renderThunder(ctx, w, h);
        break;
      case 'neon':
        this.renderNeon(ctx, w, h);
        break;
      case 'manolo':
        this.renderManolo(ctx, w, h);
        break;
      case 'glass':
        this.renderGlass(ctx, w, h);
        break;
      case 'dark':
        this.renderDark(ctx, w, h);
        break;
      case 'light':
        this.renderLight(ctx, w, h);
        break;
    }
  }

  renderFire(ctx, w, h) {
    // Warm volcanic glow from bottom
    const pulse = 0.18 + Math.sin(Date.now() * 0.005) * 0.06;
    const grad = ctx.createLinearGradient(0, h, 0, h - 90);
    grad.addColorStop(0, `rgba(255, 60, 0, ${pulse})`);
    grad.addColorStop(0.5, `rgba(255, 140, 0, ${pulse * 0.4})`);
    grad.addColorStop(1, 'rgba(0, 0, 0, 0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, h - 90, w, 90);

    // Rising embers
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx + Math.sin(Date.now() * 0.003 + p.y) * 0.5;
      p.y += p.vy;
      p.alpha -= p.decay;

      if (p.alpha <= 0 || p.y < -10) {
        p.x = Math.random() * w;
        p.y = h - Math.random() * 20;
        p.vx = (Math.random() - 0.5) * 1.2;
        p.vy = -(Math.random() * 1.8 + 0.8);
        p.alpha = Math.random() * 0.9 + 0.2;
      }

      ctx.save();
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fillStyle = `hsla(${p.hue}, 100%, 60%, ${p.alpha})`;
      ctx.shadowColor = `hsla(${p.hue}, 100%, 50%, 0.8)`;
      ctx.shadowBlur = p.size * 3;
      ctx.fill();
      ctx.restore();
    }
  }

  renderThunder(ctx, w, h) {
    const now = Date.now();

    // Check for periodic lightning
    if (now > this.nextLightningTime) {
      this.lightningIntensity = 1.0;
      this.lightningBranches = this.generateLightningBolt(w, h);
      this.nextLightningTime = now + 2800 + Math.random() * 2500;
    }

    // Lightning Flash Ambient
    if (this.lightningIntensity > 0.02) {
      ctx.fillStyle = `rgba(180, 220, 255, ${this.lightningIntensity * 0.35})`;
      ctx.fillRect(0, 0, w, h);

      // Render lightning branches
      ctx.save();
      ctx.strokeStyle = `rgba(255, 255, 255, ${this.lightningIntensity})`;
      ctx.shadowColor = 'rgba(100, 200, 255, 0.9)';
      ctx.shadowBlur = 15;
      ctx.lineWidth = 2.2;
      ctx.beginPath();
      for (const seg of this.lightningBranches) {
        ctx.moveTo(seg.x1, seg.y1);
        ctx.lineTo(seg.x2, seg.y2);
      }
      ctx.stroke();
      ctx.restore();

      this.lightningIntensity *= 0.86; // Flash decay
    }

    // Slanted Falling Rain Streaks
    ctx.strokeStyle = 'rgba(130, 190, 255, 0.45)';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    for (const p of this.particles) {
      p.x += p.vx;
      p.y += p.vy;

      if (p.y > h) {
        p.x = Math.random() * (w + 100);
        p.y = -20;
      }

      ctx.moveTo(p.x, p.y);
      ctx.lineTo(p.x + p.vx * 1.5, p.y + p.length);
    }
    ctx.stroke();
  }

  renderNeon(ctx, w, h) {
    // Horizontal Laser Scanning Beam
    this.sweepProgress = (this.sweepProgress + 0.0035) % 1;
    const beamY = this.sweepProgress * h;

    const grad = ctx.createLinearGradient(0, beamY - 14, 0, beamY + 14);
    grad.addColorStop(0, 'rgba(0, 240, 255, 0)');
    grad.addColorStop(0.5, 'rgba(0, 240, 255, 0.28)');
    grad.addColorStop(1, 'rgba(0, 240, 255, 0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, beamY - 14, w, 28);

    // Neon Cyber Motes
    for (const p of this.particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0) p.x = w;
      if (p.x > w) p.x = 0;
      if (p.y < 0) p.y = h;
      if (p.y > h) p.y = 0;

      ctx.save();
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fillStyle = `${p.color} ${p.alpha})`;
      ctx.shadowColor = '#00f0ff';
      ctx.shadowBlur = 8;
      ctx.fill();
      ctx.restore();
    }
  }

  renderManolo(ctx, w, h) {
    // Expanding Golden Shockwaves
    if (this.shockwaves.length === 0 || this.shockwaves[this.shockwaves.length - 1].r > 90) {
      this.shockwaves.push({ x: w / 2, y: h / 2, r: 0, alpha: 0.85 });
    }

    ctx.save();
    for (let i = this.shockwaves.length - 1; i >= 0; i--) {
      const sw = this.shockwaves[i];
      sw.r += 2.2;
      sw.alpha -= 0.009;

      if (sw.alpha <= 0) {
        this.shockwaves.splice(i, 1);
        continue;
      }

      ctx.beginPath();
      ctx.ellipse(sw.x, sw.y, sw.r * 1.8, sw.r, 0, 0, Math.PI * 2);
      ctx.strokeStyle = `rgba(255, 215, 0, ${sw.alpha})`;
      ctx.lineWidth = 1.8;
      ctx.shadowColor = 'rgba(255, 200, 0, 0.7)';
      ctx.shadowBlur = 12;
      ctx.stroke();
    }
    ctx.restore();

    // Gold Luxury Stardust
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.spin += 0.04;
      p.alpha -= p.decay;

      if (p.alpha <= 0 || p.y < -10) {
        p.x = Math.random() * w;
        p.y = h + 10;
        p.alpha = Math.random() * 0.8 + 0.3;
      }

      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.spin);
      ctx.beginPath();
      // 4-point golden starlet
      ctx.moveTo(0, -p.size * 2);
      ctx.lineTo(p.size * 0.5, -p.size * 0.5);
      ctx.lineTo(p.size * 2, 0);
      ctx.lineTo(p.size * 0.5, p.size * 0.5);
      ctx.lineTo(0, p.size * 2);
      ctx.lineTo(-p.size * 0.5, p.size * 0.5);
      ctx.lineTo(-p.size * 2, 0);
      ctx.lineTo(-p.size * 0.5, -p.size * 0.5);
      ctx.closePath();
      ctx.fillStyle = `rgba(255, 220, 80, ${p.alpha})`;
      ctx.shadowColor = 'rgba(255, 215, 0, 0.8)';
      ctx.shadowBlur = 6;
      ctx.fill();
      ctx.restore();
    }
  }

  renderGlass(ctx, w, h) {
    // Diagonal Specular Reflection Sweep
    this.sweepProgress = (this.sweepProgress + 0.0022) % 1;
    const sweepX = this.sweepProgress * (w + 400) - 200;

    const grad = ctx.createLinearGradient(sweepX - 80, 0, sweepX + 80, h);
    grad.addColorStop(0, 'rgba(255, 255, 255, 0)');
    grad.addColorStop(0.5, 'rgba(255, 255, 255, 0.12)');
    grad.addColorStop(1, 'rgba(255, 255, 255, 0)');

    ctx.save();
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.moveTo(sweepX - 80, 0);
    ctx.lineTo(sweepX + 60, 0);
    ctx.lineTo(sweepX - 20, h);
    ctx.lineTo(sweepX - 160, h);
    ctx.closePath();
    ctx.fill();
    ctx.restore();

    // Floating Frosted Glass Bokeh Circles
    for (const p of this.particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < -20) p.x = w + 20;
      if (p.x > w + 20) p.x = -20;
      if (p.y < -20) p.y = h + 20;

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(255, 255, 255, ${p.alpha})`;
      ctx.fill();
    }
  }

  renderDark(ctx, w, h) {
    // Subtle Deep Obsidian Breathing Vignette
    const breath = 0.15 + Math.sin(Date.now() * 0.002) * 0.05;
    const radGrad = ctx.createRadialGradient(w / 2, h / 2, 40, w / 2, h / 2, w * 0.6);
    radGrad.addColorStop(0, 'rgba(80, 90, 140, 0)');
    radGrad.addColorStop(1, `rgba(5, 7, 15, ${breath})`);
    ctx.fillStyle = radGrad;
    ctx.fillRect(0, 0, w, h);
  }

  renderLight(ctx, w, h) {
    // Pure Daylight Glint
    this.sweepProgress = (this.sweepProgress + 0.002) % 1;
    const sweepX = this.sweepProgress * w;
    const grad = ctx.createRadialGradient(sweepX, h * 0.2, 5, sweepX, h * 0.2, 120);
    grad.addColorStop(0, 'rgba(255, 255, 255, 0.15)');
    grad.addColorStop(1, 'rgba(255, 255, 255, 0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. Audio Engine: Real Files + Web Audio Fallback
// ═══════════════════════════════════════════════════════════════════════════

class MechanicalSoundEngine {
  constructor() {
    this.currentProfile = 'thocky';
    this.audioPool = {};
    this.audioCtx = null;
    this.unlocked = false;

    this.preloadAudioFiles();
    this.setupUnlockGestures();
  }

  preloadAudioFiles() {
    // Preload audio elements for each profile
    for (const [profile, urls] of Object.entries(SOUND_ASSETS)) {
      this.audioPool[profile] = urls.map(url => {
        const a = new Audio();
        a.src = url;
        a.preload = 'auto';
        return a;
      });
    }
  }

  setupUnlockGestures() {
    const unlock = () => {
      if (this.unlocked) return;
      this.unlocked = true;
      this.getAudioContext();
      // Pre-warm audio elements
      try {
        if (this.audioPool.clicky && this.audioPool.clicky[0]) {
          const warm = this.audioPool.clicky[0].cloneNode(true);
          warm.volume = 0.01;
          warm.play().then(() => warm.pause()).catch(() => {});
        }
      } catch (_) {}
    };

    ['click', 'pointerdown', 'touchstart', 'keydown'].forEach(evt => {
      window.addEventListener(evt, unlock, { once: true, passive: true });
    });
  }

  getAudioContext() {
    if (!this.audioCtx) {
      const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
      if (AudioCtxClass) {
        this.audioCtx = new AudioCtxClass();
      }
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
    return this.audioCtx;
  }

  playKey(keyName = 'CHAR', profile = this.currentProfile) {
    const pool = this.audioPool[profile];
    if (pool && pool.length > 0) {
      let chosenAudio;
      if (keyName === 'SPACE') {
        chosenAudio = pool[pool.length - 1]; // Dedicated space or last sound
      } else {
        const randIndex = Math.floor(Math.random() * (pool.length - 1));
        chosenAudio = pool[randIndex] || pool[0];
      }

      if (chosenAudio && chosenAudio.src) {
        try {
          const inst = chosenAudio.cloneNode(true);
          inst.volume = 0.85;
          inst.play().catch(() => {
            this.playSynthesizedFallback(profile);
          });
          return;
        } catch (_) {}
      }
    }

    // Fallback if audio files unavailable
    this.playSynthesizedFallback(profile);
  }

  playSynthesizedFallback(profile) {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;
      const now = ctx.currentTime;

      switch (profile) {
        case 'thocky':
          this.synthThock(ctx, now);
          break;
        case 'clicky':
          this.synthClicky(ctx, now);
          break;
        case 'tactile':
          this.synthTactile(ctx, now);
          break;
        case 'futuristic':
          this.synthFuturistic(ctx, now);
          break;
        default:
          this.synthClicky(ctx, now);
      }
    } catch (e) {
      console.warn('Audio fallback note:', e);
    }
  }

  synthThock(ctx, now) {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const filter = ctx.createBiquadFilter();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(155, now);
    osc.frequency.exponentialRampToValueAtTime(50, now + 0.05);

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(360, now);
    filter.frequency.exponentialRampToValueAtTime(90, now + 0.06);

    gain.gain.setValueAtTime(0.7, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.075);
    this.synthNoise(ctx, now, 0.04, 300, 0.35);
  }

  synthClicky(ctx, now) {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'square';
    osc.frequency.setValueAtTime(2600, now);
    osc.frequency.exponentialRampToValueAtTime(1600, now + 0.015);

    gain.gain.setValueAtTime(0.45, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.02);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.022);
    this.synthNoise(ctx, now, 0.02, 2200, 0.3);
  }

  synthTactile(ctx, now) {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const filter = ctx.createBiquadFilter();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(210, now);
    osc.frequency.exponentialRampToValueAtTime(80, now + 0.04);

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(550, now);

    gain.gain.setValueAtTime(0.5, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.045);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.05);
    this.synthNoise(ctx, now, 0.03, 650, 0.25);
  }

  synthFuturistic(ctx, now) {
    const osc1 = ctx.createOscillator();
    const osc2 = ctx.createOscillator();
    const gain = ctx.createGain();

    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(840, now);
    osc1.frequency.exponentialRampToValueAtTime(420, now + 0.04);

    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(1260, now);
    osc2.frequency.exponentialRampToValueAtTime(630, now + 0.04);

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(ctx.destination);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.05);
    osc2.stop(now + 0.05);
  }

  synthNoise(ctx, now, duration, cutoff, volume) {
    // Crucial: Web Audio requires integer frame counts
    const bufferSize = Math.floor(ctx.sampleRate * duration);
    if (bufferSize <= 0) return;

    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const noise = ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(cutoff, now);

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(volume, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    noise.start(now);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. Page Initialization & Controller
// ═══════════════════════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
  const soundEngine = new MechanicalSoundEngine();
  const animator = new ThemeCanvasAnimator('theme-animation-canvas');

  initThemeSwitcher(soundEngine, animator);
  initSoundBoard(soundEngine, animator);
  initPhysicalTypingListener(soundEngine);
  initUIButtonClicks(soundEngine);
});

function initThemeSwitcher(soundEngine, animator) {
  const tabs = document.querySelectorAll('.theme-tab');
  const previewImg = document.getElementById('hero-preview-img');
  const captionText = document.getElementById('preview-caption-text');
  const previewWrapper = document.querySelector('.hero-preview-wrapper');

  if (!previewImg || tabs.length === 0) return;

  const themeKeys = Object.keys(THEMES);
  let currentIndex = 0;
  let autoCycleTimer = null;
  let isHovered = false;

  function switchTheme(themeKey, isManual = false) {
    if (!THEMES[themeKey]) return;

    tabs.forEach(t => t.classList.toggle('active', t.dataset.theme === themeKey));
    animator.setTheme(themeKey);

    previewImg.style.opacity = '0.2';
    previewImg.style.transform = 'scale(0.99)';

    setTimeout(() => {
      previewImg.src = THEMES[themeKey].image;
      if (captionText) {
        captionText.textContent = `${THEMES[themeKey].name} Theme — ${THEMES[themeKey].desc}`;
      }
      previewImg.style.opacity = '1';
      previewImg.style.transform = 'scale(1)';
    }, 120);

    currentIndex = themeKeys.indexOf(themeKey);
    if (isManual) {
      soundEngine.playKey('CLICK');
    }
  }

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      switchTheme(tab.dataset.theme, true);
    });
  });

  // Canvas click trigger particle spark
  if (animator.canvas) {
    animator.canvas.addEventListener('pointerdown', (e) => {
      const rect = animator.canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      animator.triggerSpark(x, y);
      soundEngine.playKey('CLICK');
    });
  }

  // Auto-cycle carousel every 4.8 seconds
  function startAutoCycle() {
    stopAutoCycle();
    autoCycleTimer = setInterval(() => {
      if (!isHovered) {
        currentIndex = (currentIndex + 1) % themeKeys.length;
        switchTheme(themeKeys[currentIndex], false);
      }
    }, 4800);
  }

  function stopAutoCycle() {
    if (autoCycleTimer) clearInterval(autoCycleTimer);
  }

  if (previewWrapper) {
    previewWrapper.addEventListener('mouseenter', () => { isHovered = true; });
    previewWrapper.addEventListener('mouseleave', () => { isHovered = false; });
  }

  startAutoCycle();
}

function initSoundBoard(soundEngine, animator) {
  // Sound profile chips
  const chips = document.querySelectorAll('.profile-chip');
  chips.forEach(chip => {
    chip.addEventListener('click', () => {
      chips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      soundEngine.currentProfile = chip.dataset.profile;
      soundEngine.playKey('CLICK');
    });
  });

  // Interactive keyboard key caps
  const keys = document.querySelectorAll('.key-cap');
  keys.forEach(key => {
    const trigger = (e) => {
      if (e) e.preventDefault();
      key.classList.add('pressed');
      const keyName = key.dataset.key || 'CHAR';
      soundEngine.playKey(keyName);

      if (animator && animator.canvas) {
        const rect = animator.canvas.getBoundingClientRect();
        animator.triggerSpark(rect.width / 2 + (Math.random() - 0.5) * 120, rect.height * 0.7);
      }

      setTimeout(() => key.classList.remove('pressed'), 110);
    };

    key.addEventListener('mousedown', trigger);
    key.addEventListener('touchstart', trigger, { passive: false });
  });
}

function initPhysicalTypingListener(soundEngine) {
  window.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;

    const char = e.key.toUpperCase();
    const keyEl = (char === ' ')
      ? document.querySelector('.key-cap[data-key="SPACE"]')
      : (document.querySelector(`.key-cap[data-key="${char}"]`) || document.querySelector('.key-cap[data-key="SPACE"]'));

    if (keyEl) {
      keyEl.classList.add('pressed');
      setTimeout(() => keyEl.classList.remove('pressed'), 110);
    }

    soundEngine.playKey(char === ' ' ? 'SPACE' : 'CHAR');
  });
}

function initUIButtonClicks(soundEngine) {
  // Give subtle mechanical tactile feedback to every interactive button on the page
  const selectors = ['.btn', '.layout-tab', '.preview-theme-selector button', '.nav-link', '.faq-item summary'];
  selectors.forEach(sel => {
    document.querySelectorAll(sel).forEach(el => {
      el.addEventListener('click', () => {
        soundEngine.playKey('CLICK');
      });
    });
  });
}
