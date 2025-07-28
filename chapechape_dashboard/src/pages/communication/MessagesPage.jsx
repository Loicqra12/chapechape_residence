import React, { useState, useEffect } from 'react';
import {
  Mail,
  Inbox,
  Send,
  Star,
  Trash2,
  Search,
  Plus,
  RefreshCw,
  Filter,
  Archive,
  MoreHorizontal,
  Reply,
  Forward,
  X,
  Paperclip,
  Eye,
  EyeOff,
  Clock,
  User,
  CheckCircle
} from 'lucide-react';
import { communicationService } from '../../services/communicationService';
import MessageList from '../../components/communication/MessageList';
import ComposeMessage from '../../components/communication/ComposeMessage';
import toast from 'react-hot-toast';

// ============ COMPOSANTS RÉUTILISABLES ============

// Composant Folder Item
const FolderItem = ({ folder, isSelected, onClick, count }) => {
  const Icon = folder.icon;
  
  return (
    <button
      onClick={() => onClick(folder.id)}
      className={`w-full flex items-center justify-between p-3 rounded-lg transition-all duration-200 group ${
        isSelected
          ? 'bg-primary-500 text-white shadow-lg'
          : 'text-gray-700 hover:bg-primary-50 hover:text-primary-700'
      }`}
    >
      <div className="flex items-center space-x-3">
        <Icon className={`w-5 h-5 ${isSelected ? 'text-white' : 'text-gray-500 group-hover:text-primary-600'}`} />
        <span className="font-medium">{folder.label}</span>
      </div>
      {count > 0 && (
        <span className={`text-xs font-bold px-2 py-1 rounded-full ${
          isSelected 
            ? 'bg-white bg-opacity-20 text-white' 
            : 'bg-primary-100 text-primary-700'
        }`}>
          {count}
        </span>
      )}
    </button>
  );
};

// Composant Message Card
const MessageCard = ({ message, onStar, onReply, onDelete, onMarkRead }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className={`bg-white border rounded-lg transition-all duration-200 hover:shadow-md ${
      !message.read ? 'border-primary-200 bg-primary-25' : 'border-gray-200'
    }`}>
      {/* Header du message */}
      <div className="p-4 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="relative">
              {message.sender?.avatar ? (
                <img 
                  src={message.sender.avatar} 
                  alt={message.sender.name}
                  className="w-10 h-10 rounded-full object-cover"
                />
              ) : (
                <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                  <User className="w-5 h-5 text-primary-600" />
                </div>
              )}
              {!message.read && (
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-primary-500 rounded-full"></div>
              )}
            </div>
            
            <div className="flex-1 min-w-0">
              <div className="flex items-center space-x-2">
                <h4 className={`font-medium ${!message.read ? 'text-gray-900' : 'text-gray-700'}`}>
                  {message.sender?.name || 'Expéditeur inconnu'}
                </h4>
                {!message.read && (
                  <span className="text-xs bg-primary-100 text-primary-700 px-2 py-1 rounded-full font-medium">
                    Nouveau
                  </span>
                )}
              </div>
              <p className={`text-sm ${!message.read ? 'font-medium text-gray-900' : 'text-gray-600'}`}>
                {message.subject || 'Sans objet'}
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <span className="text-xs text-gray-500">
              {new Date(message.createdAt).toLocaleDateString('fr-FR', {
                day: 'numeric',
                month: 'short',
                hour: '2-digit',
                minute: '2-digit'
              })}
            </span>
            
            <button
              onClick={() => onStar(message._id)}
              className={`p-1 rounded transition-colors ${
                message.starred 
                  ? 'text-yellow-500 hover:text-yellow-600' 
                  : 'text-gray-400 hover:text-yellow-500'
              }`}
              title={message.starred ? 'Retirer des favoris' : 'Ajouter aux favoris'}
            >
              <Star className={`w-4 h-4 ${message.starred ? 'fill-current' : ''}`} />
            </button>

            <button
              onClick={() => setIsExpanded(!isExpanded)}
              className="p-1 text-gray-400 hover:text-gray-600 rounded transition-colors"
              title={isExpanded ? 'Réduire' : 'Développer'}
            >
              {isExpanded ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>

            <div className="relative group">
              <button className="p-1 text-gray-400 hover:text-gray-600 rounded transition-colors">
                <MoreHorizontal className="w-4 h-4" />
              </button>
              
              {/* Menu contextuel */}
              <div className="absolute right-0 top-full mt-1 w-48 bg-white rounded-lg shadow-lg border border-gray-200 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-10">
                <div className="py-1">
                  <button
                    onClick={() => onMarkRead(message._id)}
                    className="w-full flex items-center space-x-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <CheckCircle className="w-4 h-4" />
                    <span>{message.read ? 'Marquer non lu' : 'Marquer lu'}</span>
                  </button>
                  <button
                    onClick={() => onReply(message)}
                    className="w-full flex items-center space-x-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <Reply className="w-4 h-4" />
                    <span>Répondre</span>
                  </button>
                  <button className="w-full flex items-center space-x-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50">
                    <Forward className="w-4 h-4" />
                    <span>Transférer</span>
                  </button>
                  <button className="w-full flex items-center space-x-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50">
                    <Archive className="w-4 h-4" />
                    <span>Archiver</span>
                  </button>
                  <div className="border-t border-gray-100 my-1"></div>
                  <button
                    onClick={() => onDelete(message._id)}
                    className="w-full flex items-center space-x-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50"
                  >
                    <Trash2 className="w-4 h-4" />
                    <span>Supprimer</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Contenu du message */}
      {isExpanded && (
        <div className="p-4">
          <div className="prose prose-sm max-w-none">
            <p className="text-gray-700 leading-relaxed">
              {message.content || 'Aucun contenu disponible'}
            </p>
          </div>
          
          {/* Pièces jointes */}
          {message.attachments && message.attachments.length > 0 && (
            <div className="mt-4 p-3 bg-gray-50 rounded-lg">
              <h5 className="text-sm font-medium text-gray-900 mb-2 flex items-center">
                <Paperclip className="w-4 h-4 mr-1" />
                Pièces jointes ({message.attachments.length})
              </h5>
              <div className="space-y-2">
                {message.attachments.map((attachment, index) => (
                  <div key={index} className="flex items-center space-x-2 text-sm">
                    <Paperclip className="w-3 h-3 text-gray-400" />
                    <span className="text-primary-600 hover:text-primary-700 cursor-pointer">
                      {attachment.name}
                    </span>
                    <span className="text-gray-500">({attachment.size})</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center space-x-3 mt-4 pt-4 border-t border-gray-100">
            <button
              onClick={() => onReply(message)}
              className="flex items-center space-x-1 px-3 py-1.5 text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
            >
              <Reply className="w-4 h-4" />
              <span>Répondre</span>
            </button>
            <button className="flex items-center space-x-1 px-3 py-1.5 text-gray-600 hover:bg-gray-50 rounded-lg transition-colors">
              <Forward className="w-4 h-4" />
              <span>Transférer</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

// Composant Compose Dialog
const ComposeDialog = ({ isOpen, onClose, onSend, replyTo }) => {
  const [formData, setFormData] = useState({
    to: replyTo?.sender?.email || '',
    subject: replyTo ? `Re: ${replyTo.subject}` : '',
    content: ''
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (formData.to && formData.content) {
      onSend(formData);
      setFormData({ to: '', subject: '', content: '' });
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900">
            {replyTo ? 'Répondre au message' : 'Nouveau message'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Formulaire */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Destinataire
            </label>
            <input
              type="email"
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              value={formData.to}
              onChange={(e) => setFormData({ ...formData, to: e.target.value })}
              placeholder="email@exemple.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Objet
            </label>
            <input
              type="text"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              value={formData.subject}
              onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
              placeholder="Objet du message"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Message
            </label>
            <textarea
              required
              rows={8}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 resize-none"
              value={formData.content}
              onChange={(e) => setFormData({ ...formData, content: e.target.value })}
              placeholder="Rédigez votre message..."
            />
          </div>

          {/* Message original en réponse */}
          {replyTo && (
            <div className="bg-gray-50 rounded-lg p-4 border-l-4 border-primary-500">
              <h4 className="text-sm font-medium text-gray-900 mb-2">Message original :</h4>
              <p className="text-sm text-gray-600">{replyTo.content}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center justify-between pt-4">
            <div className="flex items-center space-x-2">
              <button
                type="button"
                className="flex items-center space-x-1 px-3 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <Paperclip className="w-4 h-4" />
                <span>Joindre</span>
              </button>
            </div>
            
            <div className="flex items-center space-x-3">
              <button
                type="button"
                onClick={onClose}
                className="px-6 py-2 text-gray-600 hover:text-gray-800 font-medium"
              >
                Annuler
              </button>
              <button
                type="submit"
                className="flex items-center space-x-2 px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
              >
                <Send className="w-4 h-4" />
                <span>Envoyer</span>
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};

// ============ COMPOSANT PRINCIPAL ============

const MessagesPage = () => {
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState('inbox');
  const [searchTerm, setSearchTerm] = useState('');
  const [composeOpen, setComposeOpen] = useState(false);
  const [replyTo, setReplyTo] = useState(null);
  const [stats, setStats] = useState({
    inbox: 0,
    unread: 0,
    starred: 0,
    sent: 0,
    trash: 0,
  });

  useEffect(() => {
    loadMessages();
  }, [selectedFolder, searchTerm]);

  const loadMessages = async () => {
    try {
      setLoading(true);
      const response = await communicationService.getMessages();
      
      if (response.success) {
        let filteredMessages = response.data;

        // Filtrer selon le dossier sélectionné
        switch (selectedFolder) {
          case 'inbox':
            filteredMessages = filteredMessages.filter(m => !m.sent && !m.deleted);
            break;
          case 'sent':
            filteredMessages = filteredMessages.filter(m => m.sent);
            break;
          case 'starred':
            filteredMessages = filteredMessages.filter(m => m.starred);
            break;
          case 'trash':
            filteredMessages = filteredMessages.filter(m => m.deleted);
            break;
          default:
            break;
        }

        // Appliquer la recherche
        if (searchTerm) {
          const term = searchTerm.toLowerCase();
          filteredMessages = filteredMessages.filter(m =>
            m.subject?.toLowerCase().includes(term) ||
            m.content?.toLowerCase().includes(term) ||
            m.sender?.name?.toLowerCase().includes(term)
          );
        }

        setMessages(filteredMessages);
        
        // Mettre à jour les statistiques
        setStats({
          inbox: response.data.filter(m => !m.sent && !m.deleted).length,
          unread: response.data.filter(m => !m.read && !m.deleted).length,
          starred: response.data.filter(m => m.starred).length,
          sent: response.data.filter(m => m.sent).length,
          trash: response.data.filter(m => m.deleted).length,
        });

        toast.success('Messages chargés avec succès');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des messages:', error);
      toast.error('Erreur lors du chargement des messages');
    } finally {
      setLoading(false);
    }
  };

  const handleCompose = () => {
    setReplyTo(null);
    setComposeOpen(true);
  };

  const handleReply = (message) => {
    setReplyTo(message);
    setComposeOpen(true);
  };

  const handleSend = async (messageData) => {
    try {
      const response = await communicationService.sendMessage(messageData);
      if (response.success) {
        toast.success('Message envoyé avec succès');
        loadMessages();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de l\'envoi du message:', error);
      toast.error('Erreur lors de l\'envoi du message');
    }
  };

  const handleStar = async (messageId) => {
    try {
      const message = messages.find(m => m._id === messageId);
      const response = await communicationService.toggleMessageStar(messageId);
      if (response.success) {
        setMessages(messages.map(m =>
          m._id === messageId ? { ...m, starred: !m.starred } : m
        ));
        toast.success(message?.starred ? 'Retiré des favoris' : 'Ajouté aux favoris');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la modification du message:', error);
      toast.error('Erreur lors de la modification du message');
    }
  };

  const handleDelete = async (messageId) => {
    try {
      const response = await communicationService.deleteMessage(messageId);
      if (response.success) {
        setMessages(messages.filter(m => m._id !== messageId));
        toast.success('Message supprimé');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la suppression du message:', error);
      toast.error('Erreur lors de la suppression du message');
    }
  };

  const handleMarkRead = async (messageId) => {
    try {
      const message = messages.find(m => m._id === messageId);
      // Simuler le changement d'état lu/non lu
      setMessages(messages.map(m =>
        m._id === messageId ? { ...m, read: !m.read } : m
      ));
      toast.success(message?.read ? 'Marqué comme non lu' : 'Marqué comme lu');
    } catch (error) {
      toast.error('Erreur lors de la modification du message');
    }
  };

  const folders = [
    { id: 'inbox', label: 'Boîte de réception', icon: Inbox, count: stats.inbox },
    { id: 'sent', label: 'Messages envoyés', icon: Send, count: stats.sent },
    { id: 'starred', label: 'Favoris', icon: Star, count: stats.starred },
    { id: 'trash', label: 'Corbeille', icon: Trash2, count: stats.trash },
  ];

  if (loading && messages.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-primary-200 rounded-full animate-spin"></div>
            <div className="absolute top-0 left-0 w-16 h-16 border-4 border-primary-600 border-t-transparent rounded-full animate-spin"></div>
          </div>
          <p className="text-gray-600 font-medium text-lg">Chargement de la messagerie...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex h-screen">
        {/* Sidebar */}
        <div className="w-80 bg-white border-r border-gray-200 flex flex-col">
          {/* Header sidebar */}
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-12 h-12 bg-primary-500 rounded-xl flex items-center justify-center">
                <Mail className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">Messagerie</h1>
                {stats.unread > 0 && (
                  <p className="text-sm text-primary-600">
                    {stats.unread} message{stats.unread > 1 ? 's' : ''} non lu{stats.unread > 1 ? 's' : ''}
                  </p>
                )}
              </div>
            </div>
            
            <button
              onClick={handleCompose}
              className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
            >
              <Plus className="w-5 h-5" />
              <span>Nouveau message</span>
            </button>
          </div>

          {/* Dossiers */}
          <div className="flex-1 p-4 space-y-2">
            {folders.map((folder) => (
              <FolderItem
                key={folder.id}
                folder={folder}
                isSelected={selectedFolder === folder.id}
                onClick={setSelectedFolder}
                count={folder.count}
              />
            ))}
          </div>
        </div>

        {/* Contenu principal */}
        <div className="flex-1 flex flex-col">
          {/* Header */}
          <div className="bg-white border-b border-gray-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-bold text-gray-900 capitalize">
                  {folders.find(f => f.id === selectedFolder)?.label}
                </h2>
                <p className="text-gray-600">
                  {messages.length} message{messages.length > 1 ? 's' : ''}
                </p>
              </div>

              <div className="flex items-center space-x-3">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="text"
                    placeholder="Rechercher..."
                    className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
                
                <button
                  onClick={loadMessages}
                  disabled={loading}
                  className="flex items-center space-x-1 px-3 py-2 text-gray-600 hover:text-gray-800 rounded-lg hover:bg-gray-100 transition-colors"
                >
                  <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                  <span>Actualiser</span>
                </button>

                <button className="flex items-center space-x-1 px-3 py-2 text-gray-600 hover:text-gray-800 rounded-lg hover:bg-gray-100 transition-colors">
                  <Filter className="w-4 h-4" />
                  <span>Filtrer</span>
                </button>
              </div>
            </div>
          </div>

          {/* Liste des messages */}
          <div className="flex-1 overflow-y-auto p-6">
            {loading ? (
              <div className="flex justify-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
              </div>
            ) : messages.length === 0 ? (
              <div className="text-center py-12">
                <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Mail className="w-12 h-12 text-gray-400" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  Aucun message
                </h3>
                <p className="text-gray-600">
                  {searchTerm 
                    ? 'Aucun message ne correspond à votre recherche.'
                    : 'Aucun message dans ce dossier.'
                  }
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {messages.map((message) => (
                  <MessageCard
                    key={message._id}
                    message={message}
                    onStar={handleStar}
                    onReply={handleReply}
                    onDelete={handleDelete}
                    onMarkRead={handleMarkRead}
                  />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Dialog de composition */}
      <ComposeDialog
        isOpen={composeOpen}
        onClose={() => {
          setComposeOpen(false);
          setReplyTo(null);
        }}
        onSend={handleSend}
        replyTo={replyTo}
      />
    </div>
  );
};

export default MessagesPage;