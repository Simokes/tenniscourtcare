export const isValidEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

export const isValidPassword = (password: string): boolean => {
    return password.length >= 12;
};

export const isValidName = (name: string): boolean => {
    return name.length >= 2;
};

export const isValidRole = (role: string): boolean => {
    return ['admin', 'agent', 'secretary'].includes(role);
};
