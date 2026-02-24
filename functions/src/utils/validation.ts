export const isValidEmail = (email: string | null | undefined): boolean => {
    if (!email || typeof email !== 'string') return false;
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
};

export const isValidPassword = (password: string | null | undefined): boolean => {
    return !!password && typeof password === 'string' && password.length >= 12;
};

export const isValidName = (name: string | null | undefined): boolean => {
    if (!name || typeof name !== 'string') return false;
    return name.length >= 2 && name.length <= 100;
};

export const isValidRole = (role: string | null | undefined): boolean => {
    if (!role || typeof role !== 'string') return false;
    return ['admin', 'agent', 'secretary'].includes(role.toLowerCase());
};
