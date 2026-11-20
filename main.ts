// Brainrot Bay — make.fun roblox-brainrot-01 entry (Node 22, standard library only).
// The game is this directory's Rojo project, built into game.rbxl with
// `rojo build default.project.json --output game.rbxl`, and this program hands
// it in. It copies game.rbxl, src/, screenshots/ and PLAY.json from beside
// this file to /output and writes /output/dossier.json, the summary the judge
// reads, with the vendored make.fun library.
//
// The game itself: a 3D brainrot collection game. Brainrots ride a conveyor
// into the bay, the player buys one, carries it to their base plot, places
// it, and it earns money every second. Other players can steal brainrots off
// a base (bases lock on a cooldown), a tsunami sweeps the map every few
// minutes, and rebirths trade everything for a permanent income multiplier.
// Twelve original characters, six rarities, four mutations.
//
// Every name under /output starts with a letter, a digit or _ and holds only
// letters, digits, . _ and -: the grader fails an entry whose output holds
// any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a
// dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { closeSync, copyFileSync, cpSync, existsSync, mkdirSync, openSync, readSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// --- Brainrot Bay pre-flight: refuse to hand in a half-built entry. ---
// The place must exist and be a binary Roblox place (it starts with the
// `<roblox!` magic), and screenshots/ must hold 3 or 4 images. These checks
// run before anything is copied, so a failed build can never be submitted.
const placePath = join(here, 'game.rbxl');
const placeStat = statSync(placePath);
if (placeStat.size === 0) throw new Error('game.rbxl is empty: run rojo build first');
const placeHead = Buffer.alloc(8);
const placeFd = openSync(placePath, 'r');
readSync(placeFd, placeHead, 0, 8, 0);
closeSync(placeFd);
if (placeHead.toString('ascii') !== '<roblox!') throw new Error('game.rbxl is not a binary Roblox place');
const screenshotNames = existsSync(join(here, 'screenshots'))
  ? readdirSync(join(here, 'screenshots')).filter((n) => !n.startsWith('.'))
  : [];
if (screenshotNames.length < 3 || screenshotNames.length > 4) {
  throw new Error(`screenshots/ must hold 3 or 4 images, found ${screenshotNames.length}`);
}
console.log(`Brainrot Bay: handing in game.rbxl (${placeStat.size} bytes) and ${screenshotNames.length} screenshots.`);

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
console.log('Brainrot Bay: dossier.json written.');
