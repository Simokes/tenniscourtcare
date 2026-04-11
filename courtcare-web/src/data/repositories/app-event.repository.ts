import { collection, doc, addDoc, updateDoc, deleteDoc, getDocs, onSnapshot, query, where, Timestamp } from 'firebase/firestore';
import { db } from '../../core/firebase/client';
import logger from '../../core/utils/logger';
import { AppEvent } from '../../domain/entities/app-event';
import { firestoreToAppEvent, appEventToFirestore } from '../mappers/app-event.mapper';

export interface AppEventRepository {
  subscribe(callback: (items: AppEvent[]) => void): () => void;
  subscribeByDateRange(start: Date, end: Date, callback: (items: AppEvent[]) => void): () => void;
  getAll(): Promise<AppEvent[]>;
  add(data: Omit<AppEvent, 'firebaseId' | 'createdAt' | 'updatedAt'>): Promise<string>;
  update(firebaseId: string, partial: Partial<Omit<AppEvent, 'firebaseId'>>): Promise<void>;
  remove(firebaseId: string): Promise<void>;
}

export const firestoreAppEventRepository: AppEventRepository = {
  subscribe(callback) {
    logger.firestore('AppEventRepository', 'subscribe to events');
    return onSnapshot(collection(db, 'events'), (snapshot) => {
      logger.firestore('AppEventRepository', `snapshot recu (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToAppEvent(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('AppEventRepository', `error in subscribe (${error})`);
    });
  },

  subscribeByDateRange(start, end, callback) {
    logger.firestore('AppEventRepository', `subscribe to events by date range (${start} - ${end})`);
    const q = query(
      collection(db, 'events'),
      where('startTime', '>=', Timestamp.fromDate(start)),
      where('startTime', '<=', Timestamp.fromDate(end))
    );
    return onSnapshot(q, (snapshot) => {
      logger.firestore('AppEventRepository', `snapshot recu (by date range) (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToAppEvent(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('AppEventRepository', `error in subscribeByDateRange (${error})`);
    });
  },

  async getAll() {
    logger.firestore('AppEventRepository', 'getAll events');
    const snapshot = await getDocs(collection(db, 'events'));
    return snapshot.docs.map(doc => firestoreToAppEvent(doc.id, doc.data()));
  },

  async add(data) {
    logger.firestore('AppEventRepository', 'add event');
    const now = new Date();
    const eventData: AppEvent = {
      ...data,
      firebaseId: null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await addDoc(collection(db, 'events'), appEventToFirestore(eventData));
    await updateDoc(docRef, { firebaseId: docRef.id });

    return docRef.id;
  },

  async update(firebaseId, partial) {
    logger.firestore('AppEventRepository', `update event (${firebaseId})`);
    const docRef = doc(db, 'events', firebaseId);

    const updateData: Record<string, unknown> = {
      ...partial,
      updatedAt: new Date().toISOString()
    };

    await updateDoc(docRef, updateData);
  },

  async remove(firebaseId) {
    logger.firestore('AppEventRepository', `remove event (${firebaseId})`);
    await deleteDoc(doc(db, 'events', firebaseId));
  }
};
