# The Cashflow Conjurer

A spooky, pixel-art personal-finance game set in an alchemist's hall. Gold is power, debts are ghosts, and the tax wizards are coming. Manage your income statement and balance sheet, invest through the market ticker, and try to escape the Rat Race before you starve.

## How to play

- Move with the **arrow keys** or **WASD**
- Press **E** to interact
- Sleep on the **red cushion** to end each month
- Grow your passive income until it covers your expenses to escape the Rat Race
- Press **L** for the ledger, **G** for your goal, **N** for the world map, **J** for the story so far, **H** for help

### Story

You have inherited the Alchemist Hall from your Great-Aunt Ysolde, along with her goblin banker, her ledger, and a letter from the Ministry of Dues. The tax wizards would like the hall. Each level opens a chapter of the story, and winning or losing a level adds an epilogue:

1. **The Drafty Hall**: prove to the goblin you can keep coins in a pocket
2. **The Goblin's Wager**: build income that arrives while you sleep and earn the forest map
3. **The Wizards Come Knocking**: Form 7-B brings interest, crashes and the Shadow Gaol
4. **The Siege of Forms**: the Grand Auditor demands the hall sustain itself, in writing
5. **After the Rat Race**: the hall is yours; answer your aunt's last question at your own pace

Press **J** at any time to re-read the current chapter.

### Levels and endless mode

Levels 1 to 4 each have a fixed goal and a month limit. **Level 5: Endless Conjurer** has no month limit: you pick your own goal (passive income, net worth, gold in hand, assets owned, or debt free) and a starting map. Reaching a goal earns a trophy and lets you set a bigger one, or retire and see your legend.

After winning or losing any other level you can choose **Keep playing this map (endless)** to carry on with the same run in endless mode.

### Maps

Six areas connect in two loops. Walk to a marked exit and press E (in endless mode the world map also offers fast travel).

- **Alchemist Hall**: your home, the kitchen, the Goblin Bank and the red cushion. Exits: the Outside Gate to the yard, the Harbor Stairs down to the harbor
- **Spooky Yard**: market stalls, Trading Post, Tax Office and Business Office. Exits: the Hall Gate, the Forest Path, the Gaol Road
- **Enchanted Forest**: a treehouse to sleep in, the Druid's Hollow (bank), real-estate and bond stalls, a Berry Cart and the Faerie Ring (trading). Exits: the Yard Path, the Old Mine Shaft down to the caverns
- **Crystal Caverns**: a bedroll by the campfire, the Ore Vault (bank), mine-share and business stalls, a Stew Pot and the Gem Exchange (trading). Exits: the Ladder Up to the harbor, the Forest Tunnel
- **Moonlit Harbor**: a hammock to sleep in, the Harbor Vault (bank), stock and business stalls, a Fish Stall and the Smuggler's Market (trading). Exits: the Hall Stairs, the Cave Mouth, the Prison Hulk
- **Shadow Gaol**: a rain-soaked prison yard where the tax wizards keep debtors. A cell cot to sleep on, the Warden's Vault (bank), Repossessions (real estate) and Bail Bonds stalls, a Gruel Pot and the Debtors' Auction (trading). Exits: the Gaol Road up to the yard, the Prison Hulk down to the harbor

If the tax wizards catch you while you owe overdue debt, they seize up to $250 and drag you to the Shadow Gaol.

The ledger (L) includes a Fortune chart of your net worth by month.

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
