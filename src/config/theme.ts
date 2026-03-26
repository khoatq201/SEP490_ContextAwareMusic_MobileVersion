import type { ThemeConfig } from 'antd';

export const antTheme: ThemeConfig = {
  cssVar: { key: '_,:root,css-var-my-theme-id' },
  token: {
    fontFamily: 'Inter',
    borderRadius: 4,
  },
  components: {
    Typography: {
      titleMarginBottom: 0,
    },
    Form: {
      labelColor: 'var(--color-gray)',
    },
    Menu: {
      itemMarginInline: 0,
      itemMarginBlock: 0,
      itemBorderRadius: 0,
      itemHeight: 46,
    },
    Button: {
      fontSizeLG: 14,
    },
    Input: {
      fontSizeLG: 14,
    },
    InputNumber: {
      fontSizeLG: 14,
    },
    Select: {
      fontSizeLG: 14,
    },
    Card: {
      colorBorderSecondary: '#E6EBF1',
    },
    Tabs: {
      horizontalItemGutter: 0,
    },
    DatePicker: {
      fontSizeLG: 14,
    },
    Divider: {
      marginLG: 0,
    },
  },
};
