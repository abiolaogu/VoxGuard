import { Switch, Tooltip } from 'antd';
import { SunOutlined, MoonOutlined } from '@ant-design/icons';
import { useThemeMode } from '../../hooks/useThemeMode';

interface ThemeSwitchProps {
  size?: 'small' | 'default';
}

export const ThemeSwitch: React.FC<ThemeSwitchProps> = ({
  size = 'default',
}) => {
  const { toggleMode, isDark } = useThemeMode();

  return (
    <Tooltip title={isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'}>
      <Switch
        checked={isDark}
        onChange={toggleMode}
        checkedChildren={<MoonOutlined />}
        unCheckedChildren={<SunOutlined />}
        size={size}
      />
    </Tooltip>
  );
};

export default ThemeSwitch;
