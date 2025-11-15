# Configuration Mailtrap pour Forgot Password

## Identifiants Mailtrap
- **Host:** sandbox.smtp.mailtrap.io
- **Port:** 2525
- **Username:** b05bc95cf579cf
- **Password:** a2828ad5ae1705

## Exemple Node.js/Express avec Nodemailer

### 1. Installation des dépendances
```bash
npm install nodemailer
```

### 2. Configuration du transporter Mailtrap
```javascript
// config/email.js
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'sandbox.smtp.mailtrap.io',
  port: 2525,
  auth: {
    user: 'b05bc95cf579cf',
    pass: 'a2828ad5ae1705'
  }
});

module.exports = transporter;
```

### 3. Route Forgot Password
```javascript
// routes/auth.js
const express = require('express');
const router = express.Router();
const transporter = require('../config/email');
const crypto = require('crypto');
const { Parent } = require('../models'); // Ajustez selon votre modèle

// Route pour demander la réinitialisation
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    // Vérifier que l'email existe
    const parent = await Parent.findOne({ where: { email: email.toLowerCase() } });
    
    // Pour la sécurité, on ne révèle pas si l'email existe ou non
    if (!parent) {
      return res.status(200).json({ 
        message: 'If this email exists, a password reset link has been sent.' 
      });
    }

    // Générer un token de réinitialisation
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes

    // Sauvegarder le token dans la base de données
    parent.resetPasswordToken = resetToken;
    parent.resetPasswordExpires = resetTokenExpiry;
    await parent.save();

    // Créer le lien de réinitialisation
    // Note: Vous devrez créer une page web ou une deep link iOS pour gérer ce token
    const resetUrl = `https://votre-app.com/reset-password?token=${resetToken}`;
    
    // Alternative pour iOS: utiliser un deep link
    // const resetUrl = `edukid://reset-password?token=${resetToken}`;

    // Envoyer l'email via Mailtrap
    const mailOptions = {
      from: '"EduKid Support" <support@edukid.app>',
      to: email,
      subject: 'Réinitialisation de votre mot de passe',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #8B7DE8;">Réinitialisation de votre mot de passe</h2>
          <p>Bonjour ${parent.name || 'Parent'},</p>
          <p>Vous avez demandé à réinitialiser votre mot de passe. Cliquez sur le lien ci-dessous pour continuer :</p>
          <p style="text-align: center; margin: 30px 0;">
            <a href="${resetUrl}" 
               style="background-color: #8B7DE8; color: white; padding: 12px 24px; 
                      text-decoration: none; border-radius: 6px; display: inline-block;">
              Réinitialiser mon mot de passe
            </a>
          </p>
          <p>Ou copiez ce lien dans votre navigateur :</p>
          <p style="word-break: break-all; color: #666;">${resetUrl}</p>
          <p style="color: #999; font-size: 12px; margin-top: 30px;">
            Ce lien expire dans 30 minutes. Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.
          </p>
        </div>
      `,
      text: `
        Bonjour ${parent.name || 'Parent'},
        
        Vous avez demandé à réinitialiser votre mot de passe. 
        Cliquez sur ce lien pour continuer : ${resetUrl}
        
        Ce lien expire dans 30 minutes.
      `
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({ 
      message: 'If this email exists, a password reset link has been sent.' 
    });

  } catch (error) {
    console.error('Error sending password reset email:', error);
    res.status(500).json({ 
      error: 'Failed to send password reset email' 
    });
  }
});

// Route pour réinitialiser le mot de passe avec le token
router.post('/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    // Trouver l'utilisateur avec un token valide et non expiré
    const parent = await Parent.findOne({
      where: {
        resetPasswordToken: token,
        resetPasswordExpires: {
          [Op.gt]: new Date() // Token non expiré
        }
      }
    });

    if (!parent) {
      return res.status(400).json({ 
        error: 'Invalid or expired reset token' 
      });
    }

    // Valider le nouveau mot de passe
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ 
        error: 'Password must be at least 6 characters' 
      });
    }

    // Hasher et sauvegarder le nouveau mot de passe
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    parent.password = hashedPassword;
    parent.resetPasswordToken = null;
    parent.resetPasswordExpires = null;
    await parent.save();

    res.status(200).json({ 
      message: 'Password has been reset successfully' 
    });

  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({ 
      error: 'Failed to reset password' 
    });
  }
});

module.exports = router;
```

## Exemple avec TypeScript/Express

```typescript
// routes/auth.ts
import express, { Request, Response } from 'express';
import nodemailer from 'nodemailer';
import crypto from 'crypto';
import { Parent } from '../models';

const router = express.Router();

// Configuration Mailtrap
const transporter = nodemailer.createTransport({
  host: 'sandbox.smtp.mailtrap.io',
  port: 2525,
  auth: {
    user: 'b05bc95cf579cf',
    pass: 'a2828ad5ae1705'
  }
});

router.post('/forgot-password', async (req: Request, res: Response) => {
  try {
    const { email } = req.body;

    const parent = await Parent.findOne({ 
      where: { email: email.toLowerCase() } 
    });
    
    if (!parent) {
      return res.status(200).json({ 
        message: 'If this email exists, a password reset link has been sent.' 
      });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 30 * 60 * 1000);

    await parent.update({
      resetPasswordToken: resetToken,
      resetPasswordExpires: resetTokenExpiry
    });

    const resetUrl = `https://votre-app.com/reset-password?token=${resetToken}`;

    await transporter.sendMail({
      from: '"EduKid Support" <support@edukid.app>',
      to: email,
      subject: 'Réinitialisation de votre mot de passe',
      html: `
        <h2>Réinitialisation de votre mot de passe</h2>
        <p>Bonjour ${parent.name || 'Parent'},</p>
        <p>Cliquez sur ce lien pour réinitialiser votre mot de passe :</p>
        <a href="${resetUrl}">${resetUrl}</a>
        <p>Ce lien expire dans 30 minutes.</p>
      `
    });

    res.status(200).json({ 
      message: 'If this email exists, a password reset link has been sent.' 
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to send reset email' });
  }
});

export default router;
```

## Variables d'environnement (recommandé)

Créez un fichier `.env` :
```env
MAILTRAP_HOST=sandbox.smtp.mailtrap.io
MAILTRAP_PORT=2525
MAILTRAP_USER=b05bc95cf579cf
MAILTRAP_PASS=a2828ad5ae1705
FRONTEND_URL=https://votre-app.com
```

Puis utilisez-les dans votre code :
```javascript
const transporter = nodemailer.createTransport({
  host: process.env.MAILTRAP_HOST,
  port: process.env.MAILTRAP_PORT,
  auth: {
    user: process.env.MAILTRAP_USER,
    pass: process.env.MAILTRAP_PASS
  }
});
```

## Test

1. Démarrez votre serveur backend
2. Testez avec Postman ou curl :
```bash
curl -X POST https://votre-backend.com/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```
3. Vérifiez dans Mailtrap → Inbox que l'email est bien reçu

## Notes importantes

- **Sécurité** : Ne révélez jamais si un email existe ou non dans votre base de données
- **Expiration** : Les tokens doivent expirer (30 minutes recommandé)
- **Production** : Remplacez Mailtrap par un vrai service SMTP (SendGrid, AWS SES, etc.) en production
- **Deep Links iOS** : Pour ouvrir l'app iOS directement, configurez un URL scheme dans votre app

