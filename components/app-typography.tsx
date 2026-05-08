import React, { forwardRef } from 'react';
import {
  StyleSheet,
  Text as RNText,
  TextInput as RNTextInput,
  type StyleProp,
  type TextInputProps,
  type TextInput as RNTextInputType,
  type TextProps,
  type TextStyle,
} from 'react-native';

export const FontFamilies = {
  black: 'SFProBlack',
  bold: 'SFProBold',
  heavy: 'SFProHeavy',
  light: 'SFProLight',
  medium: 'SFProMedium',
  regular: 'SFProRegular',
  semibold: 'SFProSemibold',
  thin: 'SFProThin',
  ultralight: 'SFProUltralight',
} as const;

function normalizeWeight(weight?: TextStyle['fontWeight']) {
  if (weight == null) return undefined;
  return typeof weight === 'number' ? `${weight}` : weight;
}

export function getSFFontFamily(weight?: TextStyle['fontWeight']) {
  switch (normalizeWeight(weight)) {
    case '100':
    case '200':
      return FontFamilies.ultralight;
    case '300':
      return FontFamilies.light;
    case '500':
      return FontFamilies.medium;
    case '600':
      return FontFamilies.semibold;
    case '700':
    case 'bold':
      return FontFamilies.bold;
    case '800':
      return FontFamilies.heavy;
    case '900':
    case 'black':
      return FontFamilies.black;
    default:
      return FontFamilies.regular;
  }
}

function resolveTypographyStyle(style?: StyleProp<TextStyle>): TextStyle {
  const flattened = StyleSheet.flatten(style) ?? {};
  if (flattened.fontFamily) {
    return flattened;
  }

  const resolved = getSFFontFamily(flattened.fontWeight);
  return {
    ...flattened,
    fontFamily: resolved,
    fontWeight: undefined,
  };
}

export const AppText = forwardRef<RNText, TextProps>(function AppText({ style, ...props }, ref) {
  return <RNText ref={ref} style={resolveTypographyStyle(style)} {...props} />;
});

export const AppTextInput = forwardRef<RNTextInputType, TextInputProps>(function AppTextInput(
  { style, ...props },
  ref
) {
  return <RNTextInput ref={ref} style={resolveTypographyStyle(style)} {...props} />;
});
