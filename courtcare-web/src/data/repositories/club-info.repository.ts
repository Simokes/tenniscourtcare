import { doc, updateDoc } from 'firebase/firestore';
import { db } from '../../core/firebase/client';
import logger from '../../core/utils/logger';

export interface ClubInfoRepository {
  update(partial: Record<string, unknown>): Promise<void>;
}

export const firestoreClubInfoRepository: ClubInfoRepository = {
  async update(partial) {
    logger.firestore('ClubInfoRepository', 'update main doc');
    const docRef = doc(db, 'clubInfo', 'main');
    await updateDoc(docRef, partial);
  }
};
