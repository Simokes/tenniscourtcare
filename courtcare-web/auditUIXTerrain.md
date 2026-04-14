  ---
  Audit UI/UX — Page Terrains

  Accessibilité (CRITIQUE)

  A1 — Modals sans ARIA L.282, 335, 388
  Les 3 modals n'ont ni role="dialog", ni aria-modal="true", ni aria-labelledby. Un lecteur d'écran ne sait pas 
  qu'une fenêtre modale est ouverte.
  // Actuel
  <div className="fixed inset-0 z-50 ...">

  // Corrigé
  <div role="dialog" aria-modal="true" aria-labelledby="modal-title" className="fixed inset-0 z-50 ...">        
  <h2 id="modal-title" ...>

  A2 — Pas de focus trap dans les modals L.282, 335, 388
  Quand une modal s'ouvre, le focus reste sur la page derrière. Il faut piéger le focus dans la modal et le     
  restaurer à la fermeture (utiliser un hook useFocusTrap ou la lib focus-trap-react).

  A3 — Pas de fermeture au Escape L.282, 335, 388
  Aucun onKeyDown sur le backdrop ni useEffect pour écouter Escape. Standard UX/a11y pour toute modal.

  A4 — Labels sans for/htmlFor L.290-296, 299-309, 342-354, 356-363
  Les <label> n'ont pas de htmlFor et les <input>/<select> n'ont pas d'id. Association label ↔ champ absente.   
  // Actuel
  <label className="...">Nom</label>
  <input type="text" {...registerAddEdit('nom')} />

  // Corrigé
  <label htmlFor="terrain-nom" className="...">Nom</label>
  <input id="terrain-nom" type="text" {...registerAddEdit('nom')} />

  A5 — Erreurs de formulaire sans role="alert" L.296, 309
  // Actuel
  <p className="text-red-500 text-xs mt-1">{errorsAddEdit.nom.message}</p>

  // Corrigé
  <p role="alert" className="text-red-500 text-xs mt-1">{errorsAddEdit.nom.message}</p>

  A6 — Badge statut : couleur seule L.211-216
  terrainStatusColors code uniquement par couleur (inline style). Daltoniens ne distinguent pas les statuts.    
  Ajouter une icône ou un texte court déjà présent, mais le badge inline style ne passe pas en dark mode.       

  ---
  Interaction & Feedback (ÉLEVÉ)

  I1 — Pas de feedback succès sur mutations L.61-64, 69-72
  Après ajout/modification, la modal se ferme silencieusement. Aucun toast ni message de confirmation.
  L'utilisateur ne sait pas si l'opération a réussi.

  I2 — Erreurs mutations non affichées L.48-100
  addMutation.isError, updateMutation.isError, deleteMutation.isError, closeMutation.isError ne sont jamais     
  rendus. Si Firestore échoue, l'utilisateur voit juste la modal qui reste ouverte.

  I3 — Bouton "Rouvrir" sans loading indicator L.241-247
  disabled={reopenMutation.isPending} mais aucun spinner ou texte "En cours…". L'utilisateur peut croire que son
   clic n'a pas marché.

  I4 — Backdrop des modals non cliquable L.282, 335, 388
  Clic sur bg-black/50 ne ferme pas la modal. Comportement standard attendu.
  <div
    className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
    onClick={() => setIsAddEditModalOpen(false)}
  >
    <div onClick={(e) => e.stopPropagation()} className="bg-white ...">

  I5 — cursor-pointer absent sur les boutons d'action L.233-270
  Tailwind Preflight ne garantit pas cursor: pointer sur les <button>. À ajouter explicitement.

  ---
  Layout & Responsive (MOYEN)

  L1 — Skeleton loading absent L.187-189
  Un spinner unique pour toute la page cause un content jump à l'arrivée des données. Utiliser des skeleton     
  cards (3 rectangles gris animés) pour maintenir la structure.

  L2 — Inline style pour les couleurs de statut L.213-214
  style={{ backgroundColor: terrainStatusColors[terrain.status] }} contourne le système de design Tailwind et ne
   supporte pas le dark mode. Mapper les statuts vers des classes Tailwind.
  // Remplacer inline style par classes conditionnelles
  const statusClasses: Record<TerrainStatus, string> = {
    [TerrainStatus.PLAYABLE]: 'bg-emerald-500',
    [TerrainStatus.UNAVAILABLE]: 'bg-zinc-500',
    [TerrainStatus.MAINTENANCE]: 'bg-blue-500',
  }

  L3 — Cards : hauteur inégale sur contenu variable L.197
  h-full + flex-col + double mt-auto (L.220 et L.230) est fragile. La div vide L.230 est un spacer hack.        
  Utiliser justify-between + mt-auto une seule fois sur la zone footer.

  ---
  Code Quality (FAIBLE)

  Q1 — id: Date.now() L.50
  Commentaire reconnaît la mauvaise pratique. À remplacer par crypto.randomUUID() ou supprimer le champ id si le
   repository peut s'en passer.

  Q2 — useForm et reset dupliqué L.40-41
  Un seul formulaire sert à la fois pour "add" et "edit" — acceptable, mais les appels resetAddEdit en L.63 et  
  L.71 (dans onSuccess) + L.104 et L.110 (dans les handlers) dupliquent la logique de reset.

  ---
  Récapitulatif priorités

  ┌────────────┬──────────────────────────────────────────┬──────────┐
  │     #      │                 Problème                 │ Sévérité │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ A1–A3      │ Modals ARIA + focus trap + Escape        │ Critique │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ A4–A5      │ Labels for + role alert                  │ Élevé    │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ I1–I2      │ Feedback succès/erreur mutations         │ Élevé    │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ I4         │ Backdrop cliquable                       │ Élevé    │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ A6, I3, I5 │ Badge couleur, loading indicator, cursor │ Moyen    │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ L1–L3      │ Skeleton, inline styles, height cards    │ Moyen    │
  ├────────────┼──────────────────────────────────────────┼──────────┤
  │ Q1–Q2      │ Date.now(), reset dupliqué               │ Faible   │
  └────────────┴──────────────────────────────────────────┴──────────┘