const Role = require('../models/role.model');
const Permission = require('../models/permission.model');
const { createActivityLog } = require('../lib/activityLogger');

// Contrôleurs pour les rôles
exports.getAllRoles = async (req, res) => {
  try {
    const roles = await Role.find().populate('permissions');
    res.json(roles);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createRole = async (req, res) => {
  try {
    const { name, description, permissions } = req.body;
    
    // Vérifier si le rôle existe déjà
    const existingRole = await Role.findOne({ name });
    if (existingRole) {
      return res.status(400).json({ message: 'Un rôle avec ce nom existe déjà' });
    }

    const role = new Role({
      name,
      description,
      permissions
    });

    const savedRole = await role.save();
    await createActivityLog({
      user: req.user._id,
      action: 'create',
      target: 'role',
      description: `Création du rôle ${name}`
    });

    res.status(201).json(savedRole);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.getRole = async (req, res) => {
  try {
    const role = await Role.findById(req.params.id).populate('permissions');
    if (!role) {
      return res.status(404).json({ message: 'Rôle non trouvé' });
    }
    res.json(role);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateRole = async (req, res) => {
  try {
    const { name, description, permissions } = req.body;
    const role = await Role.findById(req.params.id);

    if (!role) {
      return res.status(404).json({ message: 'Rôle non trouvé' });
    }

    if (role.isSystem) {
      return res.status(403).json({ message: 'Les rôles système ne peuvent pas être modifiés' });
    }

    // Vérifier si le nouveau nom existe déjà pour un autre rôle
    if (name !== role.name) {
      const existingRole = await Role.findOne({ name });
      if (existingRole) {
        return res.status(400).json({ message: 'Un rôle avec ce nom existe déjà' });
      }
    }

    role.name = name;
    role.description = description;
    role.permissions = permissions;

    const updatedRole = await role.save();
    await createActivityLog({
      user: req.user._id,
      action: 'update',
      target: 'role',
      description: `Modification du rôle ${name}`
    });

    res.json(updatedRole);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deleteRole = async (req, res) => {
  try {
    const role = await Role.findById(req.params.id);
    
    if (!role) {
      return res.status(404).json({ message: 'Rôle non trouvé' });
    }

    if (role.isSystem) {
      return res.status(403).json({ message: 'Les rôles système ne peuvent pas être supprimés' });
    }

    await role.remove();
    await createActivityLog({
      user: req.user._id,
      action: 'delete',
      target: 'role',
      description: `Suppression du rôle ${role.name}`
    });

    res.json({ message: 'Rôle supprimé avec succès' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Contrôleurs pour les permissions
exports.getAllPermissions = async (req, res) => {
  try {
    const permissions = await Permission.find();
    res.json(permissions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createPermission = async (req, res) => {
  try {
    const { name, description, module, action } = req.body;
    
    // Vérifier si la permission existe déjà
    const existingPermission = await Permission.findOne({ name });
    if (existingPermission) {
      return res.status(400).json({ message: 'Une permission avec ce nom existe déjà' });
    }

    const permission = new Permission({
      name,
      description,
      module,
      action
    });

    const savedPermission = await permission.save();
    await createActivityLog({
      user: req.user._id,
      action: 'create',
      target: 'permission',
      description: `Création de la permission ${name}`
    });

    res.status(201).json(savedPermission);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.getPermission = async (req, res) => {
  try {
    const permission = await Permission.findById(req.params.id);
    if (!permission) {
      return res.status(404).json({ message: 'Permission non trouvée' });
    }
    res.json(permission);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updatePermission = async (req, res) => {
  try {
    const { name, description, module, action } = req.body;
    const permission = await Permission.findById(req.params.id);

    if (!permission) {
      return res.status(404).json({ message: 'Permission non trouvée' });
    }

    if (permission.isSystem) {
      return res.status(403).json({ message: 'Les permissions système ne peuvent pas être modifiées' });
    }

    // Vérifier si le nouveau nom existe déjà pour une autre permission
    if (name !== permission.name) {
      const existingPermission = await Permission.findOne({ name });
      if (existingPermission) {
        return res.status(400).json({ message: 'Une permission avec ce nom existe déjà' });
      }
    }

    permission.name = name;
    permission.description = description;
    permission.module = module;
    permission.action = action;

    const updatedPermission = await permission.save();
    await createActivityLog({
      user: req.user._id,
      action: 'update',
      target: 'permission',
      description: `Modification de la permission ${name}`
    });

    res.json(updatedPermission);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deletePermission = async (req, res) => {
  try {
    const permission = await Permission.findById(req.params.id);
    
    if (!permission) {
      return res.status(404).json({ message: 'Permission non trouvée' });
    }

    if (permission.isSystem) {
      return res.status(403).json({ message: 'Les permissions système ne peuvent pas être supprimées' });
    }

    await permission.remove();
    await createActivityLog({
      user: req.user._id,
      action: 'delete',
      target: 'permission',
      description: `Suppression de la permission ${permission.name}`
    });

    res.json({ message: 'Permission supprimée avec succès' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
