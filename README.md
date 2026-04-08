# Provisionamiento Automatizado de Usuarios en Active Directory

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Este script de PowerShell ha sido diseñado para optimizar y automatizar la gestion de identidades en entornos de Active Directory. Permite procesar de forma masiva tanto el alta de nuevos empleados como la actualizacion de cuentas existentes a partir de una fuente de datos en formato CSV.

## Caracteristicas Principales

- Logica de Upsert: Detecta si el usuario ya existe para actualizar su ficha o crearlo desde cero si es nuevo.
- Saneamiento de Datos: Limpieza automatica de espacios y normalizacion de nombres de usuario.
- Descripcion Dinamica: Genera automaticamente el campo de descripcion basado en los permisos de acceso (Local/Remoto).
- Consola Estructurada: Interfaz visual limpia con alertas por colores y control de errores en tiempo real.
- Mapeo Completo: Sincroniza campos de Puesto, Departamento, Provincia, Telefono y Correo Electronico.

## Requisitos Previos

1. Modulo de Active Directory: Debe estar instalado en el equipo desde donde se ejecute el script (RSAT).
2. Permisos: El usuario que ejecute el script debe tener privilegios de Administrador de Dominio o delegacion de control sobre la OU de destino.
3. Archivo CSV: Debe estar delimitado por punto y coma (;) y guardado con codificacion UTF-8 con BOM para asegurar la compatibilidad de caracteres.

## Guia de Uso Rapido

1. Clona este repositorio o descarga el archivo .ps1 y el CSV de ejemplo.
2. Edita las variables de configuracion inicial ($RutaCSV y $RutaOU) con los datos de tu entorno.
3. Ejecuta el script:
   ```powershell
   .\provision-users.ps1

## Autor
* **Axier Baez** - (https://github.com/AxierSysOp)

## Licencia
Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para detalles.
