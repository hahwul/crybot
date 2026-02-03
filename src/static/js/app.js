class CrybotWeb {
  constructor() {
    this.ws = null;
    this.sessionId = null;
    this.currentSection = 'chat';
    this.currentTab = 'chat-tab';
    this.currentTelegramChat = null;

    this.init();
  }

  init() {
    this.setupNavigation();
    this.setupTabs();
    this.setupForms();
    this.connectWebSocket();
    this.loadConfiguration();
    this.loadLogs();
  }

  setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const section = item.dataset.section;
        this.showSection(section);
      });
    });
  }

  showSection(section) {
    // Update nav items
    document.querySelectorAll('.nav-item').forEach(item => {
      item.classList.remove('active');
      if (item.dataset.section === section) {
        item.classList.add('active');
      }
    });

    // Update sections
    document.querySelectorAll('.section').forEach(sec => {
      sec.classList.remove('active');
    });
    document.getElementById(`section-${section}`).classList.add('active');

    this.currentSection = section;
  }

  setupTabs() {
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        const tabId = tab.dataset.tab;
        this.showTab(tabId);
      });
    });
  }

  showTab(tabId) {
    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => {
      tab.classList.remove('active');
      if (tab.dataset.tab === tabId) {
        tab.classList.add('active');
      }
    });

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
      content.classList.remove('active');
    });
    document.getElementById(tabId).classList.add('active');

    this.currentTab = tabId;

    // Load content based on tab
    if (tabId === 'telegram-tab') {
      this.loadTelegramConversations();
    }
  }

  setupForms() {
    // Chat form
    document.getElementById('chat-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.sendChatMessage('chat');
    });

    // Telegram form
    document.getElementById('telegram-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.sendChatMessage('telegram');
    });

    // Voice form
    document.getElementById('voice-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.sendChatMessage('voice');
    });

    // Config form
    document.getElementById('config-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.saveConfiguration();
    });

    // Telegram back button
    document.getElementById('telegram-back').addEventListener('click', () => {
      this.showTelegramList();
    });
  }

  connectWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws/chat`;

    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = () => {
      console.log('Connected to Crybot');
    };

    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      this.handleWebSocketMessage(data);
    };

    this.ws.onclose = () => {
      console.log('Disconnected from Crybot');
      setTimeout(() => this.connectWebSocket(), 3000);
    };

    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }

  handleWebSocketMessage(data) {
    switch (data.type) {
      case 'connected':
        this.sessionId = data.session_id;
        break;
      case 'response':
        this.addMessage(data.content, 'assistant', this.getCurrentContainer());
        break;
      case 'error':
        this.addMessage(`Error: ${data.message}`, 'system', this.getCurrentContainer());
        break;
    }
  }

  getCurrentContainer() {
    switch (this.currentTab) {
      case 'chat-tab':
        return 'chat-messages';
      case 'telegram-tab':
        return 'telegram-messages';
      case 'voice-tab':
        return 'voice-messages';
      default:
        return 'chat-messages';
    }
  }

  sendChatMessage(context) {
    const formId = context === 'chat' ? 'chat-form' :
                    context === 'telegram' ? 'telegram-form' : 'voice-form';
    const form = document.getElementById(formId);
    const input = form.querySelector('.message-input');
    const content = input.value.trim();

    if (!content) return;

    this.addMessage(content, 'user', this.getCurrentContainer());
    input.value = '';

    // Send via WebSocket
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        type: 'message',
        session_id: this.sessionId || '',
        content: content,
      }));
    } else {
      // Fallback to REST API
      this.sendViaAPI(content);
    }
  }

  async sendViaAPI(content) {
    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: this.sessionId || '',
          content: content,
        }),
      });

      const data = await response.json();
      if (data.content) {
        this.addMessage(data.content, 'assistant', this.getCurrentContainer());
      }
    } catch (error) {
      this.addMessage('Failed to send message', 'system', this.getCurrentContainer());
    }
  }

  addMessage(content, role, containerId) {
    const container = document.getElementById(containerId);
    const messageEl = document.createElement('div');
    messageEl.className = `message ${role}`;

    const avatar = role === 'user' ? 'U' : role === 'assistant' ? 'C' : '!';
    const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    messageEl.innerHTML = `
      <div class="message-avatar">${avatar}</div>
      <div class="message-content">
        <div class="message-bubble">${this.escapeHtml(content)}</div>
        <div class="message-time">${time}</div>
      </div>
    `;

    container.appendChild(messageEl);
    container.scrollTop = container.scrollHeight;
  }

  async loadTelegramConversations() {
    const listContainer = document.getElementById('telegram-list');
    listContainer.innerHTML = '<p style="color: #666;">Loading conversations...</p>';

    try {
      const response = await fetch('/api/telegram/conversations');
      const data = await response.json();

      if (!data.conversations || data.conversations.length === 0) {
        listContainer.innerHTML = '<p style="color: #666;">No conversations found.</p>';
        return;
      }

      listContainer.innerHTML = '';
      data.conversations.forEach(conv => {
        const item = document.createElement('div');
        item.className = 'telegram-conversation-item';
        item.innerHTML = `
          <div class="telegram-conversation-title">${this.escapeHtml(conv.title || 'Unknown')}</div>
          <div class="telegram-conversation-preview">${this.escapeHtml(conv.preview || 'No messages')}</div>
          <div class="telegram-conversation-time">${conv.time || ''}</div>
        `;
        item.addEventListener('click', () => this.openTelegramChat(conv.id));
        listContainer.appendChild(item);
      });
    } catch (error) {
      listContainer.innerHTML = '<p style="color: #e74c3c;">Failed to load conversations.</p>';
    }
  }

  openTelegramChat(chatId) {
    this.currentTelegramChat = chatId;
    document.getElementById('telegram-list').classList.add('hidden');
    document.getElementById('telegram-chat-view').classList.remove('hidden');

    // Load messages for this chat
    const messagesContainer = document.getElementById('telegram-messages');
    messagesContainer.innerHTML = '<p style="color: #666;">Loading messages...</p>';

    // TODO: Load actual messages from API
    setTimeout(() => {
      messagesContainer.innerHTML = '<p style="color: #666;">No messages yet.</p>';
    }, 500);
  }

  showTelegramList() {
    this.currentTelegramChat = null;
    document.getElementById('telegram-list').classList.remove('hidden');
    document.getElementById('telegram-chat-view').classList.add('hidden');
  }

  async loadConfiguration() {
    try {
      const response = await fetch('/api/config');
      const config = await response.json();

      // Web
      document.getElementById('web-enabled').checked = config.web?.enabled || false;
      document.getElementById('web-host').value = config.web?.host || '127.0.0.1';
      document.getElementById('web-port').value = config.web?.port || 3000;
      document.getElementById('web-auth-token').value = '';

      // Agents
      document.getElementById('agent-model').value = config.agents?.defaults?.model || 'glm-4.7-flash';
      document.getElementById('agent-temperature').value = config.agents?.defaults?.temperature || 0.7;
      document.getElementById('agent-max-tokens').value = config.agents?.defaults?.max_tokens || 4096;

      // Providers
      document.getElementById('provider-zhipu-key').value = '';
      document.getElementById('provider-openai-key').value = '';
      document.getElementById('provider-anthropic-key').value = '';

      // Channels - Telegram
      document.getElementById('telegram-enabled').checked = config.channels?.telegram?.enabled || false;
      document.getElementById('telegram-token').value = '';
      document.getElementById('telegram-allow-from').value = (config.channels?.telegram?.allow_from || []).join(', ');
    } catch (error) {
      console.error('Failed to load configuration:', error);
    }
  }

  async saveConfiguration() {
    const config = {
      web: {
        enabled: document.getElementById('web-enabled').checked,
        host: document.getElementById('web-host').value,
        port: parseInt(document.getElementById('web-port').value),
        auth_token: document.getElementById('web-auth-token').value,
      },
      agents: {
        defaults: {
          model: document.getElementById('agent-model').value,
          temperature: parseFloat(document.getElementById('agent-temperature').value),
          max_tokens: parseInt(document.getElementById('agent-max-tokens').value),
        },
      },
      providers: {
        zhipu: { api_key: document.getElementById('provider-zhipu-key').value },
        openai: { api_key: document.getElementById('provider-openai-key').value },
        anthropic: { api_key: document.getElementById('provider-anthropic-key').value },
      },
      channels: {
        telegram: {
          enabled: document.getElementById('telegram-enabled').checked,
          token: document.getElementById('telegram-token').value,
          allow_from: document.getElementById('telegram-allow-from').value.split(',').map(s => s.trim()).filter(s => s),
        },
      },
    };

    try {
      const response = await fetch('/api/config', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config),
      });

      if (response.ok) {
        alert('Configuration saved successfully!');
      } else {
        const error = await response.json();
        alert(`Failed to save: ${error.error || 'Unknown error'}`);
      }
    } catch (error) {
      alert('Failed to save configuration');
    }
  }

  loadLogs() {
    const logsContainer = document.getElementById('logs-container');
    logsContainer.innerHTML = `
      <div class="log-entry">
        <span class="log-time">[${new Date().toISOString()}]</span>
        <span class="log-level-info">[INFO]</span>
        <span class="log-message">Crybot Web UI initialized</span>
      </div>
    `;

    // TODO: Implement real-time log streaming via WebSocket or polling
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  new CrybotWeb();
});
