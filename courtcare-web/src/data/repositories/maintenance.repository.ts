import { collection, doc, addDoc, updateDoc, deleteDoc, getDocs, onSnapshot, query, where, orderBy } from 'firebase/firestore';
import { db } from '../../core/firebase/client';
import logger from '../../core/utils/logger';
import { Maintenance } from '../../domain/entities/maintenance';
import { firestoreToMaintenance, maintenanceToFirestore } from '../mappers/maintenance.mapper';

export interface MaintenanceRepository {
  subscribe(callback: (items: Maintenance[]) => void): () => void;
  subscribeByTerrain(terrainId: number, callback: (items: Maintenance[]) => void): () => void;
  getAll(): Promise<Maintenance[]>;
  add(data: Omit<Maintenance, 'firebaseId' | 'createdAt' | 'updatedAt'>): Promise<string>;
  update(firebaseId: string, partial: Partial<Omit<Maintenance, 'firebaseId'>>): Promise<void>;
  remove(firebaseId: string): Promise<void>;
}

export const firestoreMaintenanceRepository: MaintenanceRepository = {
  subscribe(callback) {
    logger.firestore('MaintenanceRepository', 'subscribe to maintenances');
    return onSnapshot(collection(db, 'maintenance'), (snapshot) => {
      logger.firestore('MaintenanceRepository', `snapshot recu (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToMaintenance(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('MaintenanceRepository', `error in subscribe (${error})`);
    });
  },

  subscribeByTerrain(terrainId, callback) {
    logger.firestore('MaintenanceRepository', `subscribe to maintenances by terrain (${terrainId})`);
    const q = query(
      collection(db, 'maintenance'),
      where('terrainId', '==', terrainId),
      orderBy('date', 'desc')
    );
    return onSnapshot(q, (snapshot) => {
      logger.firestore('MaintenanceRepository', `snapshot recu (by terrain) (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToMaintenance(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('MaintenanceRepository', `error in subscribeByTerrain (${error})`);
    });
  },

  async getAll() {
    logger.firestore('MaintenanceRepository', 'getAll maintenances');
    const snapshot = await getDocs(collection(db, 'maintenance'));
    return snapshot.docs.map(doc => firestoreToMaintenance(doc.id, doc.data()));
  },

  async add(data) {
    logger.firestore('MaintenanceRepository', 'add maintenance');
    const now = new Date();
    const maintenanceData: Maintenance = {
      ...data,
      firebaseId: null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await addDoc(collection(db, 'maintenance'), maintenanceToFirestore(maintenanceData));
    await updateDoc(docRef, { firebaseId: docRef.id });

    return docRef.id;
  },

  async update(firebaseId, partial) {
    logger.firestore('MaintenanceRepository', `update maintenance (${firebaseId})`);
    const docRef = doc(db, 'maintenance', firebaseId);

    const updateData: Record<string, unknown> = {
      ...partial,
      updatedAt: new Date().toISOString()
    };

    await updateDoc(docRef, updateData);
  },

  async remove(firebaseId) {
    logger.firestore('MaintenanceRepository', `remove maintenance (${firebaseId})`);
    await deleteDoc(doc(db, 'maintenance', firebaseId));
  }
};
