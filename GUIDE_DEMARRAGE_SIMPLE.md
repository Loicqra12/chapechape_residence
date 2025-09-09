# 🚀 GUIDE DE DÉMARRAGE SIMPLE - CHAPECHAPE

## 🎯 TON GITHUB CORRIGÉ !

Parfait ! J'ai mis à jour la configuration pour ton vrai GitHub : **Loicqra12/chapechape_residence**

## 📋 ÉTAPES SIMPLES À SUIVRE

### **1️⃣ PUSH TON CODE SUR GITHUB**
```bash
# Ouvre PowerShell dans ton dossier
cd C:\Users\DELL\CascadeProjects\chapechape_residence

# Push vers ton GitHub
git init
git add .
git commit -m "🚀 Infrastructure CI/CD complète"
git branch -M main
git remote add origin https://github.com/Loicqra12/chapechape_residence.git
git push -u origin main
```

### **2️⃣ CONFIGURER LES SECRETS GITHUB**
Va sur : https://github.com/Loicqra12/chapechape_residence/settings/secrets/actions

Clique "New repository secret" et ajoute :
- **Nom** : `TEST_USER_EMAIL` → **Valeur** : `test@chapechape.com`
- **Nom** : `TEST_USER_PASSWORD` → **Valeur** : `test123`
- **Nom** : `TEST_ADMIN_EMAIL` → **Valeur** : `admin@chapechape.com`
- **Nom** : `TEST_ADMIN_PASSWORD` → **Valeur** : `admin123`

### **3️⃣ DÉMARRER TON ENVIRONNEMENT**
```bash
# Dans PowerShell
cd C:\Users\DELL\CascadeProjects\chapechape_residence

# Lance la baguette magique
bash scripts/setup-dev.sh
```

### **4️⃣ VÉRIFIER QUE ÇA MARCHE**
Ouvre ces liens :
- 🖥️ **Dashboard** : http://localhost:3001
- 🌍 **Site Web** : http://localhost:3002
- ⚙️ **API** : http://localhost:5000/health
- 📊 **MongoDB** : http://localhost:8081
- 🔴 **Redis** : http://localhost:8082

## 🎉 C'EST TOUT !

Après ça, chaque fois que tu push du code :
- ✅ Tests automatiques
- 📱 Build de tes apps Flutter
- 🚀 Déploiement automatique

## 🆘 SI TU AS UN PROBLÈME

```bash
# Voir ce qui se passe
docker-compose -f docker-compose.dev.yml logs -f

# Redémarrer tout
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d
```

## 📱 CONSTRUIRE TES APPS FLUTTER

```bash
# App Client
bash scripts/build-flutter.sh client apk

# App Partner
bash scripts/build-flutter.sh partner aab

# Toutes les apps
bash scripts/build-flutter.sh all both
```

**Tes fichiers seront dans :**
- `chapechape_client/build/app/outputs/flutter-apk/`
- `chapechape_partner/build/app/outputs/bundle/release/`

---

**🎯 RÉSUMÉ : Tu push → Tout se fait automatiquement !** ✨
