import { useState, ReactNode } from 'react';
import {
  Shield,
  Bell,
  Server,
  Key,
  Save,
  AlertTriangle,
  Mail,
  Smartphone,
  Webhook,
} from 'lucide-react';
import { useAuthStore, hasRole } from '../stores/authStore';
import { cn } from '../utils/cn';

interface SettingSection {
  id: string;
  title: string;
  icon: ReactNode;
  adminOnly?: boolean;
}

const sections: SettingSection[] = [
  { id: 'detection', title: 'Detection Settings', icon: <Shield className="h-5 w-5" /> },
  { id: 'alerts', title: 'Alert Configuration', icon: <Bell className="h-5 w-5" /> },
  { id: 'notifications', title: 'Notifications', icon: <Mail className="h-5 w-5" /> },
  { id: 'api', title: 'API Settings', icon: <Key className="h-5 w-5" />, adminOnly: true },
  { id: 'system', title: 'System', icon: <Server className="h-5 w-5" />, adminOnly: true },
];

export function Settings() {
  const user = useAuthStore((state) => state.user);
  const isAdmin = hasRole(user, 'admin');
  const [activeSection, setActiveSection] = useState('detection');
  const [saved, setSaved] = useState(false);

  // Detection settings
  const [detectionSettings, setDetectionSettings] = useState({
    windowSeconds: 5,
    threshold: 5,
    autoBlock: true,
    autoDisconnect: false,
  });

  // Alert settings
  const [alertSettings, setAlertSettings] = useState({
    criticalEnabled: true,
    highEnabled: true,
    mediumEnabled: true,
    lowEnabled: false,
    autoEscalate: true,
    escalateAfterMinutes: 15,
  });

  // Notification settings
  const [notificationSettings, setNotificationSettings] = useState({
    emailEnabled: true,
    emailAddress: user?.email || '',
    smsEnabled: false,
    smsNumber: '',
    webhookEnabled: false,
    webhookUrl: '',
  });

  const handleSave = () => {
    // In production, this would call the API
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  const filteredSections = sections.filter(
    (section) => !section.adminOnly || isAdmin
  );

  return (
    <div className="flex gap-6">
      {/* Sidebar */}
      <div className="w-64 flex-shrink-0">
        <div className="bg-white rounded-xl shadow-sm p-4">
          <nav className="space-y-1">
            {filteredSections.map((section) => (
              <button
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                className={cn(
                  'w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left transition-colors',
                  activeSection === section.id
                    ? 'bg-blue-50 text-blue-700'
                    : 'text-gray-600 hover:bg-gray-50'
                )}
              >
                {section.icon}
                <span className="font-medium">{section.title}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1">
        <div className="bg-white rounded-xl shadow-sm p-6">
          {/* Detection Settings */}
          {activeSection === 'detection' && (
            <div className="space-y-6">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Detection Settings</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Configure the anti-call masking detection parameters
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Detection Window (seconds)
                  </label>
                  <input
                    type="number"
                    value={detectionSettings.windowSeconds}
                    onChange={(e) =>
                      setDetectionSettings({
                        ...detectionSettings,
                        windowSeconds: parseInt(e.target.value),
                      })
                    }
                    min={1}
                    max={60}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    Time window for detecting multiple A-numbers (1-60 seconds)
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    A-Number Threshold
                  </label>
                  <input
                    type="number"
                    value={detectionSettings.threshold}
                    onChange={(e) =>
                      setDetectionSettings({
                        ...detectionSettings,
                        threshold: parseInt(e.target.value),
                      })
                    }
                    min={2}
                    max={20}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    Minimum distinct A-numbers to trigger alert (2-20)
                  </p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Auto-Block Suspicious Numbers</p>
                    <p className="text-sm text-gray-500">
                      Automatically block A-numbers involved in detected attacks
                    </p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={detectionSettings.autoBlock}
                      onChange={(e) =>
                        setDetectionSettings({
                          ...detectionSettings,
                          autoBlock: e.target.checked,
                        })
                      }
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>

                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Auto-Disconnect Calls</p>
                    <p className="text-sm text-gray-500">
                      Automatically disconnect calls involved in active attacks
                    </p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={detectionSettings.autoDisconnect}
                      onChange={(e) =>
                        setDetectionSettings({
                          ...detectionSettings,
                          autoDisconnect: e.target.checked,
                        })
                      }
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
              </div>
            </div>
          )}

          {/* Alert Settings */}
          {activeSection === 'alerts' && (
            <div className="space-y-6">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Alert Configuration</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Configure which alerts to receive and escalation rules
                </p>
              </div>

              <div className="space-y-4">
                <h3 className="font-medium text-gray-900">Alert Severity Levels</h3>

                {[
                  { key: 'criticalEnabled', label: 'Critical', color: 'red' },
                  { key: 'highEnabled', label: 'High', color: 'orange' },
                  { key: 'mediumEnabled', label: 'Medium', color: 'yellow' },
                  { key: 'lowEnabled', label: 'Low', color: 'green' },
                ].map((level) => (
                  <div key={level.key} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div className="flex items-center gap-3">
                      <div className={`w-3 h-3 rounded-full bg-${level.color}-500`} />
                      <p className="font-medium text-gray-900">{level.label} Alerts</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={alertSettings[level.key as keyof typeof alertSettings] as boolean}
                        onChange={(e) =>
                          setAlertSettings({
                            ...alertSettings,
                            [level.key]: e.target.checked,
                          })
                        }
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>
                ))}
              </div>

              <div className="pt-4 border-t">
                <h3 className="font-medium text-gray-900 mb-4">Escalation Rules</h3>

                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg mb-4">
                  <div>
                    <p className="font-medium text-gray-900">Auto-Escalate Unhandled Alerts</p>
                    <p className="text-sm text-gray-500">
                      Escalate alerts that haven't been addressed
                    </p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={alertSettings.autoEscalate}
                      onChange={(e) =>
                        setAlertSettings({
                          ...alertSettings,
                          autoEscalate: e.target.checked,
                        })
                      }
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>

                {alertSettings.autoEscalate && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Escalate after (minutes)
                    </label>
                    <input
                      type="number"
                      value={alertSettings.escalateAfterMinutes}
                      onChange={(e) =>
                        setAlertSettings({
                          ...alertSettings,
                          escalateAfterMinutes: parseInt(e.target.value),
                        })
                      }
                      min={5}
                      max={120}
                      className="w-32 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Notification Settings */}
          {activeSection === 'notifications' && (
            <div className="space-y-6">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Notification Settings</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Configure how you receive alert notifications
                </p>
              </div>

              {/* Email */}
              <div className="p-4 bg-gray-50 rounded-lg space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Mail className="h-5 w-5 text-gray-500" />
                    <p className="font-medium text-gray-900">Email Notifications</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notificationSettings.emailEnabled}
                      onChange={(e) =>
                        setNotificationSettings({
                          ...notificationSettings,
                          emailEnabled: e.target.checked,
                        })
                      }
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
                {notificationSettings.emailEnabled && (
                  <input
                    type="email"
                    value={notificationSettings.emailAddress}
                    onChange={(e) =>
                      setNotificationSettings({
                        ...notificationSettings,
                        emailAddress: e.target.value,
                      })
                    }
                    placeholder="email@example.com"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                )}
              </div>

              {/* SMS */}
              <div className="p-4 bg-gray-50 rounded-lg space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Smartphone className="h-5 w-5 text-gray-500" />
                    <p className="font-medium text-gray-900">SMS Notifications</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notificationSettings.smsEnabled}
                      onChange={(e) =>
                        setNotificationSettings({
                          ...notificationSettings,
                          smsEnabled: e.target.checked,
                        })
                      }
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
                {notificationSettings.smsEnabled && (
                  <input
                    type="tel"
                    value={notificationSettings.smsNumber}
                    onChange={(e) =>
                      setNotificationSettings({
                        ...notificationSettings,
                        smsNumber: e.target.value,
                      })
                    }
                    placeholder="+1234567890"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                )}
              </div>

              {/* Webhook */}
              <div className="p-4 bg-gray-50 rounded-lg space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Webhook className="h-5 w-5 text-gray-500" />
                    <p className="font-medium text-gray-900">Webhook Integration</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notificationSettings.webhookEnabled}
                      onChange={(e) =>
                        setNotificationSettings({
                          ...notificationSettings,
                          webhookEnabled: e.target.checked,
                        })
                      }
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
                {notificationSettings.webhookEnabled && (
                  <input
                    type="url"
                    value={notificationSettings.webhookUrl}
                    onChange={(e) =>
                      setNotificationSettings({
                        ...notificationSettings,
                        webhookUrl: e.target.value,
                      })
                    }
                    placeholder="https://your-webhook.com/endpoint"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                )}
              </div>
            </div>
          )}

          {/* API Settings (Admin only) */}
          {activeSection === 'api' && isAdmin && (
            <div className="space-y-6">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">API Settings</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Manage API keys and access controls
                </p>
              </div>

              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-medium text-yellow-800">API Key Management</p>
                  <p className="text-sm text-yellow-700 mt-1">
                    API keys provide full access to the detection system. Handle with care.
                  </p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <p className="font-medium text-gray-900">Primary API Key</p>
                    <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">Active</span>
                  </div>
                  <code className="block p-2 bg-gray-200 rounded text-sm font-mono">
                    acm_live_xxxx...xxxx
                  </code>
                </div>

                <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium">
                  Generate New API Key
                </button>
              </div>
            </div>
          )}

          {/* System Settings (Admin only) */}
          {activeSection === 'system' && isAdmin && (
            <div className="space-y-6">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">System Settings</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Configure system-wide settings and integrations
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-500">kdb+ Server</p>
                  <p className="font-medium">kdb:5000</p>
                  <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">Connected</span>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-500">HTTP API</p>
                  <p className="font-medium">kdb:5001</p>
                  <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">Connected</span>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-500">Database</p>
                  <p className="font-medium">YugabyteDB</p>
                  <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">Connected</span>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-500">Cache</p>
                  <p className="font-medium">DragonflyDB</p>
                  <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">Connected</span>
                </div>
              </div>
            </div>
          )}

          {/* Save Button */}
          <div className="mt-8 pt-6 border-t flex items-center justify-between">
            {saved && (
              <span className="text-green-600 flex items-center gap-2">
                <Save className="h-4 w-4" />
                Settings saved successfully
              </span>
            )}
            <button
              onClick={handleSave}
              className="ml-auto px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium flex items-center gap-2"
            >
              <Save className="h-4 w-4" />
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
