import { collection, doc, addDoc, updateDoc, deleteDoc, getDocs, onSnapshot } from 'firebase/firestore';
import { db } from '../../core/firebase/client';
import logger from '../../core/utils/logger';
import { Terrain } from '../../domain/entities/terrain';
import { firestoreToTerrain, terrainToFirestore } from '../mappers/terrain.mapper';

export interface TerrainRepository {
  subscribe(callback: (items: Terrain[]) => void): () => void;
  getAll(): Promise<Terrain[]>;
  add(data: Omit<Terrain, 'firebaseId' | 'createdAt' | 'updatedAt'>): Promise<string>;
  update(firebaseId: string, partial: Partial<Omit<Terrain, 'firebaseId'>>): Promise<void>;
  remove(firebaseId: string): Promise<void>;
}

export const firestoreTerrainRepository: TerrainRepository = {
  subscribe(callback) {
    logger.firestore('TerrainRepository', 'subscribe to terrains');
    return onSnapshot(collection(db, 'terrains'), (snapshot) => {
      logger.firestore('TerrainRepository', `snapshot recu (${snapshot.size} items)`);
      const items = snapshot.docs.map(doc => firestoreToTerrain(doc.id, doc.data()));
      callback(items);
    }, (error) => {
      logger.firestore('TerrainRepository', `error in subscribe (${error})`);
    });
  },

  async getAll() {
    logger.firestore('TerrainRepository', 'getAll terrains');
    const snapshot = await getDocs(collection(db, 'terrains'));
    return snapshot.docs.map(doc => firestoreToTerrain(doc.id, doc.data()));
  },

  async add(data) {
    logger.firestore('TerrainRepository', 'add terrain');
    const now = new Date();
    const terrainData: Terrain = {
      ...data,
      firebaseId: null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await addDoc(collection(db, 'terrains'), terrainToFirestore(terrainData));
    await updateDoc(docRef, { firebaseId: docRef.id });

    return docRef.id;
  },

  async update(firebaseId, partial) {
    logger.firestore('TerrainRepository', `update terrain (${firebaseId})`);
    const docRef = doc(db, 'terrains', firebaseId);

    const updateData: Record<string, unknown> = {
      ...partial,
      updatedAt: new Date().toISOString()
    };

    await updateDoc(docRef, updateData);
  },

  async remove(firebaseId) {
    logger.firestore('TerrainRepository', `remove terrain (${firebaseId})`);
    await deleteDoc(doc(db, 'terrains', firebaseId));
  }
};
