import { collection, doc, addDoc, updateDoc, deleteDoc, getDocs, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '../../core/firebase/client';
import logger from '../../core/utils/logger';
import { User } from '../../domain/entities/user';
import { Role } from '../../domain/enums';
import { firestoreToUser, userToFirestore } from '../mappers/user.mapper';

export interface UserRepository {
  subscribe(callback: (items: User[]) => void): () => void;
  subscribeByRole(role: Role, callback: (items: User[]) => void): () => void;
  getAll(): Promise<User[]>;
  getByFirebaseUid(uid: string): Promise<User | null>;
  add(data: Omit<User, 'firebaseId' | 'createdAt' | 'updatedAt'>): Promise<string>;
  update(firebaseId: string, partial: Partial<Omit<User, 'firebaseId'>>): Promise<void>;
  remove(firebaseId: string): Promise<void>;
}

export const firestoreUserRepository: UserRepository = {
  subscribe(callback) {
    logger.firestore('UserRepository', 'subscribe to users');
    return onSnapshot(collection(db, 'users'), (snapshot) => {
      logger.firestore('UserRepository', `snapshot recu (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToUser(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('UserRepository', `error in subscribe (${error})`);
    });
  },

  subscribeByRole(role, callback) {
    logger.firestore('UserRepository', `subscribe to users by role (${role})`);
    const q = query(
      collection(db, 'users'),
      where('role', '==', role)
    );
    return onSnapshot(q, (snapshot) => {
      logger.firestore('UserRepository', `snapshot recu (by role) (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToUser(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('UserRepository', `error in subscribeByRole (${error})`);
    });
  },

  async getAll() {
    logger.firestore('UserRepository', 'getAll users');
    const snapshot = await getDocs(collection(db, 'users'));
    return snapshot.docs.map(doc => firestoreToUser(doc.id, doc.data()));
  },

  async getByFirebaseUid(uid: string) {
    logger.firestore('UserRepository', `get user by firebase uid (${uid})`);
    const q = query(collection(db, 'users'), where('firestoreUid', '==', uid));
    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      return null;
    }

    const doc = snapshot.docs[0];
    return firestoreToUser(doc.id, doc.data());
  },

  async add(data) {
    logger.firestore('UserRepository', 'add user');
    const now = new Date();
    const userData: User = {
      ...data,
      firebaseId: null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await addDoc(collection(db, 'users'), userToFirestore(userData));
    await updateDoc(docRef, { firebaseId: docRef.id });

    return docRef.id;
  },

  async update(firebaseId, partial) {
    logger.firestore('UserRepository', `update user (${firebaseId})`);
    const docRef = doc(db, 'users', firebaseId);

    const updateData: Record<string, unknown> = {
      ...partial,
      updatedAt: new Date().toISOString()
    };

    await updateDoc(docRef, updateData);
  },

  async remove(firebaseId) {
    logger.firestore('UserRepository', `remove user (${firebaseId})`);
    await deleteDoc(doc(db, 'users', firebaseId));
  }
};
