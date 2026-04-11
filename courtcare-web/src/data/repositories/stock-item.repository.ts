import { collection, doc, addDoc, updateDoc, deleteDoc, getDocs, onSnapshot } from 'firebase/firestore';
import { db } from '../../core/firebase/client';
import logger from '../../core/utils/logger';
import { StockItem } from '../../domain/entities/stock-item';
import { firestoreToStockItem, stockItemToFirestore } from '../mappers/stock-item.mapper';

export interface StockItemRepository {
  subscribe(callback: (items: StockItem[]) => void): () => void;
  getAll(): Promise<StockItem[]>;
  add(data: Omit<StockItem, 'firebaseId' | 'createdAt' | 'updatedAt'>): Promise<string>;
  update(firebaseId: string, partial: Partial<Omit<StockItem, 'firebaseId'>>): Promise<void>;
  remove(firebaseId: string): Promise<void>;
}

export const firestoreStockItemRepository: StockItemRepository = {
  subscribe(callback) {
    logger.firestore('StockItemRepository', 'subscribe to stock items');
    return onSnapshot(collection(db, 'stock'), (snapshot) => {
      logger.firestore('StockItemRepository', `snapshot recu (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToStockItem(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('StockItemRepository', `error in subscribe (${error})`);
    });
  },

  async getAll() {
    logger.firestore('StockItemRepository', 'getAll stock items');
    const snapshot = await getDocs(collection(db, 'stock'));
    return snapshot.docs.map(doc => firestoreToStockItem(doc.id, doc.data()));
  },

  async add(data) {
    logger.firestore('StockItemRepository', 'add stock item');
    const now = new Date();
    const itemData: StockItem = {
      ...data,
      firebaseId: null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await addDoc(collection(db, 'stock'), stockItemToFirestore(itemData));
    await updateDoc(docRef, { firebaseId: docRef.id });

    return docRef.id;
  },

  async update(firebaseId, partial) {
    logger.firestore('StockItemRepository', `update stock item (${firebaseId})`);
    const docRef = doc(db, 'stock', firebaseId);

    const updateData: Record<string, unknown> = {
      ...partial,
      updatedAt: new Date().toISOString()
    };

    await updateDoc(docRef, updateData);
  },

  async remove(firebaseId) {
    logger.firestore('StockItemRepository', `remove stock item (${firebaseId})`);
    await deleteDoc(doc(db, 'stock', firebaseId));
  }
};
