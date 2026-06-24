# Eazzio-Books AI Agent Guidelines (AGENTS.md)

This file defines the active developer skills and behavioral rules for building, testing, and maintaining the Eazzio-Books project. 

The project structure is as follows:
- [backend-books](file:///home/rahul-kumar/Desktop/Eazzio-Books/backend-books): Node.js/Express API with PostgreSQL database backend.
- [frontend-books](file:///home/rahul-kumar/Desktop/Eazzio-Books/frontend-books): React frontend using Tailwind CSS.
- [documentation](file:///home/rahul-kumar/Desktop/Eazzio-Books/documentation): Markdown documentation repository.
- [mobile-books](file:///home/rahul-kumar/Desktop/Eazzio-Books/mobile-books): Flutter mobile app (NEW — to be built, currently empty until Task 1 creates it).

---

## 🚀 Active Skills & Configurations

The following skills from the installed Antigravity library are activated and applied to Eazzio-Books:

### 1. Backend Development Skills
* **`nodejs-backend-patterns`**: Applied for maintaining standard Express controller structures, routing middleware, and server setup in `backend-books`.
* **`api-patterns`**: Guides design of RESTful APIs, response structures, status codes, standard validation, pagination, and error responses.
* **`database`**: Directs PostgreSQL schema design, optimization of queries via raw `pg` library, database migrations, and index definitions.

### 2. Frontend Development Skills
* **`react-patterns`**: Applied for React 18 component composition, state management hooks (useState, useEffect, custom hooks), performance optimization, and modular routing.
* **`tailwind-patterns`**: Guides modern styling using Tailwind CSS v3 utility classes, layout structuring, grids, and design tokens alignment.
* **`typescript-pro`**: Ready for any future conversion or TypeScript module design in the frontend or backend.

### 3. Documentation Skills
* **`documentation`**: Directs writing and updating API descriptions, inline comments, and codebase onboarding documents.
* **`wiki-architect`**: Standardizes layout and index structure for Markdown guides in the `documentation` folder.

### 4. Code Review & Testing Skills
* **`tdd-workflow`**: Promotes writing unit and integration tests (such as Jest/React Testing Library) before writing production code changes.
* **`code-reviewer`**: Ensures thorough peer-level evaluation of diffs, PR summaries, code complexity check, and refactoring potential.

### 5. Mobile Development Skills
* **`android-development`**: Applied for the new `mobile-books` Flutter app — guides
  Gradle setup, project architecture, modularization, Compose patterns (where
  applicable), and Android testing standards. Loaded from local skill bundle at
  `.skills/android-development/SKILL.md`.
* **`mobile-app-ui-design`**: Applied for all mobile UI/UX decisions in `mobile-books`
  — guides screen layout, design tokens, spacing system, and industry-specific
  conventions (Finance/Business apps) per `.skills/mobile-app-ui-design/SKILL.md`
  and `.skills/mobile-app-ui-design/references/industry-conventions.md`.
* **`flutter-tester`**: Applied for all Flutter testing in `mobile-books` — covers
  unit tests, widget tests, integration tests, mocking patterns, and Riverpod
  state management testing. Loaded from
  `.skills/flutter-claude-skills/flutter-tester/SKILL.md`.
* **`owasp-mobile-security-checker`**: Applied before every release build of
  `mobile-books` — scans for hardcoded secrets, dependency vulnerabilities,
  insecure network config, and unsafe local storage per OWASP Mobile Top 10
  (2024). Loaded from
  `.skills/flutter-claude-skills/owasp-mobile-security-checker/SKILL.md`.
  Run via: `python3 .skills/flutter-claude-skills/owasp-mobile-security-checker/scripts/scan_hardcoded_secrets.py mobile-books/`
  before every git push.

### 6. Security Audit Skills
* **`security-auditor`**: Focuses on OWASP Top 10 prevention, cookie parsing safety, CORS configurations, rate-limiting, and data sanitize validation in Express.
* **`vibe-code-auditor`**: Audits rapidly generated AI code to ensure structural integrity and vulnerability reduction.
