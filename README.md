# The Cashflow Conjurer

A spooky, pixel-art personal-finance game set in an alchemist's hall. Gold is power, debts are ghosts, and the tax wizards are coming. Manage your income statement and balance sheet, invest through the market ticker, and try to escape the Rat Race before you starve.

## How to play

- Move with the **arrow keys** or **WASD**
- Press **E** to interact
- Sleep on the **red cushion** to end each month
- Grow your passive income until it covers your expenses to escape the Rat Race

## Tech stack

- [TypeScript](https://www.typescriptlang.org/)
- [React](https://react.dev/)
- [Vite](https://vite.dev/)
- [Node.js](https://nodejs.org/) (LTS recommended)

## Getting started

### Prerequisites

- Node.js 20+ and npm

### Install

```bash
npm install
```

### Develop

```bash
npm run dev
```

Then open the URL printed in the terminal (usually http://localhost:5173).

### Build

```bash
npm run build
```

The production build is written to `dist/`.

### Preview the production build

```bash
npm run preview
```

## Project structure

```
.
├── index.html      # App entry point
├── src/            # Application source (TypeScript + React)
├── public/         # Static assets served as-is
└── dist/           # Production build output (generated)
```

## Deployment

Every push to `main` deploys the site to GitHub Pages via `.github/workflows/deploy.yml`, published at `https://<username>.github.io/cashflow-conjurer/`.

One-time setup: in the GitHub repo, go to **Settings → Pages** and set **Source** to **GitHub Actions**.

## Environment variables

Copy `.env.example` to `.env` and fill in any values. Vite only exposes variables prefixed with `VITE_` to client code.

## Contributing

1. Create a feature branch: `git checkout -b my-feature`
2. Commit your changes: `git commit -m "Add my feature"`
3. Push the branch and open a pull request

## License

TBD
