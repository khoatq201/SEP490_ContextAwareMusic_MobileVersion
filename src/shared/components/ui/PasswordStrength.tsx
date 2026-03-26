import { useState } from 'react';
import { Flex, Typography, message } from 'antd';
import zxcvbn from 'zxcvbn';

const { Text } = Typography;

type PasswordStrengthProps = {
  password: string;
  onPasswordChange?: (password: string) => void;
  showGenerator?: boolean;
  description?: string;
};

export const PasswordStrength = ({
  password,
  onPasswordChange,
  showGenerator = false,
  description,
}: PasswordStrengthProps) => {
  const [generatedPassword, setGeneratedPassword] = useState<string>('');

  /**
   * Get password strength using zxcvbn
   * Score: 0-4 (0 = too guessable, 4 = very unguessable)
   */
  const getStrength = (pwd: string) => {
    if (!pwd) return { level: 0, label: '', color: '' };

    const result = zxcvbn(pwd);
    const score = result.score; // 0-4

    const strengthMap = [
      { level: 0, label: 'Too weak', color: '#ff4d4f' },
      { level: 1, label: 'Weak', color: '#ff4d4f' },
      { level: 2, label: 'Fair', color: '#faad14' },
      { level: 3, label: 'Good', color: '#52c41a' },
      { level: 4, label: 'Strong', color: '#52c41a' },
    ];

    return strengthMap[score];
  };

  /**
   * Generate a cryptographically strong password
   * Using crypto.getRandomValues for better randomness
   */
  const generatePassword = (length: number = 20): string => {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#$%^&*()_+-=[]{}|;:,.<>?';
    const allChars = uppercase + lowercase + numbers + special;

    let password = '';

    // Ensure at least one character from each category
    const getRandomChar = (chars: string) => {
      const randomIndex =
        crypto.getRandomValues(new Uint32Array(1))[0] % chars.length;
      return chars[randomIndex];
    };

    // Add required characters
    password += getRandomChar(uppercase);
    password += getRandomChar(lowercase);
    password += getRandomChar(numbers);
    password += getRandomChar(special);

    // Fill the rest with random characters
    for (let i = password.length; i < length; i++) {
      password += getRandomChar(allChars);
    }

    // Shuffle using Fisher-Yates algorithm
    const passwordArray = password.split('');
    for (let i = passwordArray.length - 1; i > 0; i--) {
      const j = crypto.getRandomValues(new Uint32Array(1))[0] % (i + 1);
      [passwordArray[i], passwordArray[j]] = [
        passwordArray[j],
        passwordArray[i],
      ];
    }

    return passwordArray.join('');
  };

  const handleGenerate = () => {
    const newPassword = generatePassword();
    setGeneratedPassword(newPassword);
    onPasswordChange?.(newPassword);
    message.success('Password generated!');
  };

  const strength = getStrength(password);
  const displayPassword = generatedPassword || password;

  if (!password && !showGenerator) return null;

  return (
    <Flex
      vertical
      gap={4}
      className='mt-2!'
    >
      {/* Strength Indicator */}
      {displayPassword && (
        <Flex
          gap={8}
          align='center'
          className='mx-1!'
        >
          <div
            className='h-1.25 flex-1 rounded'
            style={{
              backgroundColor: strength.level >= 1 ? strength.color : '#d9d9d9',
            }}
          />
          <div
            className='h-1.25 flex-1 rounded'
            style={{
              backgroundColor: strength.level >= 2 ? strength.color : '#d9d9d9',
            }}
          />
          <div
            className='h-1.25 flex-1 rounded'
            style={{
              backgroundColor: strength.level >= 3 ? strength.color : '#d9d9d9',
            }}
          />
          <div
            className='h-1.25 flex-1 rounded'
            style={{
              backgroundColor: strength.level >= 4 ? strength.color : '#d9d9d9',
            }}
          />
        </Flex>
      )}

      {/* Generator Actions */}
      {showGenerator && (
        <Flex
          gap={8}
          align='center'
        >
          <Text type='secondary'>
            {description}{' '}
            <Text
              onClick={handleGenerate}
              underline
              className='font-medium transition-opacity duration-150 ease-in-out hover:opacity-65'
              style={{ cursor: 'pointer' }}
            >
              Generate Password
            </Text>
          </Text>
        </Flex>
      )}
    </Flex>
  );
};
