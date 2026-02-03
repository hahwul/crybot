class CrybotWeb {
  constructor() {
    this.ws = null;
    this.sessionId = null;
    this.socketId = null;
    this.reconnectDelay = 1000;
    this.maxReconnectDelay = 30000;
    this.connect();
    this.setupEventListeners();
  }

  connect() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws/chat`;

    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('Connected to Crybot');
        this.updateConnectionStatus('connected');
        this.reconnectDelay = 1000;
      };

      this.ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          this.handleMessage(data);
        } catch (e) {
          console.error('Failed to parse message:', e);
        }
      };

      this.ws.onclose = () => {
        console.log('Disconnected from Crybot');
        this.updateConnectionStatus('disconnected');
        this.scheduleReconnect();
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        this.updateConnectionStatus('error');
      };
    } catch (e) {
      console.error('Failed to connect:', e);
      this.scheduleReconnect();
    }
  }

  scheduleReconnect() {
    setTimeout(() => {
      console.log(`Reconnecting in ${this.reconnectDelay}ms...`);
      this.connect();
      this.reconnectDelay = Math.min(this.reconnectDelay * 2, this.maxReconnectDelay);
    }, this.reconnectDelay);
  }

  updateConnectionStatus(status) {
    const statusEl = document.getElementById('connection-status');
    const span = statusEl.querySelector('span');

    statusEl.className = 'connection-status';
    span.className = '';

    switch (status) {
      case 'connected':
        statusEl.classList.add('connected');
        span.classList.add('connected');
        span.textContent = 'Connected';
        break;
      case 'disconnected':
        statusEl.classList.add('disconnected');
        span.classList.add('disconnected');
        span.textContent = 'Disconnected - Reconnecting...';
        break;
      case 'error':
        statusEl.classList.add('error');
        span.classList.add('error');
        span.textContent = 'Connection Error';
        break;
      default:
        statusEl.classList.add('connecting');
        span.classList.add('connecting');
        span.textContent = 'Connecting...';
    }
  }

  handleMessage(data) {
    switch (data.type) {
      case 'connected':
        this.sessionId = data.session_id;
        this.socketId = data.socket_id;
        console.log('Session initialized:', this.sessionId);
        break;
      case 'response':
        this.addMessage(data.content, 'assistant');
        this.setTyping(false);
        break;
      case 'status':
        if (data.status === 'processing') {
          this.setTyping(true);
        }
        break;
      case 'history':
        this.displayHistory(data.messages);
        break;
      case 'session_switched':
        this.sessionId = data.session_id;
        this.addMessage(`Switched to session: ${data.session_id}`, 'system');
        break;
      case 'error':
        this.addMessage(`Error: ${data.message}`, 'system');
        this.setTyping(false);
        break;
      default:
        console.log('Unknown message type:', data.type);
    }
  }

  sendMessage(content) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      this.addMessage('Not connected to server', 'system');
      return;
    }

    this.addMessage(content, 'user');

    this.ws.send(JSON.stringify({
      type: 'message',
      session_id: this.sessionId,
      content: content,
    }));
  }

  requestHistory() {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      return;
    }

    this.ws.send(JSON.stringify({
      type: 'history_request',
      session_id: this.sessionId,
    }));
  }

  switchSession(sessionId) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      return;
    }

    this.ws.send(JSON.stringify({
      type: 'session_switch',
      session_id: sessionId || null,
    }));
  }

  addMessage(content, role) {
    const messagesDiv = document.getElementById('messages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${role}`;

    // Handle multiline content
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    contentDiv.textContent = content;
    messageDiv.appendChild(contentDiv);

    const timeDiv = document.createElement('div');
    timeDiv.className = 'message-time';
    timeDiv.textContent = new Date().toLocaleTimeString();
    messageDiv.appendChild(timeDiv);

    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  }

  displayHistory(messages) {
    const messagesDiv = document.getElementById('messages');
    messagesDiv.innerHTML = '';

    for (const msg of messages) {
      this.addMessage(msg.content, msg.role);
    }
  }

  setTyping(typing) {
    let indicator = document.getElementById('typing-indicator');

    if (typing) {
      if (!indicator) {
        indicator = document.createElement('div');
        indicator.id = 'typing-indicator';
        indicator.className = 'message assistant typing';
        indicator.innerHTML = '<span class="message-content">Thinking...</span>';
        document.getElementById('messages').appendChild(indicator);
      }
      const messagesDiv = document.getElementById('messages');
      messagesDiv.scrollTop = messagesDiv.scrollHeight;
    } else {
      if (indicator) {
        indicator.remove();
      }
    }
  }

  setupEventListeners() {
    const chatForm = document.getElementById('chat-form');
    const userInput = document.getElementById('user-input');

    chatForm.addEventListener('submit', (e) => {
      e.preventDefault();
      if (userInput.value.trim()) {
        this.sendMessage(userInput.value.trim());
        userInput.value = '';
      }
    });

    // Handle Enter key (without Shift)
    userInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        chatForm.dispatchEvent(new Event('submit'));
      }
    });

    // Config form
    const configForm = document.getElementById('config-form');
    if (configForm) {
      configForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await this.saveConfig();
      });
    }
  }

  async loadSessions() {
    try {
      const response = await fetch('/api/sessions');
      const data = await response.json();
      this.displaySessions(data.sessions);
    } catch (e) {
      console.error('Failed to load sessions:', e);
    }
  }

  displaySessions(sessions) {
    const listDiv = document.getElementById('sessions-list');
    listDiv.innerHTML = '';

    if (!sessions || sessions.length === 0) {
      listDiv.innerHTML = '<p>No sessions found.</p>';
      return;
    }

    const table = document.createElement('table');
    table.role = 'table';

    const thead = document.createElement('thead');
    thead.innerHTML = '<tr><th>Session ID</th><th>Actions</th></tr>';
    table.appendChild(thead);

    const tbody = document.createElement('tbody');

    for (const sessionId of sessions) {
      const tr = document.createElement('tr');

      const tdId = document.createElement('td');
      tdId.textContent = sessionId;
      tr.appendChild(tdId);

      const tdActions = document.createElement('td');

      const loadBtn = document.createElement('button');
      loadBtn.textContent = 'Load';
      loadBtn.onclick = () => {
        this.switchSession(sessionId);
        showChat();
      };
      tdActions.appendChild(loadBtn);

      const deleteBtn = document.createElement('button');
      deleteBtn.textContent = 'Delete';
      deleteBtn.className = 'secondary';
      deleteBtn.onclick = async () => {
        if (confirm(`Delete session ${sessionId}?`)) {
          await this.deleteSession(sessionId);
          this.loadSessions();
        }
      };
      tdActions.appendChild(deleteBtn);

      tr.appendChild(tdActions);
      tbody.appendChild(tr);
    }

    table.appendChild(tbody);
    listDiv.appendChild(table);
  }

  async deleteSession(sessionId) {
    try {
      await fetch(`/api/sessions/${encodeURIComponent(sessionId)}`, {
        method: 'DELETE',
      });
    } catch (e) {
      console.error('Failed to delete session:', e);
    }
  }

  async loadConfig() {
    try {
      const response = await fetch('/api/config');
      const config = await response.json();

      document.getElementById('web-enabled').checked = config.web?.enabled || false;
      document.getElementById('web-host').value = config.web?.host || '127.0.0.1';
      document.getElementById('web-port').value = config.web?.port || 3000;
      document.getElementById('web-auth-token').value = config.web?.auth_token || '';
      document.getElementById('agent-model').value = config.agents?.defaults?.model || 'glm-4.7-flash';
      document.getElementById('agent-temperature').value = config.agents?.defaults?.temperature || 0.7;
    } catch (e) {
      console.error('Failed to load config:', e);
    }
  }

  async saveConfig() {
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
        },
      },
    };

    try {
      const response = await fetch('/api/config', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      });

      if (response.ok) {
        this.showConfigStatus('Configuration saved successfully. Changes may require restarting the server.', 'success');
      } else {
        const error = await response.json();
        this.showConfigStatus(`Failed to save: ${error.error || 'Unknown error'}`, 'error');
      }
    } catch (e) {
      console.error('Failed to save config:', e);
      this.showConfigStatus('Failed to save configuration', 'error');
    }
  }

  showConfigStatus(message, type) {
    const statusEl = document.getElementById('config-status');
    statusEl.textContent = message;
    statusEl.className = `status-msg ${type}`;
    statusEl.hidden = false;

    setTimeout(() => {
      statusEl.hidden = true;
    }, 5000);
  }
}

// Global instance
let app = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  app = new CrybotWeb();
});

// View switching functions
function showChat() {
  document.getElementById('chat-view').hidden = false;
  document.getElementById('sessions-view').hidden = true;
  document.getElementById('config-view').hidden = true;
}

function showSessions() {
  document.getElementById('chat-view').hidden = true;
  document.getElementById('sessions-view').hidden = false;
  document.getElementById('config-view').hidden = true;
  if (app) app.loadSessions();
}

function showConfig() {
  document.getElementById('chat-view').hidden = true;
  document.getElementById('sessions-view').hidden = true;
  document.getElementById('config-view').hidden = false;
  if (app) app.loadConfig();
}

function refreshSessions() {
  if (app) app.loadSessions();
}
