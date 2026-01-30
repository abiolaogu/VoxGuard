import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

// Import Ant Design reset styles (replaces index.css for base styles)
import '@refinedev/antd/dist/reset.css';

// Import custom global styles
import './styles/global.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
