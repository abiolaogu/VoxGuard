import React, { useState } from 'react';
import {
  Search,
  Plus,
  Edit,
  Trash2,
  Shield,
  User,
  Mail,
  Key,
  Check,
  X,
} from 'lucide-react';
import { useAuthStore, hasRole, UserRole } from '../stores/authStore';
import { cn } from '../utils/cn';

interface UserData {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  status: 'active' | 'inactive';
  lastLogin: string;
  createdAt: string;
}

const ROLE_COLORS = {
  admin: 'bg-purple-100 text-purple-800',
  analyst: 'bg-blue-100 text-blue-800',
  developer: 'bg-green-100 text-green-800',
  viewer: 'bg-gray-100 text-gray-800',
};

// Demo users data
const demoUsers: UserData[] = [
  {
    id: '1',
    name: 'System Admin',
    email: 'admin@acm.com',
    role: 'admin',
    status: 'active',
    lastLogin: new Date().toISOString(),
    createdAt: '2024-01-15T10:00:00Z',
  },
  {
    id: '2',
    name: 'John Analyst',
    email: 'john.analyst@acm.com',
    role: 'analyst',
    status: 'active',
    lastLogin: new Date(Date.now() - 3600000).toISOString(),
    createdAt: '2024-02-20T14:30:00Z',
  },
  {
    id: '3',
    name: 'Sarah Developer',
    email: 'sarah.dev@acm.com',
    role: 'developer',
    status: 'active',
    lastLogin: new Date(Date.now() - 86400000).toISOString(),
    createdAt: '2024-03-10T09:15:00Z',
  },
  {
    id: '4',
    name: 'Mike Viewer',
    email: 'mike.viewer@acm.com',
    role: 'viewer',
    status: 'active',
    lastLogin: new Date(Date.now() - 172800000).toISOString(),
    createdAt: '2024-04-05T16:45:00Z',
  },
  {
    id: '5',
    name: 'Jane Analyst',
    email: 'jane.analyst@acm.com',
    role: 'analyst',
    status: 'inactive',
    lastLogin: new Date(Date.now() - 604800000).toISOString(),
    createdAt: '2024-01-25T11:20:00Z',
  },
];

export function Users() {
  const currentUser = useAuthStore((state) => state.user);
  const isAdmin = hasRole(currentUser, 'admin');
  const [users, setUsers] = useState<UserData[]>(demoUsers);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingUser, setEditingUser] = useState<UserData | null>(null);

  // Filter users
  const filteredUsers = users.filter((user) => {
    const matchesSearch =
      searchTerm === '' ||
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesRole = roleFilter === 'all' || user.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  // User counts by role
  const roleCounts = {
    admin: users.filter((u) => u.role === 'admin').length,
    analyst: users.filter((u) => u.role === 'analyst').length,
    developer: users.filter((u) => u.role === 'developer').length,
    viewer: users.filter((u) => u.role === 'viewer').length,
  };

  const handleDeleteUser = (userId: string) => {
    if (confirm('Are you sure you want to delete this user?')) {
      setUsers(users.filter((u) => u.id !== userId));
    }
  };

  const handleToggleStatus = (userId: string) => {
    setUsers(
      users.map((u) =>
        u.id === userId
          ? { ...u, status: u.status === 'active' ? 'inactive' : 'active' }
          : u
      )
    );
  };

  if (!isAdmin) {
    return (
      <div className="bg-white rounded-xl shadow-sm p-8 text-center">
        <Shield className="h-12 w-12 mx-auto text-gray-300" />
        <h2 className="mt-4 text-lg font-semibold text-gray-900">Access Denied</h2>
        <p className="mt-2 text-gray-500">
          You don't have permission to manage users. Please contact an administrator.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {Object.entries(roleCounts).map(([role, count]) => (
          <button
            key={role}
            onClick={() => setRoleFilter(role)}
            className={cn(
              'p-4 rounded-lg border-2 text-left transition-all bg-white shadow-sm',
              roleFilter === role ? 'border-blue-500' : 'border-transparent hover:border-gray-300'
            )}
          >
            <p className="text-2xl font-bold text-gray-900">{count}</p>
            <p className="text-sm text-gray-600 capitalize">{role}s</p>
          </button>
        ))}
      </div>

      {/* Filters & Actions */}
      <div className="bg-white rounded-xl shadow-sm p-4">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search users..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Roles</option>
            <option value="admin">Admins</option>
            <option value="analyst">Analysts</option>
            <option value="developer">Developers</option>
            <option value="viewer">Viewers</option>
          </select>

          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="h-4 w-4" />
            Add User
          </button>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Last Login
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredUsers.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                      <span className="text-sm font-medium text-gray-600">
                        {user.name.charAt(0)}
                      </span>
                    </div>
                    <div className="ml-4">
                      <div className="text-sm font-medium text-gray-900">{user.name}</div>
                      <div className="text-sm text-gray-500">{user.email}</div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={cn('px-2 py-1 text-xs font-medium rounded capitalize', ROLE_COLORS[user.role])}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <button
                    onClick={() => handleToggleStatus(user.id)}
                    className={cn(
                      'px-2 py-1 text-xs font-medium rounded flex items-center gap-1',
                      user.status === 'active'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    )}
                  >
                    {user.status === 'active' ? (
                      <Check className="h-3 w-3" />
                    ) : (
                      <X className="h-3 w-3" />
                    )}
                    {user.status}
                  </button>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {new Date(user.lastLogin).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => setEditingUser(user)}
                      className="p-2 text-gray-400 hover:text-blue-600"
                    >
                      <Edit className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => handleDeleteUser(user.id)}
                      disabled={user.id === currentUser?.id}
                      className="p-2 text-gray-400 hover:text-red-600 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredUsers.length === 0 && (
          <div className="p-8 text-center">
            <User className="h-12 w-12 mx-auto text-gray-300" />
            <p className="mt-2 text-gray-500">No users found</p>
          </div>
        )}
      </div>

      {/* Add/Edit User Modal */}
      {(showAddModal || editingUser) && (
        <UserModal
          user={editingUser}
          onClose={() => {
            setShowAddModal(false);
            setEditingUser(null);
          }}
          onSave={(userData) => {
            if (editingUser) {
              setUsers(users.map((u) => (u.id === editingUser.id ? { ...u, ...userData } : u)));
            } else {
              setUsers([
                ...users,
                {
                  ...userData,
                  id: String(users.length + 1),
                  status: 'active',
                  lastLogin: new Date().toISOString(),
                  createdAt: new Date().toISOString(),
                } as UserData,
              ]);
            }
            setShowAddModal(false);
            setEditingUser(null);
          }}
        />
      )}
    </div>
  );
}

interface UserModalProps {
  user: UserData | null;
  onClose: () => void;
  onSave: (data: Partial<UserData>) => void;
}

function UserModal({ user, onClose, onSave }: UserModalProps) {
  const [formData, setFormData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    role: user?.role || 'analyst',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          {user ? 'Edit User' : 'Add New User'}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                required
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
            <div className="relative">
              <Key className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
              <select
                value={formData.role}
                onChange={(e) => setFormData({ ...formData, role: e.target.value as UserRole })}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 appearance-none"
              >
                <option value="admin">Admin</option>
                <option value="analyst">Analyst</option>
                <option value="developer">Developer</option>
                <option value="viewer">Viewer</option>
              </select>
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              {user ? 'Save Changes' : 'Add User'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
