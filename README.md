# DashboardManager

A full-stack **Admin Dashboard** system with **Role-Based Access Control (RBAC)**, allowing Admins to manage users and products while regular Users have restricted, read-only access. Built as a hands-on learning project applying clean architecture, secure authentication, and modern frontend practices.

## 🚀 Features

- **Authentication & Authorization** — Secure login with JWT tokens and password hashing
- **Role-Based Access Control** — Separate permissions for Admin and User roles
- **User Management** — Admins can create, update, and delete user accounts
- **Product Management** — Admins can manage products; Users can view them
- **Clean 3-Tier Architecture** — Clear separation between API, Business Logic, and Data Access
- **Secure Database Design** — Parameterized stored procedures, constraints, and transaction handling

## 🛠️ Tech Stack

- **Backend:** C#, ASP.NET Core Web API
- **Frontend:** React.js
- **Database:** Microsoft SQL Server (T-SQL, Stored Procedures)
- **Data Access:** ADO.NET
- **Authentication:** JWT (JSON Web Tokens)
- **Architecture:** 3-Tier (Presentation / Business Logic / Data Access)
- **Tools:** Visual Studio, SQL Server Management Studio (SSMS), Visual Studio Code

## 📁 Solution Structure
DashboardManager/
├── SharedDTOModel/ → Shared DTOs used across all layers
├── DashboardAPI/ → Presentation layer (Controllers, Auth, API endpoints)
├── DashboardBusinessLayer/ → Business logic, validation, and access control rules
├── DashboardDataAccessLayer/ → Data access via ADO.NET and stored procedures
├── Database/
│ ├── CreateTables.sql
│ └── StoredProcedures/
└── client/ → React frontend application

## 🏗️ Architecture Overview

- **Presentation Layer** (`DashboardAPI`) — Exposes REST endpoints, handles HTTP requests, authentication, and authorization.
- **Business Layer** (`DashboardBusinessLayer`) — Contains business rules, validation logic, and role-based permission checks.
- **Data Access Layer** (`DashboardDataAccessLayer`) — Communicates directly with SQL Server via ADO.NET and stored procedures.
- **Shared Layer** (`SharedDTOModel`) — Defines DTOs used as the common data contract between all layers.
- **Client** (`React`) — Consumes the API to render the dashboard UI for Admins and Users.

## 🗄️ Database Schema (Overview)

| Table      | Description                                  |
|------------|-----------------------------------------------|
| `Roles`    | Defines available roles (Admin, User)         |
| `Users`    | Stores user accounts, credentials, and role   |
| `Products` | Stores product data, linked to the creating Admin |

## 🔐 Security Notes

- Passwords are never stored in plain text — hashed before persistence.
- Role-based checks are enforced at the API level for every protected endpoint.
- Sensitive configuration (connection strings, JWT secrets) is excluded from version control via `.gitignore`.

## 📌 Status

🚧 **In progress** — Database design phase.

## 📖 About This Project

This project is part of my journey learning full-stack development with .NET, SQL Server, and React. It follows the same engineering principles applied in production systems: clean layered architecture, secure authentication, parameterized queries, and role-based access control.