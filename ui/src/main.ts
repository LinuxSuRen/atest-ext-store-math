import './assets/main.css'
import { createApp } from 'vue';
import App from './App.vue';
import { setupI18n } from './i18n'
import en from './locales/en.json'
import zh from './locales/zh.json'

export interface VuePlugin {
  mount(el?: string | Element, props?: Record<string, any>): void;
  unmount(): void;
}

let app: VueApp | null = null;

export function mount(el?: string | Element, props?: Record<string, any>): void {
  const container = typeof el === 'string' ? document.querySelector(el) : el;
  const language = window.navigator.userLanguage || window.navigator.language;
  const lang = language.split('-')[0]
  const i18n = setupI18n({
    legacy: false,
    locale: lang,
    fallbackLocale: 'en',
    messages: {
      en, zh
    }
  })

  app = createApp(App, props);
  app.use(i18n)
  app.mount(container || '#plugin-container');
}

export function unmount(): void {
  if (app) {
    app.unmount();
    app = null;
  }
}

if (sessionStorage.getItem('mode') === 'dev') {
  mount();
}

if (typeof window !== 'undefined') {
  (window as any).ATestPlugin = { mount, unmount };
}
