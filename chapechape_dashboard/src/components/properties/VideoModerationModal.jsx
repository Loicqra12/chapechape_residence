import React, { useState, useRef } from 'react';
import {
  CheckCircleIcon,
  XCircleIcon,
  VideoCameraIcon,
  XMarkIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';
import axios from 'axios';
import { API_URL } from '../../config';

const STATUS_LABELS = {
  pending_review: 'En attente',
  approved:       'Approuvée',
  rejected:       'Rejetée',
};

const STATUS_COLORS = {
  pending_review: 'bg-yellow-100 text-yellow-800',
  approved:       'bg-green-100 text-green-800',
  rejected:       'bg-red-100 text-red-800',
};

/**
 * Modale de modération des vidéos d'une résidence.
 *
 * Props :
 *   - residence : objet résidence complet (avec residence.videos[])
 *   - onClose   : callback fermeture
 *   - onUpdated : callback appelé après approve/reject pour rafraîchir la liste
 */
export default function VideoModerationModal({ residence, onClose, onUpdated }) {
  const [processing, setProcessing] = useState(null); // videoId en cours
  const [rejectReason, setRejectReason] = useState('');
  const [rejectingId, setRejectingId] = useState(null);
  const videoRef = useRef(null);

  const token = localStorage.getItem('token');
  const authHeaders = { headers: { Authorization: `Bearer ${token}` } };

  const videos = residence?.videos ?? [];
  const residenceId = residence?._id || residence?.id;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  const handleApprove = async (videoId) => {
    if (!residenceId) {
      alert('ID résidence manquant');
      return;
    }
    setProcessing(videoId);
    try {
      await axios.put(
        `${API_URL}/residences/${residenceId}/videos/${videoId}/approve`,
        {},
        authHeaders,
      );
      onUpdated?.();
    } catch (err) {
      alert(`Erreur : ${err?.response?.data?.message ?? err.message}`);
    } finally {
      setProcessing(null);
    }
  };

  const handleReject = async (videoId) => {
    if (!rejectReason.trim()) {
      alert('Veuillez indiquer la raison du rejet.');
      return;
    }
    if (!residenceId) {
      alert('ID résidence manquant');
      return;
    }
    setProcessing(videoId);
    try {
      await axios.put(
        `${API_URL}/residences/${residenceId}/videos/${videoId}/reject`,
        { reason: rejectReason },
        authHeaders,
      );
      setRejectingId(null);
      setRejectReason('');
      onUpdated?.();
    } catch (err) {
      alert(`Erreur : ${err?.response?.data?.message ?? err.message}`);
    } finally {
      setProcessing(null);
    }
  };

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  return (
    <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b">
          <div className="flex items-center gap-2">
            <VideoCameraIcon className="w-5 h-5 text-indigo-600" />
            <h2 className="text-lg font-semibold text-gray-900">
              Vidéos — {residence?.title ?? 'Résidence'}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-full hover:bg-gray-100 transition"
          >
            <XMarkIcon className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Corps */}
        <div className="p-6 space-y-6">
          {videos.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <VideoCameraIcon className="w-12 h-12 mx-auto mb-3 opacity-40" />
              <p>Aucune vidéo pour cette résidence.</p>
            </div>
          ) : (
            videos.map((video) => (
              <div
                key={video._id}
                className="border rounded-xl overflow-hidden"
              >
                {/* Lecteur vidéo */}
                <div className="relative bg-black aspect-video">
                  <video
                    ref={videoRef}
                    src={video.url}
                    poster={video.thumbnail}
                    controls
                    className="w-full h-full object-contain"
                  />
                  {/* Badge statut */}
                  <span
                    className={`absolute top-2 left-2 px-2 py-1 rounded-full text-xs font-semibold ${
                      STATUS_COLORS[video.status] ?? 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {STATUS_LABELS[video.status] ?? video.status}
                  </span>
                </div>

                {/* Métadonnées */}
                <div className="px-4 py-3 bg-gray-50 border-t flex items-center gap-4 text-sm text-gray-600">
                  {video.duration && (
                    <span className="flex items-center gap-1">
                      <ClockIcon className="w-4 h-4" />
                      {Math.round(video.duration)}s
                    </span>
                  )}
                  {video.size && (
                    <span>
                      {(video.size / 1024 / 1024).toFixed(1)} Mo
                    </span>
                  )}
                  {video.uploadedAt && (
                    <span>
                      Uploadée le{' '}
                      {new Date(video.uploadedAt).toLocaleDateString('fr-FR')}
                    </span>
                  )}
                  {video.rejectionReason && (
                    <span className="text-red-600">
                      Rejet : {video.rejectionReason}
                    </span>
                  )}
                </div>

                {/* Actions modération */}
                {video.status !== 'approved' && (
                  <div className="px-4 py-3 flex flex-col gap-2">
                    {/* Approuver */}
                    <button
                      disabled={!!processing}
                      onClick={() => handleApprove(video._id)}
                      className="flex items-center gap-2 justify-center w-full py-2 px-4 bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white rounded-lg font-medium transition"
                    >
                      <CheckCircleIcon className="w-5 h-5" />
                      {processing === video._id ? 'Traitement…' : 'Approuver'}
                    </button>

                    {/* Rejeter */}
                    {rejectingId === video._id ? (
                      <div className="space-y-2">
                        <textarea
                          className="w-full border rounded-lg p-2 text-sm resize-none"
                          rows={2}
                          placeholder="Raison du rejet (obligatoire)…"
                          value={rejectReason}
                          onChange={(e) => setRejectReason(e.target.value)}
                        />
                        <div className="flex gap-2">
                          <button
                            disabled={!!processing}
                            onClick={() => handleReject(video._id)}
                            className="flex-1 py-2 px-4 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white rounded-lg font-medium transition"
                          >
                            Confirmer le rejet
                          </button>
                          <button
                            onClick={() => {
                              setRejectingId(null);
                              setRejectReason('');
                            }}
                            className="px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50 transition"
                          >
                            Annuler
                          </button>
                        </div>
                      </div>
                    ) : (
                      <button
                        onClick={() => setRejectingId(video._id)}
                        className="flex items-center gap-2 justify-center w-full py-2 px-4 border border-red-300 hover:bg-red-50 text-red-600 rounded-lg font-medium transition"
                      >
                        <XCircleIcon className="w-5 h-5" />
                        Rejeter
                      </button>
                    )}
                  </div>
                )}

                {/* Déjà approuvée */}
                {video.status === 'approved' && (
                  <div className="px-4 py-3">
                    <p className="text-sm text-green-700 font-medium flex items-center gap-1">
                      <CheckCircleIcon className="w-4 h-4" />
                      Cette vidéo est approuvée et visible par les clients.
                    </p>
                  </div>
                )}
              </div>
            ))
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50 transition"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
}
