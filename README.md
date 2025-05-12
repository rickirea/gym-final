# 🏋️‍♂️ Gym Membership Management on Blockchain

Este proyecto implementa un sistema completo de gestión de membresías para gimnasios utilizando contratos inteligentes en Solidity. Integra NFTs para representar membresías, un token ERC20 como sistema de lealtad y lógica de negocio que simula check-ins, recompensas y clases.

## 📦 Contratos Incluidos

### 1. `GymControl.sol`

Contrato principal que gestiona:

- Registro de usuarios.
- Compra y gestión de membresías.
- Check-in y check-out con recompensa.
- Uso de clases gratuitas o pagadas con tokens.
- Administración por parte del owner.

### 2. `GymMembershipNFT.sol`

Contrato ERC721 que emite un NFT con metadatos únicos (URI) representando la membresía activa del usuario.

### 3. `GymLoyaltyToken.sol`

Token ERC20 con funciones de `mint()` y `burn()` controladas por el contrato `GymControl`. Actúa como token de fidelidad que los usuarios ganan por asistir y utilizan para pagar clases.

---

## 🔐 Seguridad

- **Modificadores de acceso**: Uso de `onlyOwner` y `onlyRegistered` para controlar acciones críticas.
- **Mint/Burn controlado**: Solo `GymControl` puede mintear o quemar tokens.
- **Validaciones estrictas**: Se asegura que los pagos, accesos y lógicas de membresía sean válidas y actualizadas.
- **Protección contra sobreuso**: Check-in semanal limitado y uso de tokens limitado por lógica interna.

---

## 🪙 Lógica de Lealtad

- 5 tokens por sesión si no se superan 4 en la semana.
- 15 tokens por la quinta sesión o más en la misma semana.
- Clases gratis según el tipo de membresía.
- Clases adicionales cuestan 5 tokens.

---

## 🧾 Tipos de Membresía

| Tipo       | Duración | Clases Gratuitas | Precio   |
| ---------- | -------- | ---------------- | -------- |
| Mensual    | 30 días  | 1 clase          | 0.05 ETH |
| Trimestral | 90 días  | 4 clases         | 0.12 ETH |
| Semestral  | 180 días | 6 clases         | 0.20 ETH |
| Anual      | 365 días | 12 clases        | 0.35 ETH |

---

## 🚀 Despliegue y Prueba

1. **Importa los contratos** en Remix o tu entorno de desarrollo preferido.
2. **Despliega `GymLoyaltyToken` y `GymMembershipNFT`** primero.
3. **Despliega `GymControl` pasando las direcciones de los contratos anteriores**.
4. **Configura `setMinter()`** en ambos contratos para autorizar a `GymControl` como minter.
5. Comienza con `register()` y prueba el flujo completo de compra de membresía, check-in, check-out y clases.

---

## 🧪 Tests sugeridos

- Registro y doble registro.
- Compra de membresía válida e inválida.
- Check-in y check-out con tiempos simulados.
- Recompensa semanal y uso de clases.
- Burn de tokens al inscribirse en clases extra.

---

## 📄 Licencia

Este proyecto está bajo licencia **MIT**.

---

## ✍️ Autor

Proyecto desarrollado por [rickirea] como parte del sistema de gestión de membresías descentralizado.
